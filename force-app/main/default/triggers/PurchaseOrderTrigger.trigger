trigger PurchaseOrderTrigger on Purchase_Order__c (before insert, after insert, before update, after update) {
    // Code to handle logic before and after insert/update
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            // Logic for before insert
        }
        else if(Trigger.isUpdate) {
            // Logic for before update
        }
    }
    else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            // Logic for after insert
        }
        else if(Trigger.isUpdate) {
            // Logic for after update
        }
    }
}