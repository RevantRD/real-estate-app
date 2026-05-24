public class REAPP_PropertyTriggerHandler {

    private static Boolean hasRun = false;

    // ADD THIS
    public static Boolean bypassBatch = false;

    public static void afterInsertOrUpdate(
        List<Property__c> newRecords,
        Map<Id, Property__c> oldMap
    ) {

        if (hasRun) return;
        hasRun = true;

        List<Id> propertyIds = new List<Id>();

        for (Property__c p : newRecords) {

            if (String.isBlank(p.Address__c)) continue;

            if (
                p.Location__Latitude__s != null &&
                p.Location__Longitude__s != null
            ) {
                continue;
            }

            propertyIds.add(p.Id);
        }

        // UPDATED CONDITION
        if (
            !propertyIds.isEmpty() &&
            !bypassBatch
        ) {
            Database.executeBatch(
                new REAPP_GeocodeBatch(propertyIds),
                1
            );
        }
    }
}