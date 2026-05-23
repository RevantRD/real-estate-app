public with sharing class REAPP_MaintenanceRequestHandler {
    public static void assignVendors(List<Maintenance_Request__c> newRequests) {
        if (newRequests.isEmpty()) return;

        // Query vendors with their active requests
        List<Vendor__c> vendors = [
            SELECT Id,
                   (SELECT Id FROM Maintenance_Requests__r WHERE Status__c IN ('Open','In Progress'))
            FROM Vendor__c
        ];

        if (vendors.isEmpty()) return;

        for (Maintenance_Request__c req : newRequests) {
            Vendor__c leastBusy = null;
            Integer minCount = null;

            for (Vendor__c v : vendors) {
                Integer workload = v.Maintenance_Requests__r.size();

                if (minCount == null || workload < minCount) {
                    minCount = workload;
                    leastBusy = v;
                }
            }

            if (leastBusy != null) {
                req.Vendor__c = leastBusy.Id;
            }
        }
    }
}