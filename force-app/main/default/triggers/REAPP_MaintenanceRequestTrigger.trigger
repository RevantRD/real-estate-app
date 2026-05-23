trigger REAPP_MaintenanceRequestTrigger on Maintenance_Request__c(before insert) {
	// Your trigger logic here
    if (Trigger.isBefore && Trigger.isInsert) {
        REAPP_MaintenanceRequestHandler.assignVendors(Trigger.new);
    }
}