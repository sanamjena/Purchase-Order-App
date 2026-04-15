@IsTest
private class PurchaseOrderControllerTest {
    private static Purchase_Order__c createPurchaseOrder(String supplier, Date expectedDate) {
        Purchase_Order__c po = new Purchase_Order__c(
            Supplier_Name__c = supplier,
            Requester__c = 'Automated Tester',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = expectedDate,
            Status__c = 'Draft',
            Tax_Amount__c = 5,
            Shipping_Amount__c = 10,
            Discount_Amount__c = 0
        );
        return PurchaseOrderController.savePurchaseOrder(po);
    }

    @IsTest
    static void testControllerCreateAndQueryFlow() {
        Test.startTest();
        Purchase_Order__c created = createPurchaseOrder('Controller Test Supplier', Date.today().addDays(7));

        Purchase_Order_Line__c line = PurchaseOrderController.saveLineItem(new Purchase_Order_Line__c(
            Purchase_Order__c = created.Id,
            Product_Name__c = 'Controller Product',
            SKU__c = 'CTRL-001',
            Quantity__c = 3,
            Unit_Price__c = 15
        ));

        List<Purchase_Order__c> orders = PurchaseOrderController.getPurchaseOrders();
        List<Purchase_Order_Line__c> lines = PurchaseOrderController.getLinesForOrder(created.Id);
        Map<String, Object> metrics = PurchaseOrderController.getDashboardMetrics();
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'Expected purchase order to be created.');
        System.assertNotEquals(null, line.Id, 'Expected line to be created.');
        System.assert(orders.size() > 0, 'Expected controller order query to return rows.');
        System.assertEquals(1, lines.size(), 'Expected one line item for created order.');
        System.assert(metrics.containsKey('openAmount'), 'Expected openAmount metric key.');
    }

    @IsTest
    static void testControllerValidationErrors() {
        Purchase_Order__c invalidOrder = new Purchase_Order__c(
            Supplier_Name__c = 'Bad Date Supplier',
            Requester__c = 'Automated Tester',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(-2)
        );

        Boolean orderValidationHit = false;
        try {
            PurchaseOrderController.savePurchaseOrder(invalidOrder);
        } catch (AuraHandledException e) {
            orderValidationHit = e.getMessage().contains('Expected delivery date');
        }
        System.assertEquals(true, orderValidationHit, 'Expected date validation error through controller.');

        Purchase_Order__c validOrder = createPurchaseOrder('Line Validation Supplier', Date.today().addDays(3));

        Boolean lineValidationHit = false;
        try {
            PurchaseOrderController.saveLineItem(new Purchase_Order_Line__c(
                Purchase_Order__c = validOrder.Id,
                Product_Name__c = 'Bad Qty',
                Quantity__c = 0,
                Unit_Price__c = 10
            ));
        } catch (AuraHandledException e) {
            lineValidationHit = e.getMessage().contains('quantity must be positive');
        }
        System.assertEquals(true, lineValidationHit, 'Expected line validation error through controller.');
    }

    @IsTest
    static void testNullOrderIdReturnsNoLines() {
        Test.startTest();
        List<Purchase_Order_Line__c> lines = PurchaseOrderController.getLinesForOrder(null);
        Test.stopTest();

        System.assertEquals(0, lines.size(), 'Expected empty list when order id is null.');
    }
}
