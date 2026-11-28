
public with sharing class AchievementTimelineController {

public class AchievementField {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public AchievementField(String apiName, String label, String value) {
            this.apiName = apiName;
            this.label = label;
            this.value = value;
        }    
    }

    public class AchievementItem {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public List<AchievementField> headerFields;
        @AuraEnabled public List<AchievementField> scoreFields;
        @AuraEnabled public List<AchievementField> detailFields;
    }

    public class YearGroup {
        @AuraEnabled public String sectionName;
        @AuraEnabled public Integer count = 0;
        @AuraEnabled public List<AchievementItem> achievements = new List<AchievementItem>();
    }

    @AuraEnabled(cacheable=true)
    public static List<YearGroup> getTimeline(Id recordId, String headerFieldSet, String scoreFieldSet, String detailFieldSet, String sortOrder) {

        if (recordId == null) return new List<YearGroup>();

        Id consultantId = recordId.getSObjectType() == Consultant__c.SObjectType ? recordId : null;

        if (recordId.getSObjectType() == Talent_Review__c.SObjectType) {
            Talent_Review__c review = [SELECT Consultant__c FROM Talent_Review__c WHERE Id = :recordId WITH USER_MODE LIMIT 1];
            consultantId = review.Consultant__c;
        }

        if (consultantId == null) return new List<YearGroup>();

        Map<String, Schema.FieldSet> fieldSets = Schema.SObjectType.Achievement__c.fieldSets.getMap();
        Schema.FieldSet headerSet = fieldSets.get(headerFieldSet), scoreSet = fieldSets.get(scoreFieldSet), detailSet = fieldSets.get(detailFieldSet);

        if (headerSet == null || scoreSet == null || detailSet == null) throw new AuraHandledException('Achievement Field Set not found.');

        Set<String> fieldNames = new Set<String>{'Id', 'Name', 'Date__c', 'Consultant__c'};

        for (Schema.FieldSetMember field : headerSet.getFields()) fieldNames.add(field.getFieldPath());
        for (Schema.FieldSetMember field : scoreSet.getFields()) fieldNames.add(field.getFieldPath());
        for (Schema.FieldSetMember field : detailSet.getFields()) fieldNames.add(field.getFieldPath());

        List<String> queryFields = new List<String>(fieldNames);
        queryFields.sort();

        String direction = sortOrder == 'Oldest' ? 'ASC' : 'DESC';
        String query = 'SELECT ' + String.join(queryFields, ', ') + ' FROM Achievement__c WHERE Consultant__c = :consultantId ORDER BY Date__c ' + direction;

        List<Achievement__c> records = (List<Achievement__c>) Database.queryWithBinds(query, new Map<String, Object>{'consultantId' => consultantId}, AccessLevel.USER_MODE);

        Map<String, YearGroup> groupsYearMap = new Map<String, YearGroup>();
        List<YearGroup> result = new List<YearGroup>();

        for (Achievement__c record : records) {
            String year = record.Date__c == null ? 'Undated' : String.valueOf(record.Date__c.year());

            if (!groupsYearMap.containsKey(year)) {
                YearGroup groupyear = new YearGroup();
                groupyear.sectionName = year;
                groupsYearMap.put(year, groupyear);
                result.add(groupyear);
            }

            AchievementItem item = new AchievementItem();
            item.id = record.Id;
            item.name = record.Name;
            item.headerFields = getFields(record, headerSet);
            item.scoreFields = getFields(record, scoreSet);
            item.detailFields = getFields(record, detailSet);

            groupsYearMap.get(year).achievements.add(item);
            groupsYearMap.get(year).count++;
        }

        return result;
    }

    private static List<AchievementField> getFields(Achievement__c record, Schema.FieldSet fieldSet) {
        List<AchievementField> fields = new List<AchievementField>();

        for (Schema.FieldSetMember member : fieldSet.getFields()) {
            Object value = record.get(member.getFieldPath());
            fields.add(new AchievementField(member.getFieldPath(), member.getLabel(), value == null ? '' : String.valueOf(value)));
        }

        return fields;
    }
}
