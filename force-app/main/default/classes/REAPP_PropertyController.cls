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

        if (String.isNotBlank(statusFilter)) {
            baseQuery += ' AND Status__c = \'' + String.escapeSingleQuotes(statusFilter) + '\'';
        }
        if (String.isNotBlank(furnishingFilter)) {
            baseQuery += ' AND Furnishing_Status__c = \'' + String.escapeSingleQuotes(furnishingFilter) + '\'';
        }
        if (maxPrice != null) {
            baseQuery += ' AND Rent__c <= ' + maxPrice;
        }
        if (userLatitude != null && userLongitude != null && distanceKm != null) {
            baseQuery += ' AND DISTANCE(Location__c, GEOLOCATION(' +
                userLatitude + ',' + userLongitude + '), \'km\') < ' + distanceKm;
        }

        Integer totalRecords = Database.countQuery('SELECT COUNT() ' + baseQuery);

        String query =
            'SELECT Id, Name, City__c, State__c, Rent__c, Status__c, Furnishing_Status__c, Type__c, Country__c, Postal_Code__c'
            + baseQuery
            + ' ORDER BY CreatedDate DESC'
            + ' LIMIT ' + pageSize
            + ' OFFSET ' + offsetValue;

        return new PropertyResponse(Database.query(query), totalRecords);
    }

    // =========================================================
    // CREATE PROPERTY
    // Geocoding is intentionally left to the trigger + batch.
    // Doing a callout here would violate Salesforce's rule:
    // "cannot make a callout after a DML operation in the same transaction."
    // =========================================================
    @AuraEnabled
    public static Id createPropertyWithImage(Property__c propertyRecord, List<String> documentIds) {

        insert propertyRecord;

        if (documentIds != null && !documentIds.isEmpty()) {
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (String docId : documentIds) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId    = propertyRecord.Id,
                    ShareType         = 'V'
                ));
            }
            insert links;
        }

        return propertyRecord.Id;
    }
}