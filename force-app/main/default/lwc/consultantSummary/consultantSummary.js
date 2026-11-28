
import { LightningElement, api, wire } from 'lwc';
import getSummary from '@salesforce/apex/ConsultantSummaryController.getSummary';

export default class ConsultantSummary extends LightningElement {

    @api recordId;
    @api title = 'Consultant Summary';
    @api showHeader =false;
    @api columns = '2';
    @api fieldSetName = 'Consultant_Summary_Fields';

    fields = [];
    error;
    isLoading = true;

    get cardTitle() {
        
        return this.showHeader ? this.title : '';
    }

    get columnCount() {
        const count = Number(this.columns);
        return count >= 1 && count <= 3 ? count : 2;
    }

    getColumnClass() {
        if (this.columnCount === 1) {
            return 'summary-field slds-size_1-of-1';
        }

        if (this.columnCount === 2) {
            return 'summary-field slds-size_1-of-1 slds-medium-size_1-of-2';
        }

        return 'summary-field slds-size_1-of-1 slds-medium-size_1-of-3';
    }

    @wire(getSummary, {
        recordId: '$recordId',
        fieldSetName: '$fieldSetName'
    })
    wiredSummary({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.fields = Object.entries(data).map(([label, value]) => ({
                label,
                value,
                columnClass: this.getColumnClass()
            }));

            this.error = undefined;
        } else if (error) {
            this.fields = [];
            this.error = error;
        }
    }
}
    