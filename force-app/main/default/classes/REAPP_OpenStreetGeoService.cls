public class REAPP_OpenStreetGeoService {

    public class GeoResult {
        @AuraEnabled public Decimal lat;
        @AuraEnabled public Decimal lng;
    }

    public static GeoResult geocode(String address) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'https://nominatim.openstreetmap.org/search?format=json&q=' +
            EncodingUtil.urlEncode(address, 'UTF-8')
        );
        req.setMethod('GET');
        req.setHeader('User-Agent', 'Salesforce-App');

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
        } else if (res.getStatusCode() == 429) {
            // Rate limit hit — skip gracefully
            System.debug('Nominatim rate limit exceeded, skipping this run.');
            return null;
        }

        return null;
    }
}