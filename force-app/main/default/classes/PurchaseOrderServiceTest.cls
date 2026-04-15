@IsTest
private class PurchaseOrderServiceTest {
    @IsTest
    static void testCreateAndQueryPurchaseOrder() {
        Purchase_Order__c po = new Purchase_Order__c(
            Supplier_Name__c = 'Acme Supply Co',
            Supplier_Email__c = 'orders@acme.example',
            Requester__c = 'Jane Buyer',
            Status__c = 'Draft',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(10),
            Tax_Amount__c = 50,
            Shipping_Amount__c = 25,
            Discount_Amount__c = 10
        );

        Test.startTest();
        Purchase_Order__c insertedPO = PurchaseOrderService.savePurchaseOrder(po);
        Purchase_Order_Line__c line = new Purchase_Order_Line__c(
            Purchase_Order__c = insertedPO.Id,
            Product_Name__c = 'Widget A',
            SKU__c = 'WIDGET-A',
            Quantity__c = 10,
            Unit_Price__c = 100
        );
        Purchase_Order_Line__c insertedLine = PurchaseOrderService.saveLineItem(line);
        List<Purchase_Order__c> results = PurchaseOrderService.getPurchaseOrders();
        List<Purchase_Order_Line__c> lines = PurchaseOrderService.getLinesForOrder(insertedPO.Id);
        Map<String, Object> dashboard = PurchaseOrderService.getDashboardMetrics();
        Test.stopTest();

        System.assertNotEquals(null, insertedPO.Id, 'Purchase order should be created.');
        System.assertNotEquals(null, insertedLine.Id, 'Line item should be created.');
        System.assert(results.size() >= 1, 'At least one purchase order should be returned.');
        System.assertEquals(1, lines.size(), 'Exactly one line should be returned.');
        System.assert(dashboard.containsKey('openAmount'), 'Dashboard should include open amount metric.');
    }

    @IsTest
    static void testValidationRulesInService() {
        Purchase_Order__c po = new Purchase_Order__c(
            Supplier_Name__c = 'Invalid Supplier',
            Requester__c = 'QA User',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(-1)
        );

        try {
            PurchaseOrderService.savePurchaseOrder(po);
            System.assert(false, 'An exception was expected for invalid expected delivery date.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Expected delivery date'), 'Expected validation failure message.');
        }
    }

    @IsTest
    static void testControllerMethods() {
        Purchase_Order__c po = new Purchase_Order__c(
            Supplier_Name__c = 'Controller Supplier',
            Requester__c = 'Controller Requester',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(5)
        );

        Test.startTest();
        Purchase_Order__c savedPo = PurchaseOrderController.savePurchaseOrder(po);
        Purchase_Order_Line__c savedLine = PurchaseOrderController.saveLineItem(new Purchase_Order_Line__c(
            Purchase_Order__c = savedPo.Id,
            Product_Name__c = 'Controller Line',
            Quantity__c = 2,
            Unit_Price__c = 50
        ));
        List<Purchase_Order__c> orders = PurchaseOrderController.getPurchaseOrders();
        List<Purchase_Order_Line__c> orderLines = PurchaseOrderController.getLinesForOrder(savedPo.Id);
        Map<String, Object> metrics = PurchaseOrderController.getDashboardMetrics();
        Test.stopTest();

        System.assertNotEquals(null, savedPo.Id, 'Controller should save purchase order.');
        System.assertNotEquals(null, savedLine.Id, 'Controller should save line.');
        System.assert(orders.size() > 0, 'Controller should return orders.');
        System.assertEquals(1, orderLines.size(), 'Controller should return one line.');
        System.assert(metrics.containsKey('overdueCount'), 'Metrics should include overdue count.');
    }
}
