import { LightningElement, track } from 'lwc';
import getProperties from '@salesforce/apex/REAPP_PropertyController.getProperties';

const columns = [
    { label: 'Property Name', fieldName: 'Name' },
    { label: 'City', fieldName: 'City__c' },
    { label: 'State', fieldName: 'State__c' },
    { label: 'Rent', fieldName: 'Rent__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c' }
];

export default class ReappPropertyList extends LightningElement {

    columns = columns;

    @track properties = [];

    pageNumber = 1;
    pageSize = 25;
    totalRecords = 0;

    statusFilter = '';
    furnishingFilter = '';
    maxPrice;
    distanceKm;

    userLatitude;
    userLongitude;

    statusOptions = [
        { label: 'All', value: '' },
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    furnishingOptions = [
        { label: 'All', value: '' },
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

connectedCallback() {

    if(navigator.geolocation) {

        navigator.geolocation.getCurrentPosition(position => {

            this.userLatitude = position.coords.latitude;

            this.userLongitude = position.coords.longitude;

            this.loadProperties();
        });

    } else {

        this.loadProperties();
    }
}

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

            this.properties = result.properties;
            this.totalRecords = result.totalRecords;
        })
        .catch(error => {

    console.log('FULL ERROR');

    console.log(JSON.stringify(error));

    console.log('BODY');

    console.log(JSON.stringify(error.body));

    console.log('MESSAGE');

    console.log(error.body.message);
});
    }

    get disablePrevious() {
        return this.pageNumber === 1;
    }

    get disableNext() {
        return this.pageNumber * this.pageSize >= this.totalRecords;
    }

    handleNext() {
        if(!this.disableNext) {
            this.pageNumber++;
            this.loadProperties();
        }
    }

    handlePrevious() {
        if(this.pageNumber > 1) {
            this.pageNumber--;
            this.loadProperties();
        }
    }

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

    this.maxPrice = event.detail.value;

    if(!this.maxPrice) {

        this.maxPrice = null;
    }

    this.pageNumber = 1;

    this.loadProperties();
}

handleDistanceChange(event) {

    this.distanceKm = event.detail.value;

    if(!this.distanceKm) {

        this.distanceKm = null;
    }

    this.pageNumber = 1;

    this.loadProperties();
}
}