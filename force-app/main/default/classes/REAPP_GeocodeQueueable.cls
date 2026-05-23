public class REAPP_GeocodeQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> propertyIds;

    public REAPP_GeocodeQueueable(List<Id> propertyIds) {
        this.propertyIds = new Set<Id>(propertyIds);
    }

    public void execute(QueueableContext context) {
        List<Property__c> properties = [
            SELECT Id, Address__c, City__c, State__c, Postal_Code__c, Country__c
            FROM Property__c
            WHERE Id IN :propertyIds
        ];

        List<Property__c> updates = new List<Property__c>();

        for (Property__c p : properties) {
            if (String.isBlank(p.Address__c)) continue;

            // Simplified address for Nominatim
            String fullAddress = String.join(new List<String>{
                p.City__c,
                p.State__c,
                p.Postal_Code__c,
                p.Country__c
            }, ', ');

            REAPP_OpenStreetGeoService.GeoResult geo =
                REAPP_OpenStreetGeoService.geocode(fullAddress);

            if (geo != null && geo.lat != null && geo.lng != null) {
                updates.add(new Property__c(
                    Id = p.Id,
                    Location__Latitude__s = geo.lat,
                    Location__Longitude__s = geo.lng
                ));
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}