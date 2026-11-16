public with sharing class searchRecords {
  public static void searchRecords() {
        List<List<SObject>> searchResults = [
            FIND 'John' IN ALL FIELDS
            RETURNING
            Consultant__c(Id, Name),
            Contact(Id, Name)
        ];

        for (List<SObject> records : searchResults) {
            for (SObject record : records) {
                System.debug(record);
            }
        }

    }
    public static void  searchMalePeople(String searchKey) {
        String searchTerm = searchKey + '*';
        List<List<SObject>> results = [
            FIND :searchTerm IN ALL FIELDS
            RETURNING
                Consultant__c(
                    Id, Name, Gender__c
                    WHERE Gender__c = 'Male'
                ),
                Contact(
                    Id, Name
                )
        ];

        for (List<SObject> records : results) {
            for (SObject record : records) {
                System.debug(record);
            }
        }

    }
     public static void  findApexPositions() {

        List<List<SObject>> results = [
            FIND 'Apex'
            IN ALL FIELDS
            RETURNING Position__c(
                Id,
                Name,
                Description__c
            )
        ];

        for (List<SObject> records : results) {
            for (SObject record : records) {
                System.debug(record);
            }
        }
    }
}   