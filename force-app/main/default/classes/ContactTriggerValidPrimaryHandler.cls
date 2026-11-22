public with sharing class ContactTriggerValidPrimaryHandler {
    

    // This method is called before inserting new Contact records.
    // It checks if there is already a primary contact for the associated account and prevents duplicates.
    public static void checkInsertedPrimaryContact(List<Contact> newContacts){
        Map<Id,Boolean> accountIdToPrimaryContactMap = new Map<Id,Boolean>();
        Set<Id> accountIds = new Set<Id>();
        for (Contact con : newContacts) {
            if (con.AccountId != null && con.Is_Primary__c == true) {
                accountIds.add(con.AccountId); 
            }
        }
        if (!accountIds.isEmpty()) {
            List<Contact> existingPrimaryContacts = [
                SELECT Id, AccountId
                FROM Contact
                WHERE AccountId IN :accountIds AND Is_Primary__c = true 
            ];
            Map<Id, Contact> accountToPrimaryContactMap = new Map<Id, Contact>();
            for(Contact existingContact : existingPrimaryContacts) {
                accountToPrimaryContactMap.put(existingContact.AccountId, existingContact);
            }
            for(Contact newContact : newContacts) {
                if(newContact.AccountId != null && newContact.Is_Primary__c == true) {
                    if(accountToPrimaryContactMap.containsKey(newContact.AccountId) ) {
                        newContact.addError('There is already a primary contact for this account.');
                    }
                    else if(accountIdToPrimaryContactMap.containsKey(newContact.AccountId)){
                        newContact.addError('There is already a primary contact for this account.');
                    }
                    else{
                        accountIdToPrimaryContactMap.put(newContact.AccountId,true);
                    }
                                       
                }
            }
        }
    }

    // This method is called after updating Contact records.
    // It checks if there is already a primary contact for the associated account and prevents duplicates.
   public static void checkUpdatedPrimaryContact(Map<Id, Contact> oldContacts,List<Contact> newContacts) {
    Set<Id> contactIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();

    // Step 1: Collect all updated Contact IDs.
    // Collect Account IDs for Contacts that will be Primary.
    for (Contact con : newContacts) {
        contactIds.add(con.Id);

        if (con.AccountId != null && con.Is_Primary__c == true) {
            accountIds.add(con.AccountId);
        }
    }

    if (accountIds.isEmpty()) {
        return;
    }

    // Step 2: Find other existing Primary Contacts.
    List<Contact> existingPrimaryContacts = [
        SELECT Id, AccountId
        FROM Contact
        WHERE AccountId IN :accountIds
        AND Is_Primary__c = true
        AND Id NOT IN :contactIds
    ];

    Set<Id> accountsWithPrimaryContact = new Set<Id>();

    for (Contact existingContact : existingPrimaryContacts) {
        accountsWithPrimaryContact.add(existingContact.AccountId);
    }

    // Step 3: Validate the proposed updated Contacts.
    for (Contact con : newContacts) {
        if (con.AccountId == null || con.Is_Primary__c != true) {
            continue;
        }

        if (accountsWithPrimaryContact.contains(con.AccountId)) {
            con.addError('There is already a primary contact for this account.');
        } else {
            accountsWithPrimaryContact.add(con.AccountId);
        }
    }
}
}