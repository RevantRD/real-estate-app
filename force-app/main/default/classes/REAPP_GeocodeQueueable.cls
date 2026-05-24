public class REAPP_GeocodeQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> propertyIds;
    private Integer batchSize = 1; // Nominatim allows 1 req/sec; process 1 per job run

    public REAPP_GeocodeQueueable(List<Id> propertyIds) {
        this.propertyIds = propertyIds;
    }

    public void execute(QueueableContext context) {
        if (propertyIds == null || propertyIds.isEmpty()) {
            return;
        }

        // Always take just the first ID — one callout per queueable run
        // so we stay within Nominatim's 1 req/sec policy
        Id currentId = propertyIds[0];

        List<Property__c> properties = [
            SELECT Id, Address__c, City__c, State__c, Postal_Code__c, Country__c,
                   Location__Latitude__s, Location__Longitude__s
            FROM Property__c
            WHERE Id = :currentId
        ];

        if (properties.isEmpty()) {
            // Record gone — skip and move on
            chainNext(false);
            return;
        }

        Property__c p = properties[0];

        // Skip if no address or already geocoded
        if (String.isBlank(p.Address__c)) {
            System.debug('Skipping ' + p.Id + ': blank address.');
            chainNext(false);
            return;
        }
        if (p.Location__Latitude__s != null && p.Location__Longitude__s != null) {
            System.debug('Skipping ' + p.Id + ': already geocoded.');
            chainNext(false);
            return;
        }

        // Build address string, filtering out blank parts
        List<String> parts = new List<String>();
       // if (!String.isBlank(p.Address__c))   parts.add(p.Address__c.trim());
        if (!String.isBlank(p.City__c))      parts.add(p.City__c.trim());
        if (!String.isBlank(p.State__c))     parts.add(p.State__c.trim());
        if (!String.isBlank(p.Postal_Code__c)) parts.add(p.Postal_Code__c.trim());
        if (!String.isBlank(p.Country__c))   parts.add(p.Country__c.trim());
        String fullAddress = String.join(parts, ', ');

        try {
            REAPP_OpenStreetGeoService.GeoResult geo =
                REAPP_OpenStreetGeoService.geocode(fullAddress);

            if (geo == null) {
                // No results found for address — skip and move on
                System.debug('No geocode result for ' + p.Id + ': ' + fullAddress);
                chainNext(false);
                return;
            }

            if (geo.rateLimited) {
                // Re-enqueue the SAME list so this record is retried next run
                System.debug('Rate limited — re-enqueuing same batch for retry.');
                System.enqueueJob(new REAPP_GeocodeQueueable(propertyIds));
                return;
            }

            if (geo.lat != null && geo.lng != null) {
                update new Property__c(
                    Id = p.Id,
                    Location__Latitude__s = geo.lat,
                    Location__Longitude__s = geo.lng
                );
                System.debug('Geocoded ' + p.Id + ' → ' + geo.lat + ', ' + geo.lng);
            }

        } catch (Exception e) {
            System.debug('Geocode failed for ' + p.Id + ': ' + e.getMessage());
        }

        // Move to the next record
        chainNext(false);
    }

    /**
     * Enqueues the next job for the remaining property IDs.
     * @param retryCurrent  if true, keeps the current first ID in the list (for retry)
     */
    private void chainNext(Boolean retryCurrent) {
        // Build the remaining list (drop index 0 since it was just processed)
        List<Id> remaining = new List<Id>();
        Integer startIndex = retryCurrent ? 0 : 1;
        for (Integer i = startIndex; i < propertyIds.size(); i++) {
            remaining.add(propertyIds[i]);
        }
        if (!remaining.isEmpty()) {
            System.enqueueJob(new REAPP_GeocodeQueueable(remaining));
        }
    }
}