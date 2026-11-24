public with sharing class ContactTriggerSyncCount {
    public static void updateContactCount(List<Contact> newContacts,List<Contact> oldContacts) {
        Set<Id> accountIds = new Set<Id>();
        if (newContacts != null) {
            for (Contact con : newContacts) {
                if (con.AccountId != null) {
                    accountIds.add(con.AccountId);
                }
            }
        }
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
        Map<Id, Integer> accountToContactCountMap =new Map<Id, Integer>();
         for (AggregateResult result : [
            SELECT AccountId, COUNT(Id) ContactCount
            FROM Contact
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ]) {
            accountToContactCountMap.put(
                (Id) result.get('AccountId'),
                (Integer) result.get('ContactCount')
            );
        }

         List<Account> accountsToUpdate = new List<Account>();

        for (Id accountId : accountIds) {
            Integer contactCount = 0;
            if (accountToContactCountMap.containsKey(accountId)) {
                contactCount = accountToContactCountMap.get(accountId);
            }
            accountsToUpdate.add(
                new Account(
                    Id = accountId,
                    Contact_Count__c = contactCount
                )
            );
        }
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}