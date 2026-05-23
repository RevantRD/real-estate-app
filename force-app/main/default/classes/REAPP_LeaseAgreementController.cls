public with sharing class REAPP_LeaseAgreementController {
    @AuraEnabled(cacheable=true)
    public static LeaseAgreementWrapper getLeaseAgreement(Id agreementId) {
        Lease_Agreement__c agreement = [
            SELECT Id, Name, Terms__c, Agreed_Monthly_Rent__c, Start_Date__c, End_Date__c,
                   Property__r.Name, Tenant__r.Name
            FROM Lease_Agreement__c
            WHERE Id = :agreementId
            LIMIT 1
        ];

        return new LeaseAgreementWrapper(
            agreement.Name,
            agreement.Property__r.Name,
            agreement.Tenant__r.Name,
            agreement.Terms__c,
            String.valueOf(agreement.Agreed_Monthly_Rent__c),
            String.valueOf(agreement.Start_Date__c),
            String.valueOf(agreement.End_Date__c)
        );
    }

    public class LeaseAgreementWrapper {
        @AuraEnabled public String Name;
        @AuraEnabled public String propertyName;
        @AuraEnabled public String tenantName;
        @AuraEnabled public String terms;
        @AuraEnabled public String rent;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;

        public LeaseAgreementWrapper(String Name, String propertyName, String tenantName, String terms,
                                     String rent, String startDate, String endDate) {
            this.Name = Name;
            this.propertyName = propertyName;
            this.tenantName = tenantName;
            this.terms = terms;
            this.rent = rent;
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
    @AuraEnabled
public static void sendLeaseAgreementEmail(Id agreementId, String pdfBase64) {
    Lease_Agreement__c agreement = [
        SELECT Id, Name, Tenant__r.Name, Tenant__r.Email__c
        FROM Lease_Agreement__c
        WHERE Id = :agreementId
        LIMIT 1
    ];
    System.debug('Tenant Email: ' + agreement.Tenant__r.Email__c);

    
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     //  Use Org‑Wide Email Address
    // Custom Label stores the display name of the Org‑Wide Address
    mail.setOrgWideEmailAddressId(
        [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :System.Label.Org_Wide_Address_Label LIMIT 1].Id
    );
    mail.setToAddresses(new String[] { agreement.Tenant__r.Email__c });
    mail.setSubject('Lease Agreement - ' + agreement.Name);
    // Build record link
    String recordLink = System.URL.getOrgDomainUrl().toExternalForm() + '/' + agreement.Id;
    String htmlBody =
        '<p>Dear ' + agreement.Tenant__r.Name + ',</p>' +
        '<p>Please find attached your Lease Agreement.</p>' +
        '<p>You can also view it directly in Salesforce here: ' +
        '<a href="' + recordLink + '">' + agreement.Name + '</a></p>' +
        '<p>Regards,<br/>Real Estate Property Management Team</p>';

    mail.setHtmlBody(htmlBody);
    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
    attachment.setFileName('LeaseAgreement_' + agreement.Name + '.pdf');
    attachment.setBody(EncodingUtil.base64Decode(pdfBase64));
    attachment.setContentType('application/pdf');
    mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
}

}