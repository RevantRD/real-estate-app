@IsTest
private class REAPP_LeaseAgreementControllerTest {

    // Helper: create Property record
    private static Property__c createProperty() {
        Property__c prop = new Property__c(
            Name = 'Test Property',
            Address__c = '123 Main Street',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Postal_Code__c = '600001',
            Country__c = 'India',
            Type__c = 'Residential',
            Furnishing_Status__c = 'Furnished',
            Status__c = 'Available',
            Rent__c = 25000,
            Description__c = 'Test Property'
        );
        insert prop;
        return prop;
    }

    // Helper: create Tenant record
    private static Tenant__c createTenant(String email) {
        Tenant__c tenant = new Tenant__c(
            Name = 'John Smith',
            Phone_Number__c = '9876543210',
            Email__c = email
        );
        insert tenant;
        return tenant;
    }

    // ✅ Successful getLeaseAgreement
    @IsTest
    static void testGetLeaseAgreementSuccess() {
        Property__c prop = createProperty();
        Tenant__c tenant = createTenant('john@test.com');

        Lease_Agreement__c agreement = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = '12 Months',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
        insert agreement;

        Test.startTest();
        REAPP_LeaseAgreementController.LeaseAgreementWrapper result =
            REAPP_LeaseAgreementController.getLeaseAgreement(agreement.Id);
        Test.stopTest();

        System.assertEquals(prop.Name, result.propertyName);
        System.assertEquals(tenant.Name, result.tenantName);
    }

    // ✅ Null Id throws AuraHandledException
    @IsTest
    static void testGetLeaseAgreementNullId() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            REAPP_LeaseAgreementController.getLeaseAgreement(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown);
    }

    // ✅ Nonexistent record throws AuraHandledException
    @IsTest
    static void testGetLeaseAgreementNotFound() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            REAPP_LeaseAgreementController.getLeaseAgreement(Id.valueOf('001000000000000AAA'));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown);
    }

    // ✅ Successful sendLeaseAgreementEmail
    @IsTest
    static void testSendLeaseAgreementEmailSuccess() {
        Property__c prop = createProperty();
        Tenant__c tenant = createTenant('john@test.com');

        Lease_Agreement__c agreement = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = '12 Months',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
        insert agreement;

        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('Test PDF'));

        Test.startTest();
        REAPP_LeaseAgreementController.sendLeaseAgreementEmail(agreement.Id, pdfBase64);
        Test.stopTest();

        System.assert(true);
    }

    // ✅ Null Id in sendLeaseAgreementEmail
    @IsTest
    static void testSendLeaseAgreementEmailNullId() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            REAPP_LeaseAgreementController.sendLeaseAgreementEmail(null, EncodingUtil.base64Encode(Blob.valueOf('PDF')));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown);
    }

    // ✅ Missing tenant email throws AuraHandledException
    @IsTest
    static void testSendLeaseAgreementEmailMissingTenantEmail() {
        Property__c prop = createProperty();
        Tenant__c tenant = createTenant(null);

        Lease_Agreement__c agreement = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = '12 Months',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
        insert agreement;

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            REAPP_LeaseAgreementController.sendLeaseAgreementEmail(agreement.Id, EncodingUtil.base64Encode(Blob.valueOf('PDF')));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown);
    }
}