public with sharing class OrderShippingToCustomerUserService {
    public static void createOrderShippingToCustomerUser(List<Order> newOrder,Map<Id,Order> oldOrderMap){
        set<Id> ShippedOrderIds = new set<Id>();
        set<Id> accountIds=new set<Id>();
        for(Order ord:newOrder){
            Order oldOrd = oldOrderMap.get(ord.Id);
            if(oldOrd.Status != 'Shipped' && ord.Status == 'Shipped'){
                ShippedOrderIds.add(ord.Id);
                accountIds.add(ord.AccountId);
            }
        }
        List<Opportunity> opportunityIds = [SELECT Id FROM Opportunity WHERE Id IN (SELECT OpportunityId FROM Order WHERE Id IN :ShippedOrderIds)];
        List<Contact> contacts = [SELECT Id, Name, Email FROM Contact WHERE Id IN (SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId IN :opportunityIds AND Role = 'Primary Support' ) AND AccountId IN :accountIds];
        System.enqueueJob(new CustomerCommunityUser(contacts));
    }
}