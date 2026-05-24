@IsTest
private class REAPP_OpenStreetGeoServiceTest {

    // ─────────────────────────────────────────────────────────
    // SUCCESS MOCK
    // ─────────────────────────────────────────────────────────
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            res.setStatusCode(200);
            res.setBody(
                '[{"lat":"13.0836939","lon":"80.2701860","display_name":"Chennai, Tamil Nadu, India"}]'
            );

            return res;
        }
    }

    // ─────────────────────────────────────────────────────────
    // EMPTY MOCK
    // ─────────────────────────────────────────────────────────
    private class EmptyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            res.setStatusCode(200);
            res.setBody('[]');

            return res;
        }
    }

    // ─────────────────────────────────────────────────────────
    // RATE LIMIT MOCK
    // ─────────────────────────────────────────────────────────
    private class RateLimitMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            res.setStatusCode(429);
            res.setStatus('Too Many Requests');
            res.setBody('');

            return res;
        }
    }

    // ─────────────────────────────────────────────────────────
    // SERVER ERROR MOCK
    // ─────────────────────────────────────────────────────────
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
    // TEST SUCCESS
    // ─────────────────────────────────────────────────────────
    @IsTest
    static void testGeocodeSuccess() {

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();

        REAPP_OpenStreetGeoService.GeoResult result =
            REAPP_OpenStreetGeoService.geocode(
                'Chennai, Tamil Nadu, 600047, India'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(false, result.rateLimited);
        System.assertEquals(13.0836939, result.lat);
        System.assertEquals(80.2701860, result.lng);
    }

    // ─────────────────────────────────────────────────────────
    // TEST EMPTY RESPONSE
    // ─────────────────────────────────────────────────────────
    @IsTest
    static void testGeocodeEmptyResult() {

        Test.setMock(HttpCalloutMock.class, new EmptyMock());

        Test.startTest();

        REAPP_OpenStreetGeoService.GeoResult result =
            REAPP_OpenStreetGeoService.geocode('Unknown Place XYZ');

        Test.stopTest();

        System.assertEquals(null, result);
    }

    // ─────────────────────────────────────────────────────────
    // TEST RATE LIMIT
    // ─────────────────────────────────────────────────────────
    @IsTest
    static void testGeocodeRateLimited() {

        Test.setMock(HttpCalloutMock.class, new RateLimitMock());

        Test.startTest();

        REAPP_OpenStreetGeoService.GeoResult result =
            REAPP_OpenStreetGeoService.geocode(
                'Chennai, Tamil Nadu, India'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, result.rateLimited);
        System.assertEquals(null, result.lat);
        System.assertEquals(null, result.lng);
    }

    // ─────────────────────────────────────────────────────────
    // TEST SERVER ERROR
    // ─────────────────────────────────────────────────────────
    @IsTest
    static void testGeocodeServerError() {

        Test.setMock(HttpCalloutMock.class, new ServerErrorMock());

        Test.startTest();

        REAPP_OpenStreetGeoService.GeoResult result =
            REAPP_OpenStreetGeoService.geocode(
                'Chennai, Tamil Nadu, India'
            );

        Test.stopTest();

        System.assertEquals(null, result);
    }

    // ─────────────────────────────────────────────────────────
    // TEST DEFAULT VALUES
    // ─────────────────────────────────────────────────────────
    @IsTest
    static void testGeoResultDefaults() {

        REAPP_OpenStreetGeoService.GeoResult geo =
            new REAPP_OpenStreetGeoService.GeoResult();

        System.assertEquals(false, geo.rateLimited);
        System.assertEquals(null, geo.lat);
        System.assertEquals(null, geo.lng);
    }
}