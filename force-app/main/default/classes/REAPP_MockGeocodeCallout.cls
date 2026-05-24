@IsTest
global class REAPP_MockGeocodeCallout implements HttpCalloutMock {

    public static final Integer SUCCESS      = 1;
    public static final Integer EMPTY        = 2;
    public static final Integer RATE_LIMITED = 3;
    public static final Integer SERVER_ERROR = 4;

    private Integer responseType;

    global REAPP_MockGeocodeCallout(Integer responseType) {
        this.responseType = responseType;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        if (responseType == SUCCESS) {
            res.setStatusCode(200);
            res.setBody('[{"lat":"13.0836939","lon":"80.2701860","display_name":"Chennai, Tamil Nadu, India"}]');

        } else if (responseType == EMPTY) {
            res.setStatusCode(200);
            res.setBody('[]');

        } else if (responseType == RATE_LIMITED) {
            res.setStatusCode(429);
            res.setStatus('Too Many Requests');
            res.setBody('');

        } else if (responseType == SERVER_ERROR) {
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('');
        }

        return res;
    }
}