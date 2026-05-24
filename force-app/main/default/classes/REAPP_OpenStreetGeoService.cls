public class REAPP_OpenStreetGeoService {

    public class GeoResult {
        @AuraEnabled public Decimal lat;
        @AuraEnabled public Decimal lng;
        public Boolean rateLimited = false;
    }

    public static GeoResult geocode(String address) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'https://nominatim.openstreetmap.org/search?format=json&limit=1&q=' +
            EncodingUtil.urlEncode(address, 'UTF-8')
        );
        req.setMethod('GET');
        req.setHeader('User-Agent', 'REAPPSalesforceApp/1.0');
        req.setTimeout(10000);

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
            if (!results.isEmpty()) {
                Map<String, Object> first = (Map<String, Object>) results[0];
                GeoResult geo = new GeoResult();
                geo.lat = Decimal.valueOf((String) first.get('lat'));
                geo.lng = Decimal.valueOf((String) first.get('lon'));
                return geo;
            }
            return null;
        } else if (res.getStatusCode() == 429) {
            System.debug('Nominatim rate limit exceeded — will retry.');
            GeoResult r = new GeoResult();
            r.rateLimited = true;
            return r;
        }

        System.debug('Geocode HTTP error: ' + res.getStatusCode() + ' ' + res.getStatus());
        return null;
    }
}