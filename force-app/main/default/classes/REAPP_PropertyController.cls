public with sharing class REAPP_PropertyController {

    public class PropertyResponse {

        @AuraEnabled public List<Property__c> properties;
        @AuraEnabled public Integer totalRecords;

        public PropertyResponse(List<Property__c> properties, Integer totalRecords) {
            this.properties = properties;
            this.totalRecords = totalRecords;
        }
    }

    @AuraEnabled(cacheable=true)
    public static PropertyResponse getProperties(
        Integer pageSize,
        Integer pageNumber,
        String statusFilter,
        String furnishingFilter,
        Decimal maxPrice,
        Decimal userLatitude,
        Decimal userLongitude,
        Decimal distanceKm
    ) {

        Integer offsetValue = (pageNumber - 1) * pageSize;

        String baseQuery = ' FROM Property__c WHERE Id != null';

        // -------------------------
        // STATUS FILTER
        // -------------------------
        if (String.isNotBlank(statusFilter)) {
            baseQuery += ' AND Status__c = \'' +
                String.escapeSingleQuotes(statusFilter) + '\'';
        }

        // -------------------------
        // FURNISHING FILTER
        // -------------------------
        if (String.isNotBlank(furnishingFilter)) {
            baseQuery += ' AND Furnishing_Status__c = \'' +
                String.escapeSingleQuotes(furnishingFilter) + '\'';
        }

        // -------------------------
        // PRICE FILTER
        // -------------------------
        if (maxPrice != null) {
            baseQuery += ' AND Rent__c <= ' + maxPrice;
        }

        // -------------------------
        // DISTANCE FILTER
        // -------------------------
        // NOTE: Requires Location__c = Geolocation field
        if (userLatitude != null &&
            userLongitude != null &&
            distanceKm != null) {

            baseQuery += ' AND DISTANCE(Location__c, GEOLOCATION(' +
                userLatitude + ',' +
                userLongitude +
                '), \'km\') < ' + distanceKm;
        }

        // -------------------------
        // COUNT QUERY
        // -------------------------
        Integer totalRecords = Database.countQuery(
            'SELECT COUNT() ' + baseQuery
        );

        // -------------------------
        // MAIN QUERY
        // -------------------------
        String query =
            'SELECT Id, Name, City__c, State__c, Rent__c, Status__c, Furnishing_Status__c'
            + baseQuery +
            ' ORDER BY CreatedDate DESC' +
            ' LIMIT ' + pageSize +
            ' OFFSET ' + offsetValue;

        List<Property__c> properties = Database.query(query);

        return new PropertyResponse(properties, totalRecords);
    }

    // =====================================================
    // CREATE PROPERTY
    // =====================================================

    @AuraEnabled
    public static Id createPropertyWithImage(Property__c propertyRecord, List<String> documentIds) {

    // 1. Build full address
    String fullAddress =
        propertyRecord.Address__c + ' ' +
        propertyRecord.City__c + ' ' +
        propertyRecord.State__c + ' ' +
        propertyRecord.Postal_Code__c + ' ' +
        propertyRecord.Country__c;

    // 2. Geocode
    REAPP_OpenStreetGeoService.GeoResult geo =
        REAPP_OpenStreetGeoService.geocode(fullAddress);

    // 3. Set location
    if (geo != null) {
        propertyRecord.Location__Latitude__s = geo.lat;
        propertyRecord.Location__Longitude__s = geo.lng;
    }

    // 4. Insert property
    insert propertyRecord;

    // 5. Attach files (existing logic assumed)
    if (documentIds != null && !documentIds.isEmpty()) {
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();

        for (String docId : documentIds) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = docId,
                LinkedEntityId = propertyRecord.Id,
                ShareType = 'V'
            ));
        }

        insert links;
    }

    return propertyRecord.Id;
}
}