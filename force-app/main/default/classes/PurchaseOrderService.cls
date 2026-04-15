public with sharing class PurchaseOrderService {
    @AuraEnabled
    public static String createPurchaseOrder(String purchaseOrderJson) {
        try {
            // Logic to create a purchase order
            // Deserialize JSON
            PurchaseOrder__c newOrder = (PurchaseOrder__c)JSON.deserialize(purchaseOrderJson, PurchaseOrder__c.class);
            insert newOrder;
            return newOrder.Id;
        } catch (DmlException e) {
            // Handle DML exception
            throw new AuraHandledException('Error creating purchase order: ' + e.getMessage());
        } catch (Exception e) {
            // Handle any other exceptions
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updatePurchaseOrder(String purchaseOrderId, String purchaseOrderJson) {
        try {
            // Logic to update a purchase order
            PurchaseOrder__c existingOrder = [SELECT Id, Name FROM PurchaseOrder__c WHERE Id = :purchaseOrderId LIMIT 1];
            // Deserialize JSON
            PurchaseOrder__c updatedOrder = (PurchaseOrder__c)JSON.deserialize(purchaseOrderJson, PurchaseOrder__c.class);
            // Update fields
            existingOrder.Name = updatedOrder.Name;
            update existingOrder;
        } catch (DmlException e) {
            // Handle DML exception
            throw new AuraHandledException('Error updating purchase order: ' + e.getMessage());
        } catch (QueryException e) {
            // Handle record not found
            throw new AuraHandledException('Purchase order not found: ' + e.getMessage());
        } catch (Exception e) {
            // Handle any other exceptions
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static PurchaseOrder__c getPurchaseOrder(String purchaseOrderId) {
        try {
            // Logic to retrieve a purchase order
            PurchaseOrder__c order = [SELECT Id, Name FROM PurchaseOrder__c WHERE Id = :purchaseOrderId LIMIT 1];
            return order;
        } catch (QueryException e) {
            // Handle record not found
            throw new AuraHandledException('Purchase order not found: ' + e.getMessage());
        } catch (Exception e) {
            // Handle any other exceptions
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePurchaseOrder(String purchaseOrderId) {
        try {
            // Logic to delete a purchase order
            PurchaseOrder__c orderToDelete = [SELECT Id FROM PurchaseOrder__c WHERE Id = :purchaseOrderId LIMIT 1];
            delete orderToDelete;
        } catch (DmlException e) {
            // Handle DML exception
            throw new AuraHandledException('Error deleting purchase order: ' + e.getMessage());
        } catch (QueryException e) {
            // Handle record not found
            throw new AuraHandledException('Purchase order not found: ' + e.getMessage());
        } catch (Exception e) {
            // Handle any other exceptions
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
}