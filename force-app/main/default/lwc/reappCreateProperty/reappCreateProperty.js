import { LightningElement, track } from 'lwc';

import createProperty from '@salesforce/apex/REAPP_PropertyController.createProperty';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ReappCreateProperty extends LightningElement {

    @track propertyRecord = {};
propertyCreated = false;

showUploadWarning = false;
    propertyId;

    typeOptions = [
        { label: 'Residential', value: 'Residential' },
        { label: 'Commercial', value: 'Commercial' }
    ];

    furnishingOptions = [
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

    statusOptions = [
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    handleChange(event) {

        const field = event.target.dataset.field;

        this.propertyRecord[field] = event.detail.value;
    }

    handleCreate() {

        createProperty({
            propertyRecord: this.propertyRecord
        })
        .then(result => {

    this.propertyId = result;

    this.propertyCreated = true;

    this.showUploadWarning = true;

    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Property Created',
            message: 'Please upload property images',
            variant: 'warning'
        })
    );
})
        .catch(error => {

            console.error(error);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error creating property',
                    variant: 'error'
                })
            );
        });
    }

   handleUploadFinished(event) {

    const uploadedFiles = event.detail.files;

    if(uploadedFiles.length > 0) {

        this.showUploadWarning = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Property and Images Saved Successfully',
                variant: 'success'
            })
        );
    }
}
}