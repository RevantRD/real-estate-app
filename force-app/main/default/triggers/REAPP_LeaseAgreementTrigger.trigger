trigger REAPP_LeaseAgreementTrigger on Lease_Agreement__c (after insert) {
    REAPP_LeaseAgreementTriggerHandler.createTasksForNewLeaseAgreements(Trigger.new);
}