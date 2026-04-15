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
    public static Purchase_Order_Line__c saveLineItem(Purchase_Order_Line__c lineItem) {
        return PurchaseOrderService.saveLineItem(lineItem);
    }

    @AuraEnabled
    public static Map<String, Object> getDashboardMetrics() {
        return PurchaseOrderService.getDashboardMetrics();
    }
}
