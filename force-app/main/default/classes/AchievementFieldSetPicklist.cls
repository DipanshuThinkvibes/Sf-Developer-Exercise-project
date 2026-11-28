
global class AchievementFieldSetPicklist extends VisualEditor.DynamicPickList {

    global override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('Achievement Header Fields', 'Achievement_Header_Fields');
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        List<VisualEditor.DataRow> rows = new List<VisualEditor.DataRow>();
        Map<String, Schema.FieldSet> fieldSets = Schema.SObjectType.Achievement__c.fieldSets.getMap();

        for (String name : fieldSets.keySet()) {
            Schema.FieldSet fieldSet = fieldSets.get(name);
            rows.add(new VisualEditor.DataRow(fieldSet.getLabel(), name));
        }

        return new VisualEditor.DynamicPickListRows(rows);
    }

    
}
