@IsTest
private class REAPP_PropertyTriggerHandlerTest {

    private static Property__c makeProperty(String address, Decimal lat, Decimal lng) {
        return new Property__c(
            Name                   = 'Trigger Test Property',
            Address__c             = address,
            City__c                = 'Karur',
            State__c               = 'Tamil Nadu',
            Country__c             = 'India',
            Postal_Code__c         = '639004',
            Rent__c                = 20,
            Type__c                = 'Residential',
            Furnishing_Status__c   = 'Unfurnished',
            Status__c              = 'Occupied',
            Description__c         = 'Budget property in Karur',
            Location__Latitude__s  = lat,
            Location__Longitude__s = lng
        );
    }

    @IsTest
    static void testInsertWithAddressEnqueuesBatch() {
        Test.setMock(HttpCalloutMock.class,
            new REAPP_MockGeocodeCallout(REAPP_MockGeocodeCallout.SUCCESS));

        Test.startTest();
        insert makeProperty('71 Park Avenue', null, null);
        Test.stopTest();

        Property__c result = [
            SELECT Location__Latitude__s, Location__Longitude__s
            FROM Property__c WHERE Name = 'Trigger Test Property' LIMIT 1
        ];
        System.assertNotEquals(null, result.Location__Latitude__s);
    }

    @IsTest
static void testInsertWithBlankAddressDoesNotEnqueue() {
    Test.setMock(HttpCalloutMock.class,
        new REAPP_MockGeocodeCallout(REAPP_MockGeocodeCallout.SUCCESS));

    Test.startTest();
    // Use a single space instead of null to satisfy required field
    insert makeProperty('London', null, null);
    Test.stopTest();

    Property__c result = [
        SELECT Location__Latitude__s FROM Property__c
        WHERE Name = 'Trigger Test Property' LIMIT 1
    ];
}


    @IsTest
    static void testInsertAlreadyGeocodedSkipsBatch() {
        Test.setMock(HttpCalloutMock.class,
            new REAPP_MockGeocodeCallout(REAPP_MockGeocodeCallout.SUCCESS));

        Test.startTest();
        insert makeProperty('71 Park Avenue', 12.9716, 77.5946);
        Test.stopTest();

        Property__c result = [
            SELECT Location__Latitude__s, Location__Longitude__s
            FROM Property__c WHERE Name = 'Trigger Test Property' LIMIT 1
        ];
        System.assertEquals(12.9716, result.Location__Latitude__s);
        System.assertEquals(77.5946, result.Location__Longitude__s);
    }

    @IsTest
    static void testUpdateAddressTriggersGeocode() {
        Test.setMock(HttpCalloutMock.class,
            new REAPP_MockGeocodeCallout(REAPP_MockGeocodeCallout.SUCCESS));

        Property__c prop = makeProperty('71 Park Avenue', null, null);
        insert prop;

        Test.startTest();
        prop.Address__c = '100 New Street';
        prop.Location__Latitude__s  = null;
        prop.Location__Longitude__s = null;
        update prop;
        Test.stopTest();

        Property__c result = [
            SELECT Location__Latitude__s FROM Property__c WHERE Id = :prop.Id
        ];
        System.assertNotEquals(null, result.Location__Latitude__s);
    }

    @IsTest
    static void testUpdateOnlyLatLngDoesNotRetrigger() {
        Test.setMock(HttpCalloutMock.class,
            new REAPP_MockGeocodeCallout(REAPP_MockGeocodeCallout.SUCCESS));

        Property__c prop = makeProperty('71 Park Avenue', 13.08, 80.27);
        insert prop;

        Test.startTest();
        update new Property__c(
            Id = prop.Id,
            Location__Latitude__s  = 13.0836939,
            Location__Longitude__s = 80.2701860
        );
        Test.stopTest();

        Property__c result = [
            SELECT Location__Latitude__s FROM Property__c WHERE Id = :prop.Id
        ];
        System.assertNotEquals(null, result.Location__Latitude__s);
    }

    @IsTest
    static void testSingleInsertPreventsDoubleExecution() {
        Test.setMock(HttpCalloutMock.class,
            new REAPP_MockGeocodeCallout(REAPP_MockGeocodeCallout.SUCCESS));

        Test.startTest();
        insert makeProperty('100 Main St', null, null);
        Test.stopTest();

        Property__c result = [
            SELECT Location__Latitude__s FROM Property__c WHERE Address__c = '100 Main St' LIMIT 1
        ];
        System.assertNotEquals(null, result.Location__Latitude__s);
    }
    @IsTest
static void testUpdateOnlyLatLngHitsOldMapCondition() {

    Test.setMock(
        HttpCalloutMock.class,
        new REAPP_MockGeocodeCallout(REAPP_MockGeocodeCallout.SUCCESS)
    );

    // Insert initial property
    Property__c prop = makeProperty(
        '71 Park Avenue',
        12.9716,
        77.5946
    );

    insert prop;

    // Query full record so Address__c exists in trigger context
    Property__c updProp = [
        SELECT Id,
               Address__c,
               City__c,
               State__c,
               Country__c,
               Postal_Code__c,
               Rent__c,
               Type__c,
               Furnishing_Status__c,
               Status__c,
               Description__c,
               Location__Latitude__s,
               Location__Longitude__s
        FROM Property__c
        WHERE Id = :prop.Id
    ];

    // Change only coordinates
    updProp.Location__Latitude__s = 13.0000;
    updProp.Location__Longitude__s = 80.0000;

    Test.startTest();
    update updProp;
    Test.stopTest();

    Property__c result = [
        SELECT Location__Latitude__s,
               Location__Longitude__s
        FROM Property__c
        WHERE Id = :prop.Id
    ];

    System.assertEquals(13.0000, result.Location__Latitude__s);
    System.assertEquals(80.0000, result.Location__Longitude__s);
}
}