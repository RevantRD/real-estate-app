public with sharing class REAPP_LeaseAgreementController {
    
    /**
     * @description Retrieves lease agreement details for PDF generation
     * @param agreementId The Id of the Lease Agreement record
     * @return LeaseAgreementWrapper containing agreement details
     * @throws AuraHandledException if agreement is not found or error occurs
     */
    @AuraEnabled(cacheable=true)
    public static LeaseAgreementWrapper getLeaseAgreement(Id agreementId) {
        try {
            // Validate input
            if (agreementId == null) {
                throw new AuraHandledException('Agreement Id cannot be null');
            }

            // Query lease agreement with related records
            List<Lease_Agreement__c> agreements = [
                SELECT Id, Name, Terms__c, Agreed_Monthly_Rent__c, Start_Date__c, End_Date__c,
                       Property__r.Name, Tenant__r.Name
                FROM Lease_Agreement__c
                WHERE Id = :agreementId
                LIMIT 1
            ];

            // Check if record exists
            if (agreements.isEmpty()) {
                throw new AuraHandledException('Lease Agreement not found');
            }

            Lease_Agreement__c agreement = agreements[0];

            // Null check for related records
            String propertyName = (agreement.Property__r != null) ? agreement.Property__r.Name : 'N/A';
            String tenantName = (agreement.Tenant__r != null) ? agreement.Tenant__r.Name : 'N/A';
            
            // Null check for field values
            String terms = (agreement.Terms__c != null) ? agreement.Terms__c : 'N/A';
            String rent = (agreement.Agreed_Monthly_Rent__c != null) ? String.valueOf(agreement.Agreed_Monthly_Rent__c) : '0';
            String startDate = (agreement.Start_Date__c != null) ? String.valueOf(agreement.Start_Date__c) : 'N/A';
            String endDate = (agreement.End_Date__c != null) ? String.valueOf(agreement.End_Date__c) : 'N/A';

            return new LeaseAgreementWrapper(
                agreement.Name,
                propertyName,
                tenantName,
                terms,
                rent,
                startDate,
                endDate
            );

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Lease Agreement: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for Lease Agreement data
     */
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
    
    /**
     * @description Sends lease agreement PDF via email to tenant
     * @param agreementId The Id of the Lease Agreement record
     * @param pdfBase64 Base64 encoded PDF content
     * @throws AuraHandledException if email send fails
     */
    @AuraEnabled
    public static void sendLeaseAgreementEmail(Id agreementId, String pdfBase64) {
        try {
            // Validate inputs
            if (agreementId == null) {
                throw new AuraHandledException('Agreement Id cannot be null');
            }

            // Query lease agreement with tenant email
            List<Lease_Agreement__c> agreements = [
                SELECT Id, Name, Tenant__r.Name, Tenant__r.Email__c
                FROM Lease_Agreement__c
                WHERE Id = :agreementId
                LIMIT 1
            ];

            // Validate query result
            if (agreements.isEmpty()) {
                throw new AuraHandledException('Lease Agreement not found');
            }

            Lease_Agreement__c agreement = agreements[0];

            // Validate tenant email
            if (agreement.Tenant__r == null || String.isBlank(agreement.Tenant__r.Email__c)) {
                throw new AuraHandledException('Tenant email address not found. Please update the tenant record with a valid email address.');
            }

            System.debug('Sending email to: ' + agreement.Tenant__r.Email__c);

            // Create email message
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            // Use Org-Wide Email Address
            List<OrgWideEmailAddress> orgWideAddresses = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                WHERE DisplayName = :System.Label.Org_Wide_Address_Label 
                LIMIT 1
            ];
            
            if (!orgWideAddresses.isEmpty()) {
                mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
            }

            // Set email properties
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
            
            // Create PDF attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('LeaseAgreement_' + agreement.Name + '.pdf');
            attachment.setBody(EncodingUtil.base64Decode(pdfBase64));
            attachment.setContentType('application/pdf');
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            // Send email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        }  catch (Exception e) {
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }
}