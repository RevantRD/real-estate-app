import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import jsPDFLib from '@salesforce/resourceUrl/jsPDF'; // upload jsPDF as static resource
import getLeaseAgreement from '@salesforce/apex/REAPP_LeaseAgreementController.getLeaseAgreement';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendLeaseAgreementEmail from '@salesforce/apex/REAPP_LeaseAgreementController.sendLeaseAgreementEmail';
export default class LeaseAgreementPdf extends LightningElement {
    @api recordId; // Lease_Agreement__c Id
    jsPdfInitialized = false;

    renderedCallback() {
        if (this.jsPdfInitialized) {
            return;
        }
        this.jsPdfInitialized = true;

        loadScript(this, jsPDFLib)
            .then(() => {
                console.log('jsPDF loaded');
            })
            .catch(error => {
                console.error('Error loading jsPDF', error);
            });
    }

    async generatePdf() {
  
        const leaseData = await getLeaseAgreement({ agreementId: this.recordId });
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();

        // Bold header
        doc.setFontSize(16);
        doc.setFont("helvetica", "bold");
        doc.text("Lease Agreement", 20, 20);

        // Reset font for table
        doc.setFontSize(12);
        doc.setFont("helvetica", "normal");

        // Table data
        const rows = [
            ["Agreement Name", leaseData.Name],
            ["Property", leaseData.propertyName],
            ["Tenant", leaseData.tenantName],
            ["Terms", leaseData.terms],
            ["Monthly Rent", leaseData.rent + " RS"],
            ["Start Date", leaseData.startDate],
            ["End Date", leaseData.endDate]
        ];

        // Table layout
        const startX = 20;
        const startY = 20;
        const col1Width = 50;
        const col2Width = 120;
        const rowHeight = 10;

        // // Draw header row
        // doc.setFont("helvetica", "bold");
        // doc.rect(startX, startY, col1Width, rowHeight); // Field cell
        // doc.rect(startX + col1Width, startY, col2Width, rowHeight); // Value cell
        // doc.text("Field", startX + 2, startY + 7);
        // doc.text("Value", startX + col1Width + 2, startY + 7);

        // Draw data rows
        let y = startY + rowHeight;
        doc.setFont("helvetica", "normal");
        rows.forEach(row => {
            // Draw borders
            doc.rect(startX, y, col1Width, rowHeight);
            doc.rect(startX + col1Width, y, col2Width, rowHeight);

            // Add text
            doc.setFont("helvetica", "bold");
            doc.text(row[0], startX + 2, y + 7);
            doc.setFont("helvetica", "normal");
            doc.text(row[1] || "", startX + col1Width + 2, y + 7);

            y += rowHeight;
        });
        return { doc, leaseData };
   
}
    // Download PDF
    async handleDownload() {
        try {
            const { doc, leaseData } = await this.generatePdf();
            doc.save(`LeaseAgreement_${leaseData.propertyName}.pdf`);
            this.showToast('Success', 'Lease Agreement PDF has been generated and downloaded.', 'success');
        } catch (error) {
            console.error("Error generating PDF:", error);
            this.showToast('Error', 'Failed to generate Lease Agreement PDF.', 'error');
        }
    }
// Send PDF via Apex email
    async handleSend() {
        try {
            const { doc } = await this.generatePdf();

            // Convert PDF to Base64
            const pdfBlob = doc.output('blob');
            const reader = new FileReader();
            reader.onloadend = async () => {
                const base64Pdf = reader.result.split(',')[1];
                try {
                    await sendLeaseAgreementEmail({ agreementId: this.recordId, pdfBase64: base64Pdf });
                    this.showToast('Success', 'Lease Agreement PDF has been emailed to the tenant.', 'success');
                } catch (error) {
                    console.error("Error sending PDF via email:", error);
                    this.showToast('Error', 'Failed to send Lease Agreement PDF via email.', 'error');
                }
            };
            reader.readAsDataURL(pdfBlob);
        } catch (error) {
            console.error("Error preparing PDF for email:", error);
            this.showToast('Error', 'Failed to prepare Lease Agreement PDF for email.', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}