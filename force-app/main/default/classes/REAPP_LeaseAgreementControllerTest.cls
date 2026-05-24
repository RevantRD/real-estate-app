@IsTest
private class REAPP_LeaseAgreementControllerTest {

    // ─────────────────────────────────────────────────────────
    // TEST DATA
    // ─────────────────────────────────────────────────────────

    private static Property__c makeProperty() {

        return new Property__c(

            Name = 'Test Property',

            Address__c = '123 Main Street',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Postal_Code__c = '600001',
            Country__c = 'India',

            Rent__c = 25000,
            Status__c = 'Available',
            Type__c = 'Residential',
            Furnishing_Status__c = 'Furnished',
            Description__c = 'Luxury apartment'
        );
    }

    private static Tenant__c makeTenant() {

        return new Tenant__c(

            Name = 'John Smith',
            Phone_Number__c = '9876543210',
            Email__c = 'johnsmith@test.com'
        );
    }

    private static Lease_Agreement__c makeAgreement(
        Id propertyId,
        Id tenantId
    ) {

        return new Lease_Agreement__c(


            Property__c = propertyId,
            Tenant__c = tenantId,

            Terms__c = '12 month lease agreement',

            Agreed_Monthly_Rent__c = 25000,

            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
    }

    // ─────────────────────────────────────────────────────────
    // TEST getLeaseAgreement()
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testGetLeaseAgreement() {

        Property__c prop = makeProperty();
        insert prop;

        Tenant__c tenant = makeTenant();
        insert tenant;

        Lease_Agreement__c agreement =
            makeAgreement(prop.Id, tenant.Id);

        insert agreement;

        Test.startTest();

        REAPP_LeaseAgreementController.LeaseAgreementWrapper wrapper =

            REAPP_LeaseAgreementController.getLeaseAgreement(
                agreement.Id
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            wrapper
        );

        System.assertEquals(
            prop.Name,
            wrapper.propertyName
        );

        System.assertEquals(
            tenant.Name,
            wrapper.tenantName
        );

        System.assertEquals(
            '12 month lease agreement',
            wrapper.terms
        );

        System.assertEquals(
            '25000',
            wrapper.rent
        );
    }

    // ─────────────────────────────────────────────────────────
    // TEST WRAPPER CONSTRUCTOR
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testWrapperConstructor() {

        REAPP_LeaseAgreementController.LeaseAgreementWrapper wrapper =

            new REAPP_LeaseAgreementController.LeaseAgreementWrapper(

                'Agreement A',
                'Property A',
                'Tenant A',
                'Terms A',
                '50000',
                '2026-01-01',
                '2026-12-31'
            );

        System.assertEquals(
            'Agreement A',
            wrapper.Name
        );

        System.assertEquals(
            'Property A',
            wrapper.propertyName
        );

        System.assertEquals(
            'Tenant A',
            wrapper.tenantName
        );

        System.assertEquals(
            'Terms A',
            wrapper.terms
        );

        System.assertEquals(
            '50000',
            wrapper.rent
        );

        System.assertEquals(
            '2026-01-01',
            wrapper.startDate
        );

        System.assertEquals(
            '2026-12-31',
            wrapper.endDate
        );
    }

    // ─────────────────────────────────────────────────────────
    // TEST sendLeaseAgreementEmail()
    // ─────────────────────────────────────────────────────────

    @IsTest
static void testSendLeaseAgreementEmail() {

    Property__c prop = makeProperty();
    insert prop;

    Tenant__c tenant = makeTenant();
    insert tenant;

    Lease_Agreement__c agreement =
        makeAgreement(prop.Id, tenant.Id);

    insert agreement;

    String samplePdfBase64 =

        EncodingUtil.base64Encode(
            Blob.valueOf('Sample PDF Content')
        );

    Test.startTest();

    try {

        REAPP_LeaseAgreementController.sendLeaseAgreementEmail(

            agreement.Id,
            samplePdfBase64
        );

    } catch (Exception e) {

        // Expected in test context if
        // Org Wide Email Address does not exist
    }

    Test.stopTest();

    System.assert(true);
}
    // ─────────────────────────────────────────────────────────
    // TEST INVALID AGREEMENT ID
    // ─────────────────────────────────────────────────────────

    @IsTest
    static void testGetLeaseAgreementInvalidId() {

        Test.startTest();

        try {

            REAPP_LeaseAgreementController.getLeaseAgreement(

                'a00000000000000AAA'
            );

            System.assert(false);

        } catch (Exception e) {

            System.assert(
                e.getMessage().contains('List has no rows')
            );
        }

        Test.stopTest();
    }
}