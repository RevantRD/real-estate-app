trigger REAPP_MaintenanceRequestTrigger on Maintenance_Request__c(before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        REAPP_MaintenanceRequestHandler.assignVendors(Trigger.new);
    }
}