@IsTest
private class ContactTriggerValidPrimaryHandlerTest {

    @TestSetup
    static void setupData() {

        List<Account> accounts = new List<Account>();

        for (Integer i = 1; i <= 5; i++) {
            accounts.add(new Account(
                Name = 'Test Employer ' + i
            ));
        }

        insert accounts;

        // Account 1: Existing Primary Contact
        // Account 2: Existing Primary Contact
        // Account 3: No Primary Contact
        // Account 4: No Primary Contact
        // Account 5: No Primary Contact

        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'Rahul',
                LastName = 'Sharma',
                Email = 'rahul@test.com',
                AccountId = accounts[0].Id,
                Is_Primary__c = true
            ),
            new Contact(
                FirstName = 'Amit',
                LastName = 'Verma',
                Email = 'amit@test.com',
                AccountId = accounts[1].Id,
                Is_Primary__c = true
            ),
            new Contact(
                FirstName = 'Neha',
                LastName = 'Gupta',
                Email = 'neha@test.com',
                AccountId = accounts[0].Id,
                Is_Primary__c = false
            ),
            new Contact(
                FirstName = 'Priya',
                LastName = 'Singh',
                Email = 'priya@test.com',
                AccountId = accounts[1].Id,
                Is_Primary__c = false
            )
        };

        insert contacts;
    }

    // Helper method to get Accounts.
    private static List<Account> getAccounts() {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Name LIKE 'Test Employer%'
            ORDER BY Name
        ];
    }

   
    // 1. Positive: Insert first Primary Contact.
   
    @IsTest
    static void testInsertFirstPrimaryContact() {

        Account acc = getAccounts()[2];

        Contact con = new Contact(
            FirstName = 'Karan',
            LastName = 'Mehta',
            AccountId = acc.Id,
            Is_Primary__c = true
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        Contact insertedContact = [
            SELECT Id, Is_Primary__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            true,
            insertedContact.Is_Primary__c,
            'First Primary Contact should be inserted successfully.'
        );
    }

   
    // 2. Negative: Insert duplicate Primary Contact.
   
    @IsTest
    static void testInsertDuplicatePrimaryContact() {

        Account acc = getAccounts()[0];

        Contact duplicateContact = new Contact(
            FirstName = 'Aman',
            LastName = 'Kumar',
            AccountId = acc.Id,
            Is_Primary__c = true
        );

        Test.startTest();

        Database.SaveResult result =
            Database.insert(duplicateContact, false);

        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'Duplicate Primary Contact should not be inserted.'
        );

        System.assert(
            result.getErrors().size() > 0,
            'An error should be returned.'
        );
    }

   
    // 3. Positive: Bulk insert Primary Contacts
    //    for different Accounts.
   
    @IsTest
    static void testBulkInsertDifferentAccounts() {

        List<Account> accounts = getAccounts();

        List<Contact> contacts = new List<Contact>();

        contacts.add(new Contact(
            FirstName = 'Person1',
            LastName = 'Test',
            AccountId = accounts[2].Id,
            Is_Primary__c = true
        ));

        contacts.add(new Contact(
            FirstName = 'Person2',
            LastName = 'Test',
            AccountId = accounts[3].Id,
            Is_Primary__c = true
        ));

        contacts.add(new Contact(
            FirstName = 'Person3',
            LastName = 'Test',
            AccountId = accounts[4].Id,
            Is_Primary__c = true
        ));

        Test.startTest();
        insert contacts;
        Test.stopTest();

        Integer countPrimary = [
            SELECT COUNT()
            FROM Contact
            WHERE AccountId IN :new Map<Id, Account>(accounts).keySet()
            AND Is_Primary__c = true
        ];

        System.assertEquals(
            5,
            countPrimary,
            'Each Account should have one Primary Contact.'
        );
    }

   
    // 4. Negative: Bulk insert duplicate Primary
    //    Contacts for the same Account.
   
    @IsTest
    static void testBulkInsertDuplicatePrimaryContacts() {

        Account acc = getAccounts()[1];

        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'First',
                LastName = 'Person',
                AccountId = acc.Id,
                Is_Primary__c = true
            ),
            new Contact(
                FirstName = 'Second',
                LastName = 'Person',
                AccountId = acc.Id,
                Is_Primary__c = true
            )
        };

        Test.startTest();

        Database.SaveResult[] results =
            Database.insert(contacts, false);

        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess());
        System.assertEquals(false, results[1].isSuccess());
    }

   
    // 5. Positive: Promote Non-Primary to Primary.
   
    @IsTest
    static void testPromoteNonPrimaryContact() {

        Contact con = [
            SELECT Id, AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'neha@test.com'
            LIMIT 1
        ];

        // Demote existing Primary Contact first.
        Contact existingPrimary = [
            SELECT Id, Is_Primary__c
            FROM Contact
            WHERE AccountId = :con.AccountId
            AND Is_Primary__c = true
            LIMIT 1
        ];

        existingPrimary.Is_Primary__c = false;

        Test.startTest();

        update existingPrimary;

        con.Is_Primary__c = true;
        update con;

        Test.stopTest();

        Contact updatedContact = [
            SELECT Is_Primary__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            true,
            updatedContact.Is_Primary__c,
            'Non-Primary Contact should be promoted successfully.'
        );
    }

   
    // 6. Negative: Promote when another Primary exists.
   
    @IsTest
    static void testPromoteDuplicatePrimaryContact() {

        Contact con = [
            SELECT Id, AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'neha@test.com'
            LIMIT 1
        ];

        con.Is_Primary__c = true;

        Test.startTest();

        Database.SaveResult result =
            Database.update(con, false);

        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'Promotion should fail when another Primary exists.'
        );
    }

   
    // 7. Positive: Demote one and promote another
    //    in the same bulk update.
   
    @IsTest
    static void testSwitchPrimaryContactInBulk() {

        Contact primaryContact = [
            SELECT Id, AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'rahul@test.com'
            LIMIT 1
        ];

        Contact nonPrimaryContact = [
            SELECT Id, AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'neha@test.com'
            LIMIT 1
        ];

        primaryContact.Is_Primary__c = false;
        nonPrimaryContact.Is_Primary__c = true;

        List<Contact> contacts = new List<Contact>{
            primaryContact,
            nonPrimaryContact
        };

        Test.startTest();

        Database.SaveResult[] results =
            Database.update(contacts, false);

        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess());
        System.assertEquals(true, results[1].isSuccess());
    }

   
    // 8. Positive: Update an existing Primary Contact
    //    without changing its Primary status.
   
    @IsTest
    static void testUpdateExistingPrimaryContact() {

        Contact con = [
            SELECT Id, FirstName, Is_Primary__c
            FROM Contact
            WHERE Email = 'rahul@test.com'
            LIMIT 1
        ];

        con.FirstName = 'RahulUpdated';

        Test.startTest();
        update con;
        Test.stopTest();

        Contact updatedContact = [
            SELECT FirstName, Is_Primary__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals('RahulUpdated', updatedContact.FirstName);
        System.assertEquals(true, updatedContact.Is_Primary__c);
    }

   
    // 9. Positive: Move Primary Contact to another
    //    Account which has no Primary Contact.
   
    @IsTest
    static void testMovePrimaryContactToAnotherAccount() {

        List<Account> accounts = getAccounts();

        Contact con = [
            SELECT Id, AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'rahul@test.com'
            LIMIT 1
        ];

        con.AccountId = accounts[3].Id;

        Test.startTest();
        update con;
        Test.stopTest();

        Contact updatedContact = [
            SELECT AccountId, Is_Primary__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(accounts[3].Id, updatedContact.AccountId);
        System.assertEquals(true, updatedContact.Is_Primary__c);
    }

   
    // 10. Negative: Move Primary Contact to an Account
    //     which already has a Primary Contact.
   
    @IsTest
    static void testMovePrimaryContactToOccupiedAccount() {

        List<Account> accounts = getAccounts();

        Contact con = [
            SELECT Id, AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'rahul@test.com'
            LIMIT 1
        ];

        con.AccountId = accounts[1].Id;

        Test.startTest();

        Database.SaveResult result =
            Database.update(con, false);

        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'Moving Primary Contact to an occupied Account should fail.'
        );
    }

   
    // 11. Positive: Bulk update where one Primary is
    // demoted and another remains Primary.
   
    @IsTest
    static void testBulkUpdatePrimaryStatus() {

        Contact primaryContact = [
            SELECT Id,AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'rahul@test.com'
            LIMIT 1
        ];

        Contact nonPrimaryContact = [
            SELECT Id,AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = 'neha@test.com'
            LIMIT 1
        ];

        primaryContact.Is_Primary__c = false;
        nonPrimaryContact.Is_Primary__c = false;

        Test.startTest();
        update new List<Contact>{
            primaryContact,
            nonPrimaryContact
        };
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Contact
                WHERE AccountId = :primaryContact.AccountId
                AND Is_Primary__c = true
            ],
            'Account should have no Primary Contact after both are demoted.'
        );
    }

   
    // 12. Positive: Contact without an Account.
   
    @IsTest
    static void testPrimaryContactWithoutAccount() {

        Contact con = new Contact(
            FirstName = 'NoAccount',
            LastName = 'Person',
            Is_Primary__c = true
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        System.assertNotEquals(
            null,
            con.Id,
            'Contact without Account should be inserted.'
        );
    }
}