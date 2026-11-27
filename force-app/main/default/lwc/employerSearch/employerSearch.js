
import { LightningElement } from 'lwc';

import searchEmployers
    from '@salesforce/apex/EmployerSearchController.searchEmployers';

export default class EmployerSearch extends LightningElement {

    employerName = '';
    domain = '';
    industry = '';
    billingCity = '';

    allEmployers = [];
    isLoading = false;

    currentPage = 1;
    pageSize = 10;

    sortField = 'Name';
    sortDirection = 'asc';

    domainOptions = [
        { label: 'IT', value: 'IT' },
        { label: 'Healthcare', value: 'Healthcare' },
        { label: 'Education', value: 'Education' },
        { label: 'Finance', value: 'Finance' }
    ];

    columns = [
        {
            label: 'Employer Name',
            fieldName: 'Name',
            type: 'text',
            sortable: true
        },
        {
            label: 'Domain',
            fieldName: 'Domain__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Industry',
            fieldName: 'Industry',
            type: 'text',
            sortable: true
        },
        {
            label: 'Billing City',
            fieldName: 'BillingCity',
            type: 'text',
            sortable: true
        }
    ];

    // Fetch all records when component loads

    connectedCallback() {
        this.fetchEmployers();
    }

    // Reusable Apex method

    fetchEmployers() {

        this.isLoading = true;

        searchEmployers({
            employerName: this.employerName,
            domain: this.domain,
            industry: this.industry,
            billingCity: this.billingCity
        })
        .then(result => {

            this.allEmployers = [...result];

            this.currentPage = 1;

            this.sortRecords();

        })
        .catch(error => {

            console.error('Employer Search Error:', error);

            this.allEmployers = [];

        })
        .finally(() => {

            this.isLoading = false;

        });
    }

    // Input handlers

    handleNameChange(event) {
        this.employerName = event.target.value;
    }

    handleDomainChange(event) {
        this.domain = event.detail.value;
    }

    handleIndustryChange(event) {
        this.industry = event.target.value;
    }

    handleCityChange(event) {
        this.billingCity = event.target.value;
    }

    // Search button

    handleSearch() {
        this.fetchEmployers();
    }

    // Reset filters and fetch all records

    handleReset() {

        // Clear all filter fields
        this.employerName = '';
        this.domain = '';
        this.industry = '';
        this.billingCity = '';

        // Reset pagination
        this.currentPage = 1;

        // Fetch all employer records again
        this.fetchEmployers();
    }
    // Sorting

    handleSort(event) {

        this.sortField = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        this.sortRecords();
    }

    sortRecords() {

        let records = [...this.allEmployers];

        records.sort((a, b) => {

            let valueA = a[this.sortField] ?? '';
            let valueB = b[this.sortField] ?? '';

            if (typeof valueA === 'string') {
                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();
            }

            let result = valueA > valueB ? 1 :
                         valueA < valueB ? -1 : 0;

            return this.sortDirection === 'asc'
                ? result
                : -result;
        });

        this.allEmployers = records;
    }

    // Pagination

    get totalRecords() {
        return this.allEmployers.length;
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    get employers() {

        const start =
            (this.currentPage - 1) * this.pageSize;

        return this.allEmployers.slice(
            start,
            start + this.pageSize
        );
    }
    

    get hasEmployers() {
        return this.totalRecords > 0;
    }

    get recordInformation() {

        if (!this.totalRecords) {
            return 'Total Records: 0';
        }

        const start =
            (this.currentPage - 1) * this.pageSize + 1;

        const end = Math.min(
            this.currentPage * this.pageSize,
            this.totalRecords
        );

        return `Showing ${start}-${end} of ${this.totalRecords}`;
    }

    get pageInformation() {
        return `Page ${this.currentPage} of ${this.totalPages || 1}`;
    }

    get isFirstPage() {
        return this.currentPage <= 1 || this.isLoading;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages ||
            this.isLoading ||
            this.totalRecords === 0;
    }

    handleFirst() {
        this.currentPage = 1;
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    handleLast() {
        this.currentPage = this.totalPages;
    }
}
