@IsTest
public with sharing class ContactTriggerTestClass {
   @IsTest
     public static void testPrimaryContact() {
        Account acc = new Account(Name='Test Account');
        insert acc;
        Contact con1 = new Contact(LastName='Test1', AccountId=acc.Id, Is_Primary__c=true);
        insert con1;
        Contact con2 = new Contact(LastName='Test2', AccountId=acc.Id, Is_Primary__c=true);
        Test.startTest();
        try {
            insert con2;
            System.assert(false, 'Expected an exception to be thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('There is already a primary contact for this account.')); 
            }
            Test.stopTest();


    }
}