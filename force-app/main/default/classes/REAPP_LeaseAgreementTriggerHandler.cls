public class REAPP_LeaseAgreementTriggerHandler {

    public static void createTasksForNewLeaseAgreements(List<Lease_Agreement__c> newLeases) {

        // Step 1: Collect Property IDs to fetch names in one SOQL
        Set<Id> propertyIds = new Set<Id>();
        for (Lease_Agreement__c lease : newLeases) {
            if (lease.Property__c != null) {
                propertyIds.add(lease.Property__c);
            }
        }

        // Step 2: Single SOQL — never inside a loop
        Map<Id, Property__c> propertyMap = new Map<Id, Property__c>(
            [SELECT Id, Name FROM Property__c WHERE Id IN :propertyIds]
        );

        // Step 3: Build Task list
        List<Task> tasksToInsert = new List<Task>();

        for (Lease_Agreement__c lease : newLeases) {
            String propertyName = '';
            if (lease.Property__c != null && propertyMap.containsKey(lease.Property__c)) {
                propertyName = propertyMap.get(lease.Property__c).Name;
            }

            Task t = new Task();
            t.Subject      = 'Generate Lease Agreement' +
                             (String.isNotBlank(propertyName) ? ' for ' + propertyName : '');
            t.Status       = 'Not Started';
            t.Priority     = 'High';
            t.WhatId       = lease.Id;
            t.OwnerId      = lease.OwnerId;
            t.ActivityDate = Date.today().addDays(3);
            t.Description  = 'A new lease agreement has been created. Please generate and send the lease document to the tenant.';

            tasksToInsert.add(t);
        }

        // Step 4: Single DML — never inside a loop
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}