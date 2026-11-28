
global class ConsultantFieldSetPicklist extends VisualEditor.DynamicPickList {

    global override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('Consultant Summary Fields', 'Consultant_Summary_Fields');
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        List<VisualEditor.DataRow> rows = new List<VisualEditor.DataRow>();
        Map<String, Schema.FieldSet> fieldSets = Schema.SObjectType.Consultant__c.fieldSets.getMap();

        for (String fieldSetName : fieldSets.keySet()) {
            Schema.FieldSet fieldSet = fieldSets.get(fieldSetName);
            rows.add(new VisualEditor.DataRow(fieldSet.getLabel(), fieldSetName));
        }

        return new VisualEditor.DynamicPickListRows(rows);
    }

   
}
