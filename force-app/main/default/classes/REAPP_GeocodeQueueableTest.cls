@IsTest
private class REAPP_GeocodeQueueableTest {

    // ─────────────────────────────────────────────────────────
    // MOCK CLASSES
    // ─────────────────────────────────────────────────────────

    private class SuccessMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            res.setBody(
                '[{"lat":"13.0836939","lon":"80.2701860"}]'
            );

            return res;
        }
    }

    private class EmptyMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[]');

            return res;
        }
    }

    private class RateLimitMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(429);
            res.setStatus('Too Many Requests');
            res.setBody('');

            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            throw new CalloutException('Mock Exception');
        }
    }

    // ─────────────────────────────────────────────────────────
    // TEST DATA
    // ─────────────────────────────────────────────────────────

    private static Property__c makeProperty(
        String city,
        Decimal lat,
        Decimal lng
    ) {

        return new Property__c(

            Name = 'Queueable Test ' + city + Math.random(),

            Address__c = '123 Test Street',
            City__c = city,
            State__c = 'Tamil Nadu',
            Postal_Code__c = '600001',
            Country__c = 'India',

            Rent__c = 10000,
            Status__c = 'Available',
            Type__c = 'Residential',
            Furnishing_Status__c = 'Unfurnished',
            Description__c = 'Queueable Test Property',

            Location__Latitude__s = lat,
            Location__Longitude__s = lng
        );
    }

    // ─────────────────────────────────────────────────────────
    // SUCCESS
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableSuccess() {

        REAPP_PropertyTriggerHandler.bypassBatch = true;

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Property__c prop = makeProperty(
            'Chennai',
            null,
            null
        );

        insert prop;

        Test.startTest();

        System.enqueueJob(
            new REAPP_GeocodeQueueable(
                new List<Id>{ prop.Id }
            )
        );

        Test.stopTest();

        Property__c updated = [

            SELECT
                Location__Latitude__s,
                Location__Longitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertEquals(
            13.0836939,
            updated.Location__Latitude__s
        );

        System.assertEquals(
            80.2701860,
            updated.Location__Longitude__s
        );
    }

    // ─────────────────────────────────────────────────────────
    // EMPTY IDS
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableEmptyIds() {

        Test.startTest();

        System.enqueueJob(
            new REAPP_GeocodeQueueable(
                new List<Id>()
            )
        );

        Test.stopTest();

        System.assert(true);
    }

    // ─────────────────────────────────────────────────────────
    // RECORD NOT FOUND
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableDeletedRecord() {

        REAPP_PropertyTriggerHandler.bypassBatch = true;

        Property__c prop = makeProperty(
            'Karur',
            null,
            null
        );

        insert prop;

        Id propId = prop.Id;

        delete prop;

        Test.startTest();

        System.enqueueJob(
            new REAPP_GeocodeQueueable(
                new List<Id>{ propId }
            )
        );

        Test.stopTest();

        System.assert(true);
    }

    // ─────────────────────────────────────────────────────────
    // BLANK ADDRESS
    // ─────────────────────────────────────────────────────────

   

    // ─────────────────────────────────────────────────────────
    // ALREADY GEOCODED
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableAlreadyGeocoded() {

        REAPP_PropertyTriggerHandler.bypassBatch = true;

        Property__c prop = makeProperty(
            'Chennai',
            13.08,
            80.27
        );

        insert prop;

        Test.startTest();

        System.enqueueJob(
            new REAPP_GeocodeQueueable(
                new List<Id>{ prop.Id }
            )
        );

        Test.stopTest();

        Property__c result = [

            SELECT
                Location__Latitude__s,
                Location__Longitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertEquals(
            13.08,
            result.Location__Latitude__s
        );

        System.assertEquals(
            80.27,
            result.Location__Longitude__s
        );
    }

    // ─────────────────────────────────────────────────────────
    // EMPTY RESPONSE
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableEmptyResponse() {

        REAPP_PropertyTriggerHandler.bypassBatch = true;

        Test.setMock(
            HttpCalloutMock.class,
            new EmptyMock()
        );

        Property__c prop = makeProperty(
            'Unknown',
            null,
            null
        );

        insert prop;

        Test.startTest();

        System.enqueueJob(
            new REAPP_GeocodeQueueable(
                new List<Id>{ prop.Id }
            )
        );

        Test.stopTest();

        Property__c result = [

            SELECT Location__Latitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertEquals(
            null,
            result.Location__Latitude__s
        );
    }

    // ─────────────────────────────────────────────────────────
    // RATE LIMIT
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableRateLimit() {

        REAPP_PropertyTriggerHandler.bypassBatch = true;

        Test.setMock(
            HttpCalloutMock.class,
            new RateLimitMock()
        );

        Property__c prop = makeProperty(
            'Chennai',
            null,
            null
        );

        insert prop;

        Test.startTest();

        System.enqueueJob(
            new REAPP_GeocodeQueueable(
                new List<Id>{ prop.Id }
            )
        );

        Test.stopTest();

        Property__c result = [

            SELECT Location__Latitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertEquals(
            null,
            result.Location__Latitude__s
        );
    }

    // ─────────────────────────────────────────────────────────
    // EXCEPTION PATH
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testQueueableExceptionPath() {

        REAPP_PropertyTriggerHandler.bypassBatch = true;

        Test.setMock(
            HttpCalloutMock.class,
            new ErrorMock()
        );

        Property__c prop = makeProperty(
            'Chennai',
            null,
            null
        );

        insert prop;

        Test.startTest();

        System.enqueueJob(
            new REAPP_GeocodeQueueable(
                new List<Id>{ prop.Id }
            )
        );

        Test.stopTest();

        System.assert(true);
    }
}