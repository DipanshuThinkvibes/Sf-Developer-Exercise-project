
public with sharing class ConsultantSummaryController {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getSummary(Id recordId, String fieldSetName) {

        Map<String, String> result = new Map<String, String>();

        if (recordId == null || String.isBlank(fieldSetName)) {
            return result;
        }

        Id consultantId;

        if (recordId.getSObjectType() == Consultant__c.SObjectType) {
            consultantId = recordId;
        } else if (recordId.getSObjectType() == Talent_Review__c.SObjectType) {
            Talent_Review__c review = [
                SELECT Consultant__c
                FROM Talent_Review__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];

            consultantId = review.Consultant__c;
        }

        if (consultantId == null) {
            return result;
        }

        Schema.FieldSet fieldSet =
            Schema.SObjectType.Consultant__c.fieldSets.getMap().get(fieldSetName);

        if (fieldSet == null) {
            throw new AuraHandledException('Field Set not found.');
        }

        List<String> fields = new List<String>();

        for (Schema.FieldSetMember member : fieldSet.getFields()) {
            fields.add(member.getFieldPath());
        }

        if (fields.isEmpty()) {
            return result;
        }

        String query = 'SELECT ' + String.join(fields, ', ') +
            ' FROM Consultant__c WHERE Id = :consultantId';

        Consultant__c consultant = (Consultant__c) Database.queryWithBinds(
            query,
            new Map<String, Object>{ 'consultantId' => consultantId },
            AccessLevel.USER_MODE
        );

        for (Schema.FieldSetMember member : fieldSet.getFields()) {
            Object value = consultant.get(member.getFieldPath());

            result.put(
                member.getLabel(),
                value == null ? '' : String.valueOf(value)
            );
        }

        return result;
    }
}
