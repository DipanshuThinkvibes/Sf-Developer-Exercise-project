public with sharing class searchRecords {
  public static void searchRecords(String keyword) {
    if(String.isBlank(keyword) && String.isEmpty(keyword) && keyword == null) {
        System.debug('Search keyword is empty or null.');
        return;
    }
    String searchTerm = keyword.trim() + '*';
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
           if(String.isBlank(searchKey) && String.isEmpty(searchKey) && searchKey == null) {
        System.debug('Search keyword is empty or null.');
        return;
    }
        String searchTerm = searchKey.trim() + '*';
        List<List<SObject>> results = [
            FIND :searchTerm IN ALL FIELDS
            RETURNING
                Consultant__c(
                    Id, Name, Gender__c
                    WHERE Gender__c = 'Male'
                ),
                Contact(
                    Id, Name,GenderIdentity
                    WHERE GenderIdentity = 'Male'
                )
        ];

        for (List<SObject> records : results) {
            for (SObject record : records) {
                System.debug(record);
            }
        }

    }
     public static void  findApexPositions(String keyword) {
           if(String.isBlank(keyword) && String.isEmpty(keyword) && keyword == null) {
        System.debug('Search keyword is empty or null.');
        return;
    }
    String searchTerm = keyword.trim() + '*';
        List<List<SObject>> results = [
            FIND :searchTerm
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