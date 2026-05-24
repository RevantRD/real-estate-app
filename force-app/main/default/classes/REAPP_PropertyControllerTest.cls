@IsTest
private class REAPP_PropertyControllerTest {

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"lat":"10.9596041","lon":"78.0807797","display_name":"Karur, Tamil Nadu, India"}]');
            return res;
        }
    }

    @TestSetup
    static void setup() {
        insert new List<Property__c>{
            new Property__c(
                Name                   = 'Raja Nagar Karur',
                Address__c             = '45/5, RAJA NAGAR, 7TH CROSS, RAMANOOR',
                City__c                = 'Karur',
                State__c               = 'Tamil Nadu',
                Country__c             = 'India',
                Postal_Code__c         = '639004',
                Rent__c                = 20,
                Type__c                = 'Residential',
                Furnishing_Status__c   = 'Unfurnished',
                Status__c              = 'Occupied',
                Description__c         = 'Budget property in Karur',
                Location__Latitude__s  = 10.9596041,
                Location__Longitude__s = 78.0807797
            ),
            new Property__c(
                Name                   = 'Park Avenue Chennai',
                Address__c             = '71 Park Avenue',
                City__c                = 'Chennai',
                State__c               = 'Tamil Nadu',
                Country__c             = 'India',
                Postal_Code__c         = '600047',
                Rent__c                = 62400,
                Type__c                = 'Residential',
                Furnishing_Status__c   = 'Furnished',
                Status__c              = 'Available',
                Description__c         = '2BHK property in prime location',
                Location__Latitude__s  = 13.0836939,
                Location__Longitude__s = 80.2701860
            ),
            new Property__c(
                Name                   = 'Coimbatore Commercial',
                Address__c             = '12 Industrial Road',
                City__c                = 'Coimbatore',
                State__c               = 'Tamil Nadu',
                Country__c             = 'India',
                Postal_Code__c         = '641001',
                Rent__c                = 35000,
                Type__c                = 'Commercial',
                Furnishing_Status__c   = 'Semi-Furnished',
                Status__c              = 'Available',
                Description__c         = 'Commercial space in Coimbatore',
                Location__Latitude__s  = 11.0168,
                Location__Longitude__s = 76.9558
            )
        };
    }

    @IsTest
    static void testGetPropertiesNoFilters() {
        Test.startTest();
        REAPP_PropertyController.PropertyResponse res =
            REAPP_PropertyController.getProperties(10, 1, null, null, null, null, null, null);
        Test.stopTest();

        Assert.areEqual(3, res.totalRecords, 'Should return all 3 properties');
        Assert.areEqual(3, res.properties.size(), 'Page should contain all 3 properties');
    }

    @IsTest
    static void testGetPropertiesStatusFilter() {
        Test.startTest();
        REAPP_PropertyController.PropertyResponse res =
            REAPP_PropertyController.getProperties(10, 1, 'Available', null, null, null, null, null);
        Test.stopTest();

        Assert.areEqual(2, res.totalRecords, 'Should return 2 available properties');
        for (Property__c p : res.properties) {
            Assert.areEqual('Available', p.Status__c, 'All results should be Available');
        }
    }

    @IsTest
    static void testGetPropertiesFurnishingFilter() {
        Test.startTest();
        REAPP_PropertyController.PropertyResponse res =
            REAPP_PropertyController.getProperties(10, 1, null, 'Furnished', null, null, null, null);
        Test.stopTest();

        Assert.areEqual(1, res.totalRecords, 'Should return 1 furnished property');
        Assert.areEqual('Furnished', res.properties[0].Furnishing_Status__c);
        Assert.areEqual('Park Avenue Chennai', res.properties[0].Name);
    }

    @IsTest
    static void testGetPropertiesMaxPriceFilter() {
        Test.startTest();
        REAPP_PropertyController.PropertyResponse res =
            REAPP_PropertyController.getProperties(10, 1, null, null, 25, null, null, null);
        Test.stopTest();

        Assert.areEqual(1, res.totalRecords, 'Should return 1 property under rent 25');
        Assert.isTrue(res.properties[0].Rent__c <= 25, 'Rent should be within filter');
    }

    @IsTest
    static void testGetPropertiesCombinedFilters() {
        Test.startTest();
        REAPP_PropertyController.PropertyResponse res =
            REAPP_PropertyController.getProperties(10, 1, 'Available', 'Furnished', 70000, null, null, null);
        Test.stopTest();

        Assert.areEqual(1, res.totalRecords, 'Should return 1 available furnished property');
        Assert.areEqual('Available', res.properties[0].Status__c);
        Assert.areEqual('Furnished', res.properties[0].Furnishing_Status__c);
    }

    @IsTest
    static void testGetPropertiesPagination() {
        Test.startTest();
        REAPP_PropertyController.PropertyResponse page1 =
            REAPP_PropertyController.getProperties(2, 1, null, null, null, null, null, null);
        REAPP_PropertyController.PropertyResponse page2 =
            REAPP_PropertyController.getProperties(2, 2, null, null, null, null, null, null);
        Test.stopTest();

        Assert.areEqual(3, page1.totalRecords, 'Total should always be 3');
        Assert.areEqual(2, page1.properties.size(), 'Page 1 should have 2 records');
        Assert.areEqual(3, page2.totalRecords, 'Total should always be 3');
        Assert.areEqual(1, page2.properties.size(), 'Page 2 should have 1 record');
    }

    @IsTest
    static void testGetPropertiesNoResults() {
        Test.startTest();
        REAPP_PropertyController.PropertyResponse res =
            REAPP_PropertyController.getProperties(10, 1, 'Available', null, 5, null, null, null);
        Test.stopTest();

        Assert.areEqual(0, res.totalRecords, 'Should return 0 results');
        Assert.areEqual(0, res.properties.size(), 'Properties list should be empty');
    }

    @IsTest
    static void testCreatePropertyWithoutDocuments() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Property__c newProp = new Property__c(
            Name                 = 'Testt',
            Address__c           = '45/5, RAJA NAGAR, 7TH CROSS, RAMANOOR',
            City__c              = 'Karur',
            State__c             = 'Tamil Nadu',
            Country__c           = 'India',
            Postal_Code__c       = '639004',
            Rent__c              = 20,
            Type__c              = 'Residential',
            Furnishing_Status__c = 'Unfurnished',
            Status__c            = 'Occupied',
            Description__c       = 'Test property in Karur'
        );

        Test.startTest();
        Id propId = REAPP_PropertyController.createPropertyWithImage(newProp, null);
        Test.stopTest();

        Assert.isNotNull(propId, 'Should return a valid property Id');
        Property__c inserted = [
            SELECT Name, City__c, State__c, Postal_Code__c, Country__c,
                   Rent__c, Type__c, Furnishing_Status__c, Status__c
            FROM Property__c WHERE Id = :propId
        ];
        Assert.areEqual('Testt', inserted.Name);
        Assert.areEqual('Karur', inserted.City__c);
        Assert.areEqual('Tamil Nadu', inserted.State__c);
        Assert.areEqual('639004', inserted.Postal_Code__c);
        Assert.areEqual('India', inserted.Country__c);
        Assert.areEqual(20, inserted.Rent__c);
        Assert.areEqual('Residential', inserted.Type__c);
        Assert.areEqual('Unfurnished', inserted.Furnishing_Status__c);
        Assert.areEqual('Occupied', inserted.Status__c);
    }

    @IsTest
    static void testCreatePropertyWithEmptyDocumentList() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Property__c newProp = new Property__c(
            Name                 = 'Testt',
            Address__c           = '45/5, RAJA NAGAR, 7TH CROSS, RAMANOOR',
            City__c              = 'Karur',
            State__c             = 'Tamil Nadu',
            Country__c           = 'India',
            Postal_Code__c       = '639004',
            Rent__c              = 20,
            Type__c              = 'Residential',
            Furnishing_Status__c = 'Unfurnished',
            Status__c            = 'Occupied'
        );

        Test.startTest();
        Id propId = REAPP_PropertyController.createPropertyWithImage(newProp, new List<String>());
        Test.stopTest();

        Assert.isNotNull(propId, 'Should return a valid property Id');
    }

    @IsTest
    static void testPropertyResponseWrapper() {
        List<Property__c> props = [SELECT Id FROM Property__c LIMIT 2];
        REAPP_PropertyController.PropertyResponse response =
            new REAPP_PropertyController.PropertyResponse(props, 10);

        Assert.areEqual(10, response.totalRecords);
        Assert.areEqual(2, response.properties.size());
    }
    @IsTest
static void testCreatePropertyWithDocuments() {
    // Create a ContentVersion (this will generate a ContentDocument)
    ContentVersion cv = new ContentVersion(
        Title = 'TestDoc',
        PathOnClient = 'TestDoc.pdf',
        VersionData = Blob.valueOf('Test file body'),
        IsMajorVersion = true
    );
    insert cv;

    // Query back the ContentDocumentId
    Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

    // Create a property record
    Property__c newProp = new Property__c(
        Name = 'Property With Doc',
        Address__c = '123 Test Street',
        City__c = 'Karur',
        State__c = 'Tamil Nadu',
        Country__c = 'India',
        Postal_Code__c = '639004',
        Rent__c = 10000,
        Type__c = 'Residential',
        Furnishing_Status__c = 'Furnished',
        Status__c = 'Available'
    );

    Test.startTest();
    Id propId = REAPP_PropertyController.createPropertyWithImage(newProp, new List<String>{ docId });
    Test.stopTest();

    // Assert property was created
    System.assertNotEquals(null, propId);

    // Assert ContentDocumentLink was created
    ContentDocumentLink link = [
        SELECT ContentDocumentId, LinkedEntityId, ShareType
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :propId
        LIMIT 1
    ];
    System.assertEquals(docId, link.ContentDocumentId);
    System.assertEquals('V', link.ShareType);
}

}