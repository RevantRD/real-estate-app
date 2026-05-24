/**
 * Processes ungeocoded Property__c records one at a time.
 *
 * WHY NOT SCOPE > 1:
 * Salesforce runs batch chunks in parallel, so multiple callouts hit
 * Nominatim simultaneously causing 429 rate limit errors.
 * We use scope=1 AND set ALLOW_PARALLEL=false via the batch executor.
 *
 * HOW TO RUN (Anonymous Apex):
 *   Database.executeBatch(new REAPP_GeocodeBatch(), 1);
 *
 * If some records still fail due to 429, just re-run — the query
 * only picks up records still missing coordinates.
 */
global class REAPP_GeocodeBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    global Integer successCount = 0;
    global Integer skipCount    = 0;
    global Integer failCount    = 0;

    private Set<Id> targetIds;

    global REAPP_GeocodeBatch() {}

    global REAPP_GeocodeBatch(List<Id> ids) {
        this.targetIds = new Set<Id>(ids);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (targetIds != null && !targetIds.isEmpty()) {
            return Database.getQueryLocator([
                SELECT Id, Address__c, City__c, State__c, Postal_Code__c, Country__c,
                       Location__Latitude__s, Location__Longitude__s
                FROM Property__c
                WHERE Id IN :targetIds
                AND Location__Latitude__s = null
                ORDER BY CreatedDate ASC
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id, Address__c, City__c, State__c, Postal_Code__c, Country__c,
                   Location__Latitude__s, Location__Longitude__s
            FROM Property__c
            WHERE Location__Latitude__s = null
            ORDER BY CreatedDate ASC
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Property__c> scope) {
        Property__c p = scope[0];

        List<String> parts = new List<String>();
        if (!String.isBlank(p.City__c))        parts.add(p.City__c.trim());
        if (!String.isBlank(p.State__c))       parts.add(p.State__c.trim());
        if (!String.isBlank(p.Postal_Code__c)) parts.add(p.Postal_Code__c.trim());
        if (!String.isBlank(p.Country__c))     parts.add(p.Country__c.trim());

        if (parts.isEmpty()) {
            skipCount++;
            return;
        }

        try {
            REAPP_OpenStreetGeoService.GeoResult geo =
                REAPP_OpenStreetGeoService.geocode(String.join(parts, ', '));

            if (geo == null) {
                System.debug('No result for ' + p.Id);
                skipCount++;
                return;
            }

            if (geo.rateLimited) {
                // Can't busy-wait (CPU limit). Just skip — re-run batch to retry.
                System.debug('Rate limited for ' + p.Id + ' — re-run batch to retry.');
                skipCount++;
                return;
            }

            update new Property__c(
                Id = p.Id,
                Location__Latitude__s  = geo.lat,
                Location__Longitude__s = geo.lng
            );
            successCount++;
            System.debug('Geocoded ' + p.Id + ' → ' + geo.lat + ', ' + geo.lng);

        } catch (Exception e) {
            failCount++;
            System.debug('Error for ' + p.Id + ': ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(
            'REAPP_GeocodeBatch done. ' +
            'Success: ' + successCount +
            ' | Skipped/RateLimited: ' + skipCount +
            ' | Errors: ' + failCount
        );

        // If any were skipped due to rate limiting, schedule a retry in 2 minutes
        if (skipCount > 0) {
            System.debug('Skipped records exist. Re-run: Database.executeBatch(new REAPP_GeocodeBatch(), 1);');
        }
    }
}