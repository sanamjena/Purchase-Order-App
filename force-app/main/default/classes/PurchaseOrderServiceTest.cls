@IsTest
private class PurchaseOrderServiceTest {
    @IsTest
    static void testCreateAndQueryPurchaseOrder() {
        Purchase_Order__c po = new Purchase_Order__c(
            Supplier_Name__c = 'Acme Supply Co',
            Supplier_Email__c = 'orders@acme.example',
            Requester__c = 'Jane Buyer',
            Department__c = 'Operations',
            Priority__c = 'High',
            Status__c = 'Draft',
            Approval_Status__c = 'Not Submitted',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(10),
            Budget_Amount__c = 1500,
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
        System.assert(dashboard.containsKey('pendingApprovalCount'), 'Dashboard should include pending approval metric.');
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
    static void testApprovalFlowInService() {
        Purchase_Order__c po = PurchaseOrderService.savePurchaseOrder(new Purchase_Order__c(
            Supplier_Name__c = 'Approval Supplier',
            Requester__c = 'Approver User',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(4),
            Budget_Amount__c = 1000
        ));

        Test.startTest();
        Purchase_Order__c submitted = PurchaseOrderService.submitForApproval(po.Id);
        Purchase_Order__c approved = PurchaseOrderService.setApprovalDecision(po.Id, 'Approved');
        Test.stopTest();

        System.assertEquals('Pending Approval', submitted.Approval_Status__c, 'Expected pending approval status.');
        System.assertEquals('Approved', approved.Approval_Status__c, 'Expected approved status.');
    }

    @IsTest
    static void testRejectedApprovalSetsRejectedLifecycleStatus() {
        Purchase_Order__c po = PurchaseOrderService.savePurchaseOrder(new Purchase_Order__c(
            Supplier_Name__c = 'Rejected Supplier',
            Requester__c = 'Approver User',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(4),
            Budget_Amount__c = 800
        ));

        Test.startTest();
        PurchaseOrderService.submitForApproval(po.Id);
        Purchase_Order__c rejected = PurchaseOrderService.setApprovalDecision(po.Id, 'Rejected');
        Test.stopTest();

        System.assertEquals('Rejected', rejected.Approval_Status__c, 'Expected rejected approval status.');
        System.assertEquals('Rejected', rejected.Status__c, 'Expected rejected lifecycle status.');
    }

    @IsTest
    static void testRfpToRfqToPoConversionFlow() {
        Request_For_Proposal__c rfp = new Request_For_Proposal__c(
            Title__c = 'Enterprise Laptops',
            Department__c = 'IT',
            Requested_By__c = 'Procurement Lead',
            Needed_By_Date__c = Date.today().addDays(20),
            Status__c = 'Approved',
            Estimated_Budget__c = 25000
        );
        insert rfp;

        Test.startTest();
        Request_For_Quotation__c rfq = PurchaseOrderService.convertRfpToRfq(
            rfp.Id,
            'Best Supplier Inc',
            'supplier@example.com',
            Date.today().addDays(15)
        );

        rfq.Status__c = 'Selected';
        update rfq;

        Purchase_Order__c po = PurchaseOrderService.convertRfqToPurchaseOrder(
            rfq.Id,
            'Conversion Requester',
            Date.today().addDays(30)
        );
        Test.stopTest();

        System.assertNotEquals(null, rfq.Id, 'RFQ should be created from RFP.');
        System.assertNotEquals(null, po.Id, 'PO should be created from RFQ.');
        Request_For_Quotation__c refreshedRfq = [SELECT Status__c, Purchase_Order__c FROM Request_For_Quotation__c WHERE Id = :rfq.Id];
        System.assertEquals('Converted to PO', refreshedRfq.Status__c, 'RFQ should be marked converted.');
        System.assertEquals(po.Id, refreshedRfq.Purchase_Order__c, 'RFQ should be linked to the new PO.');
    }


    @IsTest
    static void testSendRfpToExperienceCloudUsers() {
        Request_For_Proposal__c rfp = new Request_For_Proposal__c(
            Title__c = 'Network Hardware Refresh',
            Department__c = 'IT',
            Requested_By__c = 'IT Director',
            Needed_By_Date__c = Date.today().addDays(14),
            Status__c = 'Approved',
            Distribution_Status__c = 'Not Sent'
        );
        insert rfp;

        Test.startTest();
        Map<String, Object> response = PurchaseOrderService.sendRfpToExperienceCloudUsers(
            rfp.Id,
            new List<Id>{UserInfo.getUserId()},
            'Please review and respond to this RFP.'
        );
        Test.stopTest();

        System.assertEquals(1, (Integer) response.get('sentCount'), 'Expected one successful send in test mode.');
        Request_For_Proposal__c refreshed = [SELECT Distribution_Status__c, Last_Distribution_Date__c FROM Request_For_Proposal__c WHERE Id = :rfp.Id];
        System.assertEquals('Sent', refreshed.Distribution_Status__c, 'Distribution status should be Sent.');
        System.assertNotEquals(null, refreshed.Last_Distribution_Date__c, 'Distribution timestamp should be set.');
    }

}
