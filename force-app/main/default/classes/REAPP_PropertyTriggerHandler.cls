public class REAPP_PropertyTriggerHandler {
    private static Boolean hasRun = false;

    public static void afterInsertOrUpdate(List<Property__c> newRecords, Map<Id, Property__c> oldMap) {
        if (hasRun) return;
        hasRun = true;

        List<Id> propertyIds = new List<Id>();

        for (Property__c p : newRecords) {
            // Only enqueue if address exists AND coordinates are not already set
            if (p.Address__c != null && (p.Location__Latitude__s == null || p.Location__Longitude__s == null)) {
                if (oldMap != null) {
                    Property__c oldRec = oldMap.get(p.Id);
                    // Skip if only lat/lon changed (to avoid recursion)
                    Boolean latChanged = oldRec != null && p.Location__Latitude__s != oldRec.Location__Latitude__s;
                    Boolean lonChanged = oldRec != null && p.Location__Longitude__s != oldRec.Location__Longitude__s;
                    if (latChanged || lonChanged) {
                        continue;
                    }
                }
                propertyIds.add(p.Id);
            }
        }

        if (!propertyIds.isEmpty()) {
            System.enqueueJob(new REAPP_GeocodeQueueable(propertyIds));
        }
    }
}