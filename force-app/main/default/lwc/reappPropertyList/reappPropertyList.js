import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProperties from '@salesforce/apex/REAPP_PropertyController.getProperties';
import createPropertyWithImage from '@salesforce/apex/REAPP_PropertyController.createPropertyWithImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Property Name', fieldName: 'Name' },
    { label: 'City', fieldName: 'City__c' },
    { label: 'State', fieldName: 'State__c' },
    { label: 'Rent', fieldName: 'Rent__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c' }
];

export default class ReappPropertyList extends NavigationMixin(LightningElement) {

    // =========================
    // CONFIG
    // =========================
    columns = columns;

    // =========================
    // UI STATE
    // =========================
    showModal = false;
    properties = [];

    // =========================
    // WIRE RESULT (for refreshApex if needed later)
    // =========================
    wiredPropertiesResult;

    // =========================
    // PAGINATION
    // =========================
    pageNumber = 1;
    pageSize = 25;
    totalRecords = 0;

    // =========================
    // FILTERS
    // =========================
    statusFilter = '';
    furnishingFilter = '';
    maxPrice;
    distanceKm;

    // =========================
    // GEOLOCATION
    // =========================
    userLatitude;
    userLongitude;

    // =========================
    // CREATE PROPERTY STATE
    // =========================
    property = {};
    uploadedFileIds = [];
    imageUploaded = false;

    // =========================
    // PICKLIST OPTIONS
    // =========================
    statusOptionsModal = [
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    furnishingOptionsModal = [
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

    typeOptions = [
        { label: 'Residential', value: 'Residential' },
        { label: 'Commercial', value: 'Commercial' }
    ];

    // =========================
    // INIT
    // =========================
    connectedCallback() {
        this.initLocationAndLoad();
    }

    initLocationAndLoad() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.userLatitude = position.coords.latitude;
                    this.userLongitude = position.coords.longitude;
                    this.loadProperties();
                },
                (error) => {
                    console.warn('Geolocation failed:', error);
                    this.loadProperties();
                }
            );
        } else {
            this.loadProperties();
        }
    }

    // =========================
    // LOAD PROPERTIES
    // =========================
    loadProperties() {

        getProperties({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            statusFilter: this.statusFilter,
            furnishingFilter: this.furnishingFilter,
            maxPrice: this.maxPrice,
            userLatitude: this.userLatitude,
            userLongitude: this.userLongitude,
            distanceKm: this.distanceKm
        })
        .then(result => {

            if (result) {
                this.properties = [...(result.properties || [])];
                this.totalRecords = result.totalRecords || 0;
            }

        })
        .catch(error => {
            console.error('Load error:', error);
            this.showToast('Error', 'Failed to load properties', 'error');
        });
    }

    // =========================
    // PAGINATION
    // =========================
    get disablePrevious() {
        return this.pageNumber <= 1;
    }

    get disableNext() {
        return this.pageNumber * this.pageSize >= this.totalRecords;
    }

    handleNext() {
        if (!this.disableNext) {
            this.pageNumber++;
            this.loadProperties();
        }
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadProperties();
        }
    }

    // =========================
    // FILTERS
    // =========================
    handleStatusChange(event) {
        this.statusFilter = event.detail.value;
        this.pageNumber = 1;
        this.loadProperties();
    }

    handleFurnishingChange(event) {
        this.furnishingFilter = event.detail.value;
        this.pageNumber = 1;
        this.loadProperties();
    }

    handlePriceChange(event) {
        this.maxPrice = event.detail.value || null;
        this.pageNumber = 1;
        this.loadProperties();
    }

    handleDistanceChange(event) {
        this.distanceKm = event.detail.value || null;
        this.pageNumber = 1;
        this.loadProperties();
    }

    // =========================
    // MODAL
    // =========================
    openModal() {
        this.resetModalState();
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.resetModalState();
    }

    resetModalState() {
        this.property = {};
        this.uploadedFileIds = [];
        this.imageUploaded = false;
    }

    // =========================
    // FORM
    // =========================
    handleChange(event) {
        const field = event.target.dataset.field;

        this.property = {
            ...this.property,
            [field]: event.target.value
        };
    }

    // =========================
    // FILE UPLOAD
    // =========================
    handleUploadFinished(event) {
        const files = event.detail.files || [];

        this.uploadedFileIds = files
            .map(f => f.documentId)
            .filter(id => id);

        this.imageUploaded = this.uploadedFileIds.length > 0;
    }

    // =========================
    // CREATE PROPERTY
    // =========================
    handleCreate() {

        if (!this.imageUploaded) {
            this.showToast('Error', 'Image is required', 'error');
            return;
        }

        const requiredFields = [
            'Name',
            'Address__c',
            'City__c',
            'State__c',
            'Postal_Code__c',
            'Country__c',
            'Type__c',
            'Furnishing_Status__c',
            'Status__c',
            'Rent__c',
            'Description__c'
        ];

        for (let field of requiredFields) {
            if (!this.property[field]) {
                this.showToast('Error', `Missing field: ${field}`, 'error');
                return;
            }
        }

        createPropertyWithImage({
            propertyRecord: this.property,
            documentIds: this.uploadedFileIds
        })
        .then((recordId) => {

            this.showToast('Success', 'Property created', 'success');

            this.showModal = false;
            this.resetModalState();

            // refresh list
            this.pageNumber = 1;
            this.loadProperties();

            // navigate
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId,
                    objectApiName: 'Property__c',
                    actionName: 'view'
                }
            });

        })
        .catch(error => {
            console.error(error);
            this.showToast(
                'Error',
                error?.body?.message || 'Unknown error',
                'error'
            );
        });
    }

    // =========================
    // TOAST
    // =========================
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}