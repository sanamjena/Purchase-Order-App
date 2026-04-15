// Apex Class for handling Purchase Orders
public with sharing class PurchaseOrderController {
    @AuraEnabled
    public static List<PurchaseOrder__c> getPurchaseOrders() {
        return [SELECT Id, OrderNumber__c, Status__c, TotalAmount__c FROM PurchaseOrder__c];
    }
}