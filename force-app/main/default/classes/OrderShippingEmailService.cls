public with sharing class OrderShippingEmailService {
    public static void sendShippingEmail(List<Order> newOrder,Map<Id,Order> oldOrderMap) {
        set<Id> ShippedOrderIds = new set<Id>();
        for(Order ord:newOrder){
            Order oldOrd = oldOrderMap.get(ord.Id);
            if(oldOrd.Status != 'Shipped' && ord.Status == 'Shipped'){
                ShippedOrderIds.add(ord.Id);
            }
        }
        List<Opportunity> opportunityIds = [SELECT Id FROM Opportunity WHERE Id IN (SELECT OpportunityId FROM Order WHERE Id IN :ShippedOrderIds)];
        List<Contact> contacts = [SELECT Id, Name, Email FROM Contact WHERE Id IN (SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId IN :opportunityIds AND Role = 'Primary Support')];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Contact contact:contacts){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {contact.Email});
            email.setSubject('Your Order has been Shipped');
            email.setPlainTextBody('Dear '+contact.Name+',\n\nYour order has been shipped. Please check your account for more details.\n\nThank you for your business.');
            emails.add(email);
        }
        if(!emails.isEmpty()){
            Messaging.sendEmail(emails);
        }
    }

}