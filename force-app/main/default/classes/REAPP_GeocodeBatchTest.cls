@IsTest
private class REAPP_GeocodeBatchTest {

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

    private class ServerErrorMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('');

            return res;
        }
    }

    // ─────────────────────────────────────────────────────────
    // TEST DATA
    // ─────────────────────────────────────────────────────────

    private static Property__c makeProperty(
        String city,
        String state,
        String postal,
        String country,
        Decimal lat,
        Decimal lng
    ) {

        return new Property__c(
            Name = 'Test Property ' + city + Math.random(),

            Address__c = '123 Test Street',
            City__c = city,
            State__c = state,
            Postal_Code__c = postal,
            Country__c = country,

            Rent__c = 10000,
            Status__c = 'Available',
            Type__c = 'Residential',
            Furnishing_Status__c = 'Unfurnished',
            Description__c = 'Test Property',

            Location__Latitude__s = lat,
            Location__Longitude__s = lng
        );
    }

    // ─────────────────────────────────────────────────────────
    // SUCCESS TEST
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testBatchGeocodeSuccess() {

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Property__c prop = makeProperty(
            'Chennai',
            'Tamil Nadu',
            '600047',
            'India',
            null,
            null
        );

        Test.startTest();

        insert prop;

        Test.stopTest();

        Property__c updated = [
            SELECT
                Location__Latitude__s,
                Location__Longitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertNotEquals(
            null,
            updated.Location__Latitude__s
        );

        System.assertNotEquals(
            null,
            updated.Location__Longitude__s
        );

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
    // TARGET IDS COVERAGE
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testBatchWithTargetIdsCoverage() {

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Property__c prop = makeProperty(
            'Karur',
            'Tamil Nadu',
            '639004',
            'India',
            null,
            null
        );

        Test.startTest();

        insert prop;

        Test.stopTest();

        Property__c updated = [
            SELECT Location__Latitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertNotEquals(
            null,
            updated.Location__Latitude__s
        );
    }

    // ─────────────────────────────────────────────────────────
    // ALREADY GEOCODED
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testBatchSkipsAlreadyGeocoded() {

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Property__c prop = makeProperty(
            'Chennai',
            'Tamil Nadu',
            '600047',
            'India',
            13.08,
            80.27
        );

        Test.startTest();

        insert prop;

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
    static void testBatchHandlesEmptyResult() {

        Test.setMock(HttpCalloutMock.class, new EmptyMock());

        Property__c prop = makeProperty(
            'Nowhere',
            'Tamil Nadu',
            '000000',
            'India',
            null,
            null
        );

        Test.startTest();

        insert prop;

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
    static void testBatchHandlesRateLimit() {

        Test.setMock(HttpCalloutMock.class, new RateLimitMock());

        Property__c prop = makeProperty(
            'Chennai',
            'Tamil Nadu',
            '600047',
            'India',
            null,
            null
        );

        Test.startTest();

        insert prop;

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
    // SERVER ERROR
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testBatchHandlesServerError() {

        Test.setMock(HttpCalloutMock.class, new ServerErrorMock());

        Property__c prop = makeProperty(
            'Chennai',
            'Tamil Nadu',
            '600047',
            'India',
            null,
            null
        );

        Test.startTest();

        insert prop;

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


}