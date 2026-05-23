import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Property__c.Name',
    'Property__c.Address__c',
    'Property__c.Location__Latitude__s',
    'Property__c.Location__Longitude__s'
];

export default class PropertyMap extends LightningElement {

    @api recordId;

    latitude;
    longitude;
    address;
    name;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredProperty({ error, data }) {

        if (data) {

            this.name = data.fields.Name.value;
            this.address = data.fields.Address__c.value;

            this.latitude = data.fields.Location__Latitude__s?.value;
            this.longitude = data.fields.Location__Longitude__s?.value;

        } else if (error) {
            console.error('Error loading property:', error);
        }
    }

    get hasLocation() {
        return this.latitude && this.longitude;
    }

    get mapMarkers() {

        if (!this.hasLocation) return [];

        return [
            {
                location: {
                    Latitude: this.latitude,
                    Longitude: this.longitude
                },
                title: this.name,
                description: this.address
            }
        ];
    }
}