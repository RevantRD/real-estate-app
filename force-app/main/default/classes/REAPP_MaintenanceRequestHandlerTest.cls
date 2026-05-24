@IsTest
private class REAPP_MaintenanceRequestHandlerTest {

    // ─────────────────────────────────────────────────────────
    // TEST DATA
    // ─────────────────────────────────────────────────────────

    private static Vendor__c makeVendor(String name) {

        return new Vendor__c(
            Name = name,
            Phone_Number__c = '9876543210',
            Email__c = name.replace(' ', '').toLowerCase() + '@test.com'
        );
    }

    private static Property__c makeProperty() {

        return new Property__c(

            Name = 'Test Property',

            Address__c = '123 Main Street',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Postal_Code__c = '600001',
            Country__c = 'India',

            Rent__c = 25000,
            Status__c = 'Available',
            Type__c = 'Residential',
            Furnishing_Status__c = 'Furnished',
            Description__c = 'Test Property Description'
        );
    }

    // ─────────────────────────────────────────────────────────
    // TEST LEAST BUSY VENDOR ASSIGNMENT
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testAssignLeastBusyVendor() {

        // Create vendors
        Vendor__c vendor1 = makeVendor('Vendor One');
        Vendor__c vendor2 = makeVendor('Vendor Two');

        insert new List<Vendor__c>{ vendor1, vendor2 };

        // Create property
        Property__c prop = makeProperty();
        insert prop;

        // Existing maintenance request for vendor1
        Maintenance_Request__c existingReq = new Maintenance_Request__c(

            Name = 'Existing Request',

            Property__c = prop.Id,
            Vendor__c = vendor1.Id,

            Status__c = 'Open',
            Description__c = 'Existing workload'
        );

        insert existingReq;

        // New request to assign
        Maintenance_Request__c newReq = new Maintenance_Request__c(

            Name = 'New Request',

            Property__c = prop.Id,

            Status__c = 'Open',
            Description__c = 'New maintenance request'
        );

        List<Maintenance_Request__c> requests =
            new List<Maintenance_Request__c>{ newReq };

        Test.startTest();

        REAPP_MaintenanceRequestHandler.assignVendors(requests);

        Test.stopTest();

        // Vendor2 should be assigned because vendor1 already has workload
        System.assertEquals(
            vendor2.Id,
            newReq.Vendor__c
        );
    }

    // ─────────────────────────────────────────────────────────
    // TEST EMPTY REQUEST LIST
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testEmptyRequestList() {

        Test.startTest();

        REAPP_MaintenanceRequestHandler.assignVendors(
            new List<Maintenance_Request__c>()
        );

        Test.stopTest();

        System.assert(true);
    }

    // ─────────────────────────────────────────────────────────
    // TEST NO VENDORS
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testNoVendors() {

        Property__c prop = makeProperty();
        insert prop;

        Maintenance_Request__c req = new Maintenance_Request__c(

            Name = 'No Vendor Request',

            Property__c = prop.Id,

            Status__c = 'Open',
            Description__c = 'No vendors available'
        );

        List<Maintenance_Request__c> requests =
            new List<Maintenance_Request__c>{ req };

        Test.startTest();

        REAPP_MaintenanceRequestHandler.assignVendors(requests);

        Test.stopTest();

        System.assertEquals(
            null,
            req.Vendor__c
        );
    }

    // ─────────────────────────────────────────────────────────
    // TEST SAME WORKLOAD
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testSameWorkloadVendors() {

        Vendor__c vendor1 = makeVendor('Vendor A');
        Vendor__c vendor2 = makeVendor('Vendor B');

        insert new List<Vendor__c>{ vendor1, vendor2 };

        Property__c prop = makeProperty();
        insert prop;

        Maintenance_Request__c req = new Maintenance_Request__c(

            Name = 'Equal Workload Request',

            Property__c = prop.Id,

            Status__c = 'Open',
            Description__c = 'Equal workload test'
        );

        List<Maintenance_Request__c> requests =
            new List<Maintenance_Request__c>{ req };

        Test.startTest();

        REAPP_MaintenanceRequestHandler.assignVendors(requests);

        Test.stopTest();

        // First vendor encountered gets assigned
        System.assertEquals(
            vendor1.Id,
            req.Vendor__c
        );
    }

    // ─────────────────────────────────────────────────────────
    // TEST CLOSED REQUESTS NOT COUNTED
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testClosedRequestsIgnored() {

        Vendor__c vendor1 = makeVendor('Vendor X');
        Vendor__c vendor2 = makeVendor('Vendor Y');

        insert new List<Vendor__c>{ vendor1, vendor2 };

        Property__c prop = makeProperty();
        insert prop;

        // Closed request should NOT count
        Maintenance_Request__c closedReq = new Maintenance_Request__c(

            Name = 'Closed Request',

            Property__c = prop.Id,
            Vendor__c = vendor1.Id,

            Status__c = 'Completed',
            Description__c = 'Closed request'
        );

        insert closedReq;

        Maintenance_Request__c newReq = new Maintenance_Request__c(

            Name = 'New Request',

            Property__c = prop.Id,

            Status__c = 'Open',
            Description__c = 'Fresh request'
        );

        List<Maintenance_Request__c> requests =
            new List<Maintenance_Request__c>{ newReq };

        Test.startTest();

        REAPP_MaintenanceRequestHandler.assignVendors(requests);

        Test.stopTest();

        // Since completed requests are ignored,
        // both vendors have equal workload
        System.assertEquals(
            vendor1.Id,
            newReq.Vendor__c
        );
    }
}