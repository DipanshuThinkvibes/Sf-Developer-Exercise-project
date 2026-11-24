@IsTest
private class ContactTriggerSyncCountTest {

    // Common test data
    @TestSetup
    static void setupData() {

        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Employer A'),
            new Account(Name = 'Test Employer B'),
            new Account(Name = 'Test Employer C'),
            new Account(Name = 'Test Employer D')
        };

        insert accounts;

        List<Contact> contacts = new List<Contact>{

            // Employer A has two Contacts
            new Contact(
                FirstName = 'Rahul',
                LastName = 'Sharma',
                Email = 'rahul@test.com',
                AccountId = accounts[0].Id,
                Is_Primary__c = true
            ),
            new Contact(
                FirstName = 'Neha',
                LastName = 'Gupta',
                Email = 'neha@test.com',
                AccountId = accounts[0].Id,
                Is_Primary__c = false
            ),

            // Employer B has one Contact
            new Contact(
                FirstName = 'Amit',
                LastName = 'Verma',
                Email = 'amit@test.com',
                AccountId = accounts[1].Id,
                Is_Primary__c = true
            )
        };

        insert contacts;
    }

    // Helper method to get Account
    private static Account getAccount(String accountName) {
        return [
            SELECT Id, Name, Contact_Count__c
            FROM Account
            WHERE Name = :accountName
            LIMIT 1
        ];
    }

    // Helper method to get Contact
    private static Contact getContact(String email) {
        return [
            SELECT Id, FirstName, LastName, Email,
                   AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = :email
            LIMIT 1
        ];
    }

    // 1. Positive: Insert a Contact
    @IsTest
    static void testInsertContact() {

        Account acc = getAccount('Test Employer C');

        Contact con = new Contact(
            FirstName = 'Priya',
            LastName = 'Singh',
            Email = 'priya@test.com',
            AccountId = acc.Id,
            Is_Primary__c = false
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer C');

        System.assertEquals(
            1,
            updatedAccount.Contact_Count__c,
            'Contact count should increase to 1 after insertion.'
        );
    }

    // 2. Positive: Bulk insert multiple Contacts
    @IsTest
    static void testBulkInsertContacts() {

        Account acc = getAccount('Test Employer C');

        List<Contact> contacts = new List<Contact>();

        for (Integer i = 1; i <= 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Employee' + i,
                LastName = 'Test',
                Email = 'employee' + i + '@test.com',
                AccountId = acc.Id,
                Is_Primary__c = false
            ));
        }

        Test.startTest();
        insert contacts;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer C');

        System.assertEquals(
            5,
            updatedAccount.Contact_Count__c,
            'Contact count should be 5 after bulk insertion.'
        );
    }

    // 3. Positive: Delete a Contact
    @IsTest
    static void testDeleteContact() {

        Contact con = getContact('rahul@test.com');

        Test.startTest();
        delete con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            1,
            updatedAccount.Contact_Count__c,
            'Contact count should decrease from 2 to 1 after deletion.'
        );
    }

    // 4. Positive: Undelete a Contact
    @IsTest
    static void testUndeleteContact() {

        Contact con = getContact('rahul@test.com');

        Test.startTest();

        delete con;
        undelete con;

        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            2,
            updatedAccount.Contact_Count__c,
            'Contact count should return to 2 after undeleting the Contact.'
        );
    }

    // 5. Positive: Move Contact to another Account
    @IsTest
    static void testMoveContactToAnotherAccount() {

        Contact contactWithPrimary = getContact('rahul@test.com');
        Contact contactWithNonPrimary=getContact('neha@test.com');

        Account oldAccount = getAccount('Test Employer A');
        Account newAccount = getAccount('Test Employer B');

        contactWithPrimary.AccountId = newAccount.Id;
        contactWithPrimary.Is_Primary__c=false;
        contactWithNonPrimary.Is_Primary__c=true;
        contactWithNonPrimary.AccountId=oldAccount.Id;
        

        Test.startTest();
        update contactWithPrimary;
        update contactWithNonPrimary;
        

        Test.stopTest();

        Account updatedOldAccount = getAccount('Test Employer A');
        Account updatedNewAccount = getAccount('Test Employer B');

        System.assertEquals(
            1,
            updatedOldAccount.Contact_Count__c,
            'Old Account count should decrease from 2 to 1.'
        );

        System.assertEquals(
            2,
            updatedNewAccount.Contact_Count__c,
            'New Account count should increase from 1 to 2.'
        );
    }

    // 6. Positive: Update unrelated Contact field
    @IsTest
    static void testUpdateContactOtherField() {

        Contact con = getContact('rahul@test.com');

        con.FirstName = 'RahulUpdated';

        Test.startTest();
        update con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            2,
            updatedAccount.Contact_Count__c,
            'Contact count should remain unchanged after updating FirstName.'
        );
    }

    // 7. Positive: Delete all Contacts from an Account
    @IsTest
    static void testDeleteAllContacts() {

        List<Contact> contacts = [
            SELECT Id
            FROM Contact
            WHERE Account.Name = 'Test Employer A'
        ];

        Test.startTest();
        delete contacts;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            0,
            updatedAccount.Contact_Count__c,
            'Contact count should become zero after deleting all Contacts.'
        );
    }

    // 8. Positive: Bulk delete Contacts
    @IsTest
    static void testBulkDeleteContacts() {

        Account acc = getAccount('Test Employer C');

        List<Contact> contacts = new List<Contact>();

        for (Integer i = 1; i <= 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Employee' + i,
                LastName = 'Test',
                Email = 'bulkdelete' + i + '@test.com',
                AccountId = acc.Id,
                Is_Primary__c = false
            ));
        }

        insert contacts;

        List<Contact> contactsToDelete = [
            SELECT Id
            FROM Contact
            WHERE AccountId = :acc.Id
        ];

        Test.startTest();
        delete contactsToDelete;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer C');

        System.assertEquals(
            0,
            updatedAccount.Contact_Count__c,
            'Contact count should become zero after bulk deletion.'
        );
    }

    // 9. Negative: Insert Contact without Account
    @IsTest
    static void testInsertContactWithoutAccount() {

        Contact con = new Contact(
            FirstName = 'Karan',
            LastName = 'Mehta',
            Email = 'karan@test.com',
            Is_Primary__c = false
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        Contact insertedContact = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            null,
            insertedContact.AccountId,
            'Contact should be inserted without an Account.'
        );
    }

    // 10. Negative: Account with no Contacts
    @IsTest
    static void testInsertContactWithoutAccountDoesNotChangeOtherAccounts() {

        Account acc = getAccount('Test Employer D');

        Test.startTest();

        Contact con = new Contact(
            FirstName = 'Karan',
            LastName = 'Mehta',
            Email = 'karan2@test.com',
            Is_Primary__c = false
        );

        insert con;

        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer D');

        System.assertEquals(
            acc.Contact_Count__c,
            updatedAccount.Contact_Count__c,
            'An unrelated Account count should not change.'
        );
    }
}