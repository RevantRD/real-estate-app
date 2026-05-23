trigger REAPP_PropertyTrigger on Property__c (after insert, after update) {
    REAPP_PropertyTriggerHandler.afterInsertOrUpdate(Trigger.new, Trigger.oldMap);
}