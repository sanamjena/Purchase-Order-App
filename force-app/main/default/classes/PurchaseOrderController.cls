public with sharing class PurchaseOrderController {
    @AuraEnabled(cacheable=true)
    public static List<Purchase_Order__c> getPurchaseOrders() {
        return PurchaseOrderService.getPurchaseOrders();
    }

    @AuraEnabled(cacheable=true)
    public static List<Purchase_Order_Line__c> getLinesForOrder(Id purchaseOrderId) {
        return PurchaseOrderService.getLinesForOrder(purchaseOrderId);
    }

    @AuraEnabled
    public static Purchase_Order__c savePurchaseOrder(Purchase_Order__c purchaseOrder) {
        return PurchaseOrderService.savePurchaseOrder(purchaseOrder);
    }

    @AuraEnabled
    public static Purchase_Order__c submitForApproval(Id purchaseOrderId) {
        return PurchaseOrderService.submitForApproval(purchaseOrderId);
    }

    @AuraEnabled
    public static Purchase_Order__c setApprovalDecision(Id purchaseOrderId, String decision) {
        return PurchaseOrderService.setApprovalDecision(purchaseOrderId, decision);
    }

    @AuraEnabled
    public static Request_For_Quotation__c convertRfpToRfq(Id rfpId, String supplierName, String supplierEmail, Date validUntilDate) {
        return PurchaseOrderService.convertRfpToRfq(rfpId, supplierName, supplierEmail, validUntilDate);
    }

    @AuraEnabled
    public static Purchase_Order__c convertRfqToPurchaseOrder(Id rfqId, String requesterName, Date expectedDeliveryDate) {
        return PurchaseOrderService.convertRfqToPurchaseOrder(rfqId, requesterName, expectedDeliveryDate);
    }

    @AuraEnabled
    public static Map<String, Object> sendRfpToExperienceCloudUsers(Id rfpId, List<Id> userIds, String customMessage) {
        return PurchaseOrderService.sendRfpToExperienceCloudUsers(rfpId, userIds, customMessage);
    }


    @AuraEnabled
    public static Purchase_Order_Line__c saveLineItem(Purchase_Order_Line__c lineItem) {
        return PurchaseOrderService.saveLineItem(lineItem);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardMetrics() {
        return PurchaseOrderService.getDashboardMetrics();
    }
}
