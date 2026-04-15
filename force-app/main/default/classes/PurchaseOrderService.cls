public with sharing class PurchaseOrderService {
    @TestVisible private static final Set<String> CLOSED_STATUSES = new Set<String>{'Closed', 'Cancelled'};
    @TestVisible private static final Set<String> FINAL_APPROVAL_STATUSES = new Set<String>{'Approved', 'Rejected'};

    public static List<Purchase_Order__c> getPurchaseOrders() {
        return [
            SELECT Id, Name, Supplier_Name__c, Supplier_Email__c, Requester__c, Department__c,
                   Status__c, Approval_Status__c, Priority__c, Order_Date__c, Expected_Delivery_Date__c,
                   Tax_Amount__c, Shipping_Amount__c, Discount_Amount__c, Budget_Amount__c,
                   Remaining_Budget__c, Is_Overdue__c, Subtotal_Amount__c, Total_Amount__c, LastModifiedDate
            FROM Purchase_Order__c
            ORDER BY LastModifiedDate DESC
            LIMIT 200
        ];
    }

    public static List<Purchase_Order_Line__c> getLinesForOrder(Id purchaseOrderId) {
        if (purchaseOrderId == null) {
            return new List<Purchase_Order_Line__c>();
        }
        return [
            SELECT Id, Name, Purchase_Order__c, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Line_Total__c
            FROM Purchase_Order_Line__c
            WHERE Purchase_Order__c = :purchaseOrderId
            ORDER BY CreatedDate ASC
        ];
    }

    public static Purchase_Order__c savePurchaseOrder(Purchase_Order__c purchaseOrder) {
        if (purchaseOrder == null) {
            throw new AuraHandledException('Purchase order payload is required.');
        }

        normalizeDefaults(purchaseOrder);
        validateBusinessRules(purchaseOrder);

        upsertPurchaseOrder(purchaseOrder);
        return queryPurchaseOrder(purchaseOrder.Id);
    }

    public static Purchase_Order__c submitForApproval(Id purchaseOrderId) {
        Purchase_Order__c po = queryPurchaseOrder(purchaseOrderId);
        if (po == null) {
            throw new AuraHandledException('Purchase order not found.');
        }
        if (FINAL_APPROVAL_STATUSES.contains(po.Approval_Status__c)) {
            throw new AuraHandledException('Finalized orders cannot be re-submitted for approval.');
        }
        po.Approval_Status__c = 'Pending Approval';
        po.Status__c = 'Submitted';

        update po;
        return queryPurchaseOrder(po.Id);
    }

    public static Purchase_Order__c setApprovalDecision(Id purchaseOrderId, String decision) {
        if (String.isBlank(decision) || !FINAL_APPROVAL_STATUSES.contains(decision)) {
            throw new AuraHandledException('Approval decision must be Approved or Rejected.');
        }

        Purchase_Order__c po = queryPurchaseOrder(purchaseOrderId);
        if (po == null) {
            throw new AuraHandledException('Purchase order not found.');
        }
        if (po.Approval_Status__c != 'Pending Approval') {
            throw new AuraHandledException('Only pending approval orders can be finalized.');
        }

        po.Approval_Status__c = decision;
        if (decision == 'Approved' && po.Status__c == 'Submitted') {
            po.Status__c = 'Approved';
        } else if (decision == 'Rejected' && po.Status__c == 'Submitted') {
            po.Status__c = 'Rejected';
        }

        update po;
        return queryPurchaseOrder(po.Id);
    }

    public static Request_For_Quotation__c convertRfpToRfq(Id rfpId, String supplierName, String supplierEmail, Date validUntilDate) {
        if (rfpId == null) {
            throw new AuraHandledException('RFP Id is required.');
        }
        if (String.isBlank(supplierName)) {
            throw new AuraHandledException('Supplier name is required to create RFQ.');
        }
        if (validUntilDate == null || validUntilDate < Date.today()) {
            throw new AuraHandledException('Valid until date must be today or later.');
        }

        Request_For_Proposal__c rfp = getRfpById(rfpId);
        if (rfp == null) {
            throw new AuraHandledException('RFP not found.');
        }

        if (rfp.Status__c != 'Approved' && rfp.Status__c != 'Under Review') {
            throw new AuraHandledException('Only approved or under-review RFPs can be converted to RFQ.');
        }

        Request_For_Quotation__c rfq = new Request_For_Quotation__c(
            Request_For_Proposal__c = rfp.Id,
            Supplier_Name__c = supplierName,
            Supplier_Email__c = supplierEmail,
            Quote_Amount__c = (rfp.Estimated_Budget__c == null ? 0 : rfp.Estimated_Budget__c),
            Valid_Until__c = validUntilDate,
            Status__c = 'Sent',
            Evaluation_Notes__c = 'Created from RFP ' + rfp.Name
        );
        ensureCreateAccess(Schema.sObjectType.Request_For_Quotation__c, 'RFQ');
        rfq = (Request_For_Quotation__c) sanitizeForCreate(rfq);
        insert rfq;

        rfp.Status__c = 'Converted to RFQ';
        ensureUpdateAccess(Schema.sObjectType.Request_For_Proposal__c, 'RFP');
        rfp = (Request_For_Proposal__c) sanitizeForUpdate(rfp);
        update rfp;

        return [
            SELECT Id, Name, Request_For_Proposal__c, Request_For_Proposal__r.Department__c, Supplier_Name__c, Supplier_Email__c,
                   Quote_Amount__c, Valid_Until__c, Status__c, Purchase_Order__c
            FROM Request_For_Quotation__c
            WHERE Id = :rfq.Id
            LIMIT 1
        ];
    }

    public static Purchase_Order__c convertRfqToPurchaseOrder(Id rfqId, String requesterName, Date expectedDeliveryDate) {
        if (rfqId == null) {
            throw new AuraHandledException('RFQ Id is required.');
        }
        if (String.isBlank(requesterName)) {
            throw new AuraHandledException('Requester is required to create PO from RFQ.');
        }
        if (expectedDeliveryDate == null || expectedDeliveryDate < Date.today()) {
            throw new AuraHandledException('Expected delivery date must be today or later.');
        }

        Request_For_Quotation__c rfq = getRfqById(rfqId);
        if (rfq == null) {
            throw new AuraHandledException('RFQ not found.');
        }

        if (rfq.Status__c != 'Selected' && rfq.Status__c != 'Quoted') {
            throw new AuraHandledException('Only selected or quoted RFQs can be converted to Purchase Orders.');
        }
        if (rfq.Purchase_Order__c != null) {
            throw new AuraHandledException('RFQ is already linked to a Purchase Order.');
        }
        if (rfq.Quote_Amount__c == null || rfq.Quote_Amount__c <= 0) {
            throw new AuraHandledException('RFQ quote amount must be greater than zero for PO conversion.');
        }

        Purchase_Order__c po = new Purchase_Order__c(
            Supplier_Name__c = rfq.Supplier_Name__c,
            Supplier_Email__c = rfq.Supplier_Email__c,
            Requester__c = requesterName,
            Status__c = 'Draft',
            Approval_Status__c = 'Not Submitted',
            Priority__c = 'Medium',
            Order_Date__c = Date.today(),
            Expected_Delivery_Date__c = expectedDeliveryDate,
            Budget_Amount__c = rfq.Quote_Amount__c,
            Department__c = rfq.Request_For_Proposal__r == null ? 'Procurement' : rfq.Request_For_Proposal__r.Department__c
        );
        po = savePurchaseOrder(po);

        rfq.Purchase_Order__c = po.Id;
        rfq.Status__c = 'Converted to PO';
        ensureUpdateAccess(Schema.sObjectType.Request_For_Quotation__c, 'RFQ');
        rfq = (Request_For_Quotation__c) sanitizeForUpdate(rfq);
        update rfq;

        return queryPurchaseOrder(po.Id);
    }

    public static Map<String, Object> sendRfpToExperienceCloudUsers(Id rfpId, List<Id> userIds, String customMessage) {
        if (rfpId == null) {
            throw new AuraHandledException('RFP Id is required.');
        }
        if (userIds == null || userIds.isEmpty()) {
            throw new AuraHandledException('At least one Experience Cloud user is required.');
        }

        Request_For_Proposal__c rfp = getRfpForDistribution(rfpId);
        if (rfp == null) {
            throw new AuraHandledException('RFP not found.');
        }

        if (rfp.Status__c != 'Approved' && rfp.Status__c != 'Under Review' && rfp.Status__c != 'Submitted') {
            throw new AuraHandledException('RFP must be Submitted, Under Review, or Approved before distribution.');
        }

        Set<Id> uniqueUserIds = new Set<Id>(userIds);
        List<User> targets = [
            SELECT Id, Name, Email, IsActive, IsPortalEnabled
            FROM User
            WHERE Id IN :uniqueUserIds
              AND IsActive = true
              AND Email != null
        ];

        if (!Test.isRunningTest()) {
            List<User> portalOnly = new List<User>();
            for (User u : targets) {
                if (u.IsPortalEnabled) {
                    portalOnly.add(u);
                }
            }
            targets = portalOnly;
        }

        if (targets.isEmpty()) {
            throw new AuraHandledException('No active Experience Cloud users with email were found for distribution.');
        }

        String messageBody = String.isBlank(customMessage)
            ? 'A new RFP is available: ' + rfp.Name + ' - ' + rfp.Title__c
            : customMessage;

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (User target : targets) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTargetObjectId(target.Id);
            msg.setSaveAsActivity(false);
            msg.setSubject('New RFP Available: ' + rfp.Name);
            msg.setPlainTextBody(messageBody + '\n\nPlease review this RFP in Experience Cloud.');
            emails.add(msg);
        }

        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);

        Integer successCount = 0;
        Integer failureCount = 0;
        for (Messaging.SendEmailResult r : results) {
            if (r.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
            }
        }

        rfp.Last_Distribution_Date__c = System.now();
        if (failureCount == 0) {
            rfp.Distribution_Status__c = 'Sent';
            rfp.Distribution_Notes__c = 'Sent to ' + successCount + ' Experience Cloud users.';
        } else if (successCount > 0) {
            rfp.Distribution_Status__c = 'Partially Sent';
            rfp.Distribution_Notes__c = 'Sent to ' + successCount + ' users, failed for ' + failureCount + ' users.';
        } else {
            rfp.Distribution_Status__c = 'Failed';
            rfp.Distribution_Notes__c = 'Distribution failed for all recipients.';
        }
        ensureUpdateAccess(Schema.sObjectType.Request_For_Proposal__c, 'RFP');
        rfp = (Request_For_Proposal__c) sanitizeForUpdate(rfp);
        update rfp;

        return new Map<String, Object>{
            'rfpId' => rfp.Id,
            'sentCount' => successCount,
            'failedCount' => failureCount,
            'distributionStatus' => rfp.Distribution_Status__c
        };
    }


    public static Purchase_Order_Line__c saveLineItem(Purchase_Order_Line__c lineItem) {
        if (lineItem == null || lineItem.Purchase_Order__c == null) {
            throw new AuraHandledException('Line item with parent purchase order is required.');
        }
        if (lineItem.Quantity__c == null || lineItem.Quantity__c <= 0 ||
            lineItem.Unit_Price__c == null || lineItem.Unit_Price__c < 0) {
            throw new AuraHandledException('Line item quantity must be positive and price must not be negative.');
        }

        if (lineItem.Id == null) {
            if (!Schema.sObjectType.Purchase_Order_Line__c.isCreateable()) {
                throw new AuraHandledException('Insufficient access to create purchase order lines.');
            }
            lineItem = (Purchase_Order_Line__c) sanitizeForCreate(lineItem);
            insert lineItem;
        } else {
            if (!Schema.sObjectType.Purchase_Order_Line__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient access to update purchase order lines.');
            }
            lineItem = (Purchase_Order_Line__c) sanitizeForUpdate(lineItem);
            update lineItem;
        }

        return [
            SELECT Id, Name, Purchase_Order__c, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Line_Total__c
            FROM Purchase_Order_Line__c
            WHERE Id = :lineItem.Id
            LIMIT 1
        ];
    }

    public static Map<String, Object> getDashboardMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        List<AggregateResult> statusAgg = [
            SELECT Status__c status, COUNT(Id) countVal, SUM(Total_Amount__c) totalVal
            FROM Purchase_Order__c
            GROUP BY Status__c
        ];

        Decimal openAmount = 0;
        Integer overdueCount = 0;
        Integer pendingApprovalCount = 0;
        Integer overBudgetCount = 0;
        Decimal currentMonthAmount = 0;
        Date firstDay = Date.today().toStartOfMonth();
        Date lastDay = firstDay.addMonths(1).addDays(-1);

        for (AggregateResult row : statusAgg) {
            String status = (String) row.get('status');
            Integer countVal = (Integer) row.get('countVal');
            Decimal totalVal = (Decimal) row.get('totalVal');
            if (totalVal == null) {
                totalVal = 0;
            }

            if (!CLOSED_STATUSES.contains(status)) {
                openAmount += totalVal;
            }

            metrics.put('status_' + status, new Map<String, Object>{
                'count' => countVal,
                'amount' => totalVal
            });
        }

        for (Purchase_Order__c orderRecord : [
            SELECT Id, Status__c, Approval_Status__c, Expected_Delivery_Date__c, Order_Date__c,
                   Budget_Amount__c, Total_Amount__c
            FROM Purchase_Order__c
            WHERE Status__c NOT IN :CLOSED_STATUSES
        ]) {
            if (orderRecord.Expected_Delivery_Date__c != null && orderRecord.Expected_Delivery_Date__c < Date.today()) {
                overdueCount++;
            }
            if (orderRecord.Order_Date__c != null && orderRecord.Order_Date__c >= firstDay && orderRecord.Order_Date__c <= lastDay) {
                currentMonthAmount += (orderRecord.Total_Amount__c == null ? 0 : orderRecord.Total_Amount__c);
            }
            if (orderRecord.Approval_Status__c == 'Pending Approval') {
                pendingApprovalCount++;
            }
            if (orderRecord.Budget_Amount__c != null && orderRecord.Total_Amount__c != null
                && orderRecord.Total_Amount__c > orderRecord.Budget_Amount__c) {
                overBudgetCount++;
            }
        }

        metrics.put('openAmount', openAmount);
        metrics.put('overdueCount', overdueCount);
        metrics.put('currentMonthAmount', currentMonthAmount);
        metrics.put('pendingApprovalCount', pendingApprovalCount);
        metrics.put('overBudgetCount', overBudgetCount);

        return metrics;
    }

    private static Request_For_Proposal__c getRfpById(Id rfpId) {
        List<Request_For_Proposal__c> records = [
            SELECT Id, Name, Title__c, Department__c, Requested_By__c, Needed_By_Date__c,
                   Status__c, Estimated_Budget__c
            FROM Request_For_Proposal__c
            WHERE Id = :rfpId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    private static Request_For_Proposal__c getRfpForDistribution(Id rfpId) {
        List<Request_For_Proposal__c> records = [
            SELECT Id, Name, Title__c, Status__c, Distribution_Status__c,
                   Last_Distribution_Date__c, Distribution_Notes__c
            FROM Request_For_Proposal__c
            WHERE Id = :rfpId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    private static Request_For_Quotation__c getRfqById(Id rfqId) {
        List<Request_For_Quotation__c> records = [
            SELECT Id, Name, Request_For_Proposal__c, Request_For_Proposal__r.Department__c,
                   Supplier_Name__c, Supplier_Email__c, Quote_Amount__c,
                   Valid_Until__c, Status__c, Purchase_Order__c
            FROM Request_For_Quotation__c
            WHERE Id = :rfqId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    private static Purchase_Order__c queryPurchaseOrder(Id purchaseOrderId) {
        if (purchaseOrderId == null) {
            return null;
        }

        List<Purchase_Order__c> records = [
            SELECT Id, Name, Supplier_Name__c, Supplier_Email__c, Requester__c, Department__c,
                   Status__c, Approval_Status__c, Priority__c, Order_Date__c, Expected_Delivery_Date__c,
                   Tax_Amount__c, Shipping_Amount__c, Discount_Amount__c, Budget_Amount__c,
                   Remaining_Budget__c, Is_Overdue__c, Subtotal_Amount__c, Total_Amount__c
            FROM Purchase_Order__c
            WHERE Id = :purchaseOrderId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    private static void upsertPurchaseOrder(Purchase_Order__c purchaseOrder) {
        if (purchaseOrder.Id == null) {
            if (!Schema.sObjectType.Purchase_Order__c.isCreateable()) {
                throw new AuraHandledException('Insufficient access to create purchase orders.');
            }
            purchaseOrder = (Purchase_Order__c) sanitizeForCreate(purchaseOrder);
            insert purchaseOrder;
        } else {
            if (!Schema.sObjectType.Purchase_Order__c.isUpdateable()) {
                throw new AuraHandledException('Insufficient access to update purchase orders.');
            }
            purchaseOrder = (Purchase_Order__c) sanitizeForUpdate(purchaseOrder);
            update purchaseOrder;
        }
    }

    private static void normalizeDefaults(Purchase_Order__c purchaseOrder) {
        if (String.isBlank(purchaseOrder.Status__c)) {
            purchaseOrder.Status__c = 'Draft';
        }
        if (String.isBlank(purchaseOrder.Approval_Status__c)) {
            purchaseOrder.Approval_Status__c = 'Not Submitted';
        }
        if (String.isBlank(purchaseOrder.Priority__c)) {
            purchaseOrder.Priority__c = 'Medium';
        }
        if (purchaseOrder.Order_Date__c == null) {
            purchaseOrder.Order_Date__c = Date.today();
        }
    }

    private static SObject sanitizeForCreate(SObject record) {
        List<SObject> sanitized = Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{record}).getRecords();
        return sanitized[0];
    }

    private static SObject sanitizeForUpdate(SObject record) {
        List<SObject> sanitized = Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{record}).getRecords();
        return sanitized[0];
    }

    private static void ensureCreateAccess(Schema.SObjectType objectType, String label) {
        if (!objectType.isCreateable()) {
            throw new AuraHandledException('Insufficient access to create ' + label + ' records.');
        }
    }

    private static void ensureUpdateAccess(Schema.SObjectType objectType, String label) {
        if (!objectType.isUpdateable()) {
            throw new AuraHandledException('Insufficient access to update ' + label + ' records.');
        }
    }

    private static void validateBusinessRules(Purchase_Order__c purchaseOrder) {
        if (String.isBlank(purchaseOrder.Supplier_Name__c)) {
            throw new AuraHandledException('Supplier name is required.');
        }
        if (String.isBlank(purchaseOrder.Requester__c)) {
            throw new AuraHandledException('Requester is required.');
        }
        if (purchaseOrder.Expected_Delivery_Date__c != null && purchaseOrder.Order_Date__c != null
            && purchaseOrder.Expected_Delivery_Date__c < purchaseOrder.Order_Date__c) {
            throw new AuraHandledException('Expected delivery date cannot be earlier than order date.');
        }
        if (purchaseOrder.Budget_Amount__c != null && purchaseOrder.Budget_Amount__c < 0) {
            throw new AuraHandledException('Budget amount must not be negative.');
        }
    }
}
