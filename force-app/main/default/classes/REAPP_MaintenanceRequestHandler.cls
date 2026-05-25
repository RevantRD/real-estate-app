/**
 * @description Trigger handler for Maintenance_Request__c object
 * @author Real Estate App Team
 */
public with sharing class REAPP_MaintenanceRequestHandler {
    
    /**
     * @description Assigns vendors to maintenance requests using workload balancing
     * @param newRequests List of new Maintenance Request records
     */
    public static void assignVendors(List<Maintenance_Request__c> newRequests) {
        try {
            // Validate input
            if (newRequests == null || newRequests.isEmpty()) {
                return;
            }

            // Query vendors with their active requests
            List<Vendor__c> vendors = [
                SELECT Id, Name,
                       (SELECT Id FROM Maintenance_Requests__r WHERE Status__c IN ('Open','In Progress'))
                FROM Vendor__c
            ];

            if (vendors.isEmpty()) {
                System.debug('No vendors available for assignment');
                return;
            }

            // Create a map to track current workload for each vendor (including new assignments)
            Map<Id, Integer> vendorWorkloadMap = new Map<Id, Integer>();
            
            // Initialize workload map with existing active requests
            for (Vendor__c v : vendors) {
                Integer workload = (v.Maintenance_Requests__r != null) ? v.Maintenance_Requests__r.size() : 0;
                vendorWorkloadMap.put(v.Id, workload);
            }

            // Assign vendor with least workload to each request
            for (Maintenance_Request__c req : newRequests) {
                // Skip if vendor is already assigned
                if (req.Vendor__c != null) {
                    continue;
                }
                
                Id leastBusyVendorId = null;
                Integer minWorkload = null;

                // Find vendor with absolute minimum current workload
                for (Id vendorId : vendorWorkloadMap.keySet()) {
                    Integer currentWorkload = vendorWorkloadMap.get(vendorId);

                    if (minWorkload == null || currentWorkload < minWorkload) {
                        minWorkload = currentWorkload;
                        leastBusyVendorId = vendorId;
                    }
                }

                // Assign the vendor and update workload count
                if (leastBusyVendorId != null) {
                    req.Vendor__c = leastBusyVendorId;
                    
                    // Increment workload for this vendor for the next iteration
                    vendorWorkloadMap.put(leastBusyVendorId, vendorWorkloadMap.get(leastBusyVendorId) + 1);
                    
                    System.debug('Assigned Vendor ' + leastBusyVendorId + ' with workload: ' + minWorkload + ' to request');
                }
            }

        }  catch (Exception e) {
            System.debug('Error in assignVendors: ' + e.getMessage());
            throw e;
        }
    }
}