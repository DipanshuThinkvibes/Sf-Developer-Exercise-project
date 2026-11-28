
import { LightningElement, api, wire } from 'lwc';
import getTimeline from '@salesforce/apex/AchievementTimelineController.getTimeline';
import { refreshApex } from '@salesforce/apex';

export default class AchievementTimeline extends LightningElement {

    @api recordId;
    @api title = 'Achievement Timeline';
    @api headerFieldSet = 'Achievement_Header_Fields';
    @api scoreFieldSet = 'Achievement_Score_Fields';
    @api detailFieldSet = 'Achievement_Detail_Fields';
    @api sortOrder = 'Newest';

    groups = [];
    error;
    isLoading = true;
    wiredResult;
    activeSectionName;

    get errorMessage() {
        return this.error?.body?.message || this.error?.message || 'Unable to load achievements.';
    }

    @wire(getTimeline, {
        recordId: '$recordId',
        headerFieldSet: '$headerFieldSet',
        scoreFieldSet: '$scoreFieldSet',
        detailFieldSet: '$detailFieldSet',
        sortOrder: '$sortOrder'
    })
    wiredTimeline(result) {
        this.wiredResult = result;
        this.isLoading = false;

        if (result.data) {
            this.groups = result.data.map(group => ({
                ...group,
                label: `${group.sectionName} (${group.count})`,
                achievements: group.achievements.map(achievement => ({
                    ...achievement,
                    recordUrl: `/lightning/r/Achievement__c/${achievement.id}/view`,
                    headerFields: achievement.headerFields.map(field => ({
                        ...field,
                        isName: field.apiName === 'Name'
                    }))
                }))
            }));
            console.log('Groups:', result.data);
            this.activeSectionName =  this.groups[0].sectionName ;
            this.error = undefined;
        } else if (result.error) {
            this.groups = [];
            this.error = result.error;
        }
    }

    async handleRefresh() {
        this.isLoading = true;

        try {
            await refreshApex(this.wiredResult);
        } finally {
            this.isLoading = false;
        }
    }
}
