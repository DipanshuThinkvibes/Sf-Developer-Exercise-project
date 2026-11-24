import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { decodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class CustomRecordForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api pageReference;

   

    get resolvedObjectApiName() {
        return this.objectApiName ||
            this.pageReference?.state?.c__objectApiName||'Account';
    }

    defaultValues = {};

    get formTitle() {
        return this.recordId
            ? 'Edit Record'
            : 'Create New Record';
            
    }

    get fields() {
        console.log('Object API Name:', this.resolvedObjectApiName);
        if (this.resolvedObjectApiName === 'Account') {
            return [
                'Name',
                'Phone',
                'Industry',
                'Website',
                'Domain__c',
                'HR_Contact__c'
            ];
        }

        if (this.resolvedObjectApiName === 'Consultant__c') {
            return [
                'First_Name__c',
                'Last_Name__c',
                'Date_of_Birth__c',
                'Sex__c',
                'Email__c',
                'Married__c',
                'Education__c'
            ];
        }

        return [];
    }

    connectedCallback() {
        const encodedValues =
            this.pageReference?.state?.defaultFieldValues;

        if (encodedValues) {
            this.defaultValues =
                decodeDefaultFieldValues(encodedValues);
        }
    }

    handleSubmit(event) {
        event.preventDefault();

        const fields = {
            ...event.detail.fields,
            ...this.defaultValues
        };

        this.template
            .querySelector('lightning-record-edit-form')
            .submit(fields);
    }

    handleSuccess(event) {
        const savedRecordId = event.detail.id;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully!',
                variant: 'success'
            })
        );

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: savedRecordId,
                objectApiName: this.resolvedObjectApiName,
                actionName: 'view'
            }
        });
    }

    handleError(event) {
        console.error('Record save failed:', event.detail);
    }
}