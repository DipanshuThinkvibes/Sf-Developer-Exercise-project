public with sharing class ContactTriggerSyncPrimaryEmail {
public static void syncPrimaryContactEmail(List<Contact> newContacts,List<Contact> oldContacts) {
    Set<Id> accountIds = new Set<Id>();
    // Collect Account IDs from new Contact records.
    if (newContacts != null) {
        for (Contact con : newContacts) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }
    }
    // Collect Account IDs from old Contact records.
    // Important when a Contact moves to another Account.
    if (oldContacts != null) {
        for (Contact con : oldContacts) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }
    }
    if (accountIds.isEmpty()) {
        return;
    }
    // Find the current Primary Contact for each affected Account.
    Map<Id, String> accountToPrimaryEmailMap = new Map<Id, String>();
    for (Contact con : [
        SELECT Id, AccountId, Email
        FROM Contact
        WHERE AccountId IN :accountIds
        AND Is_Primary__c = true
    ]) {
        accountToPrimaryEmailMap.put(
            con.AccountId,
            con.Email
        );
    }

    // Query affected Accounts.
    List<Account> accountsToUpdate = new List<Account>();
    for (Account acc : [
        SELECT Id, Primary_Contact_Email__c
        FROM Account
        WHERE Id IN :accountIds
    ]) {
        String primaryEmail = accountToPrimaryEmailMap.get(acc.Id);
        // Update only when the email has actually changed.
        if (acc.Primary_Contact_Email__c != primaryEmail) {
            accountsToUpdate.add(
                new Account(
                    Id = acc.Id,
                    Primary_Contact_Email__c = primaryEmail
                )
            );
        }
    }

    if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
    }
}

}