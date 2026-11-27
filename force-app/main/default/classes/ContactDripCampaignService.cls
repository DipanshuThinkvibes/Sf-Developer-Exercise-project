public with sharing class ContactDripCampaignService {
   public static void updateContactDripCampaigns(List<Order> newOrders,Map<Id,Order> oldOrderMap) {
        set<Id> ShippedOrderIds = new set<Id>();
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Order ord:newOrders){
            Order oldOrd = oldOrderMap.get(ord.Id);
            if(oldOrd.Status != 'Shipped' && ord.Status == 'Shipped'){
                ShippedOrderIds.add(ord.Id);
            }
        }
        List<Opportunity> opportunityIds = [SELECT Id FROM Opportunity WHERE Id IN (SELECT OpportunityId FROM Order WHERE Id IN :ShippedOrderIds)];
        List<Contact> contacts = [SELECT Id, Drip_Campaign__c FROM Contact WHERE Id IN (SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId IN :opportunityIds AND Role = 'Primary Support')];
        for(Contact contact:contacts){
            contact.Drip_Campaign__c = true;
            contactsToUpdate.add(contact);
        }
        if(!contactsToUpdate.isEmpty()){
            update contactsToUpdate;
        }

   }
}