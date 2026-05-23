@isTest
private class REAPP_LeaseAgreementTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Property__c prop = new Property__c(
            Name           = 'Sunrise Apartment',
            Address__c     = '123 Main St',
            City__c        = 'Chennai',
            State__c       = 'Tamil Nadu',
            Postal_Code__c = '600001',
            Country__c     = 'India',
            Type__c        = 'Residential',
            Status__c      = 'Available',
            Rent__c        = 25000,
            Description__c = 'Test Property'
        );
        insert prop;

        Tenant__c tenant = new Tenant__c(
            Name            = 'John Doe',
            Phone_Number__c = '9999999999',
            Email__c        = 'john@test.com'
        );
        insert tenant;
    }

    @isTest
    static void testSingleLeaseCreatesOneTask() {
        Property__c prop   = [SELECT Id FROM Property__c LIMIT 1];
        Tenant__c tenant   = [SELECT Id FROM Tenant__c LIMIT 1];

        Lease_Agreement__c lease = new Lease_Agreement__c(
            Property__c            = prop.Id,
            Tenant__c              = tenant.Id,
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c          = Date.today(),
            End_Date__c            = Date.today().addMonths(12),
            Terms__c               = 'Standard terms'
        );

        Test.startTest();
            insert lease;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, Status, Priority, WhatId, ActivityDate
                            FROM Task WHERE WhatId = :lease.Id];

        System.assertEquals(1, tasks.size(), 'One Task should be created');
        System.assertEquals('Not Started', tasks[0].Status);
        System.assertEquals('High', tasks[0].Priority);
        System.assert(tasks[0].Subject.contains('Sunrise Apartment'));
        System.assertEquals(Date.today().addDays(3), tasks[0].ActivityDate);
    }

    @isTest
    static void testBulkLeaseCreatesBulkTasks() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        Tenant__c tenant = [SELECT Id FROM Tenant__c LIMIT 1];

        List<Lease_Agreement__c> leases = new List<Lease_Agreement__c>();
        for (Integer i = 0; i < 200; i++) {
            leases.add(new Lease_Agreement__c(
                Property__c            = prop.Id,
                Tenant__c              = tenant.Id,
                Agreed_Monthly_Rent__c = 25000,
                Start_Date__c          = Date.today(),
                End_Date__c            = Date.today().addMonths(12),
                Terms__c               = 'Standard terms'
            ));
        }

        Test.startTest();
            insert leases;
        Test.stopTest();

        Set<Id> leaseIds = new Map<Id, Lease_Agreement__c>(leases).keySet();
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :leaseIds];

        System.assertEquals(200, tasks.size(), '200 Tasks should be created');
    }

    @isTest
    static void testUpdateDoesNotCreateExtraTask() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        Tenant__c tenant = [SELECT Id FROM Tenant__c LIMIT 1];

        Lease_Agreement__c lease = new Lease_Agreement__c(
            Property__c            = prop.Id,
            Tenant__c              = tenant.Id,
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c          = Date.today(),
            End_Date__c            = Date.today().addMonths(12),
            Terms__c               = 'Standard terms'
        );
        insert lease;

        Test.startTest();
            lease.Agreed_Monthly_Rent__c = 30000;
            update lease;
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :lease.Id];
        System.assertEquals(1, tasks.size(), 'Update should not create extra Tasks');
    }
}