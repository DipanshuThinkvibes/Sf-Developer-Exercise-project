@IsTest
private class ContactTriggerSyncPrimaryEmailTest {

    // Create common test data.
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

            // Primary Contact for Employer A
            new Contact(
                FirstName = 'Rahul',
                LastName = 'Sharma',
                Email = 'rahul@test.com',
                AccountId = accounts[0].Id,
                Is_Primary__c = true
            ),

            // Non-primary Contact for Employer A
            new Contact(
                FirstName = 'Neha',
                LastName = 'Gupta',
                Email = 'neha@test.com',
                AccountId = accounts[0].Id,
                Is_Primary__c = false
            ),

            // Primary Contact for Employer C
            new Contact(
                FirstName = 'Amit',
                LastName = 'Verma',
                Email = 'amit@test.com',
                AccountId = accounts[2].Id,
                Is_Primary__c = true
            )
        };

        insert contacts;
    }

    // Helper method to get Account.
    private static Account getAccount(String accountName) {
        return [
            SELECT Id, Name, Primary_Contact_Email__c
            FROM Account
            WHERE Name = :accountName
            LIMIT 1
        ];
    }

    // Helper method to get Contact.
    private static Contact getContact(String email) {
        return [
            SELECT Id, FirstName, LastName, Email,
                   AccountId, Is_Primary__c
            FROM Contact
            WHERE Email = :email
            LIMIT 1
        ];
    }

    // 1. Positive: Insert a Primary Contact.
    @IsTest
    static void testInsertPrimaryContact() {

        Account acc = getAccount('Test Employer B');

        Contact con = new Contact(
            FirstName = 'Priya',
            LastName = 'Singh',
            Email = 'priya@test.com',
            AccountId = acc.Id,
            Is_Primary__c = true
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer B');

        System.assertEquals(
            'priya@test.com',
            updatedAccount.Primary_Contact_Email__c,
            'Account email should be populated after inserting Primary Contact.'
        );
    }

    // 2. Negative: Insert a non-Primary Contact.
    @IsTest
    static void testInsertNonPrimaryContact() {

        Account acc = getAccount('Test Employer B');

        Contact con = new Contact(
            FirstName = 'Rohit',
            LastName = 'Kumar',
            Email = 'rohit@test.com',
            AccountId = acc.Id,
            Is_Primary__c = false
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer B');

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'Account email should remain null when a non-Primary Contact is inserted.'
        );
    }

    // 3. Positive: Promote a non-Primary Contact to Primary.
   @IsTest
static void testPromoteContactToPrimary() {

    Contact rahul = getContact('rahul@test.com');
    Contact neha = getContact('neha@test.com');

    Test.startTest();

    // First remove Rahul as Primary.
    rahul.Is_Primary__c = false;
    update rahul;

    // Then promote Neha.
    neha.Is_Primary__c = true;
    update neha;

    Test.stopTest();

    Account updatedAccount = getAccount('Test Employer A');

    System.assertEquals(
        'neha@test.com',
        updatedAccount.Primary_Contact_Email__c,
        'Account email should be updated after promoting Neha.'
    );
}

    // 4. Positive: Change the email of a Primary Contact.
    @IsTest
    static void testUpdatePrimaryContactEmail() {

        Contact con = getContact('rahul@test.com');

        con.Email = 'rahulupdated@test.com';

        Test.startTest();
        update con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            'rahulupdated@test.com',
            updatedAccount.Primary_Contact_Email__c,
            'Account email should reflect the updated Primary Contact email.'
        );
    }

    // 5. Negative: Change the email of a non-Primary Contact.
    @IsTest
    static void testUpdateNonPrimaryContactEmail() {

        Contact con = getContact('neha@test.com');

        con.Email = 'nehanew@test.com';

        Test.startTest();
        update con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            'rahul@test.com',
            updatedAccount.Primary_Contact_Email__c,
            'Changing a non-Primary Contact email should not change Account email.'
        );
    }

    // 6. Positive: Demote the Primary Contact.
    @IsTest
    static void testDemotePrimaryContact() {

        Contact con = getContact('rahul@test.com');

        con.Is_Primary__c = false;

        Test.startTest();
        update con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'Account email should become null when no Primary Contact remains.'
        );
    }

    // 7. Positive: Delete the Primary Contact.
    @IsTest
    static void testDeletePrimaryContact() {

        Contact con = getContact('rahul@test.com');

        Test.startTest();
        delete con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'Account email should become null after deleting its Primary Contact.'
        );
    }

    // 8. Positive: Undelete the Primary Contact.
    @IsTest
    static void testUndeletePrimaryContact() {

        Contact con = getContact('rahul@test.com');

        Test.startTest();

        delete con;
        undelete con;

        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            'rahul@test.com',
            updatedAccount.Primary_Contact_Email__c,
            'Account email should be restored after undeleting its Primary Contact.'
        );
    }

    // 9. Positive: Move a Primary Contact to another Account.
    @IsTest
    static void testMovePrimaryContactToAnotherAccount() {

        Contact con = getContact('rahul@test.com');

        Account oldAccount = getAccount('Test Employer A');
        Account newAccount = getAccount('Test Employer B');

        con.AccountId = newAccount.Id;

        Test.startTest();
        update con;
        Test.stopTest();

        Account updatedOldAccount = getAccount('Test Employer A');
        Account updatedNewAccount = getAccount('Test Employer B');

        System.assertEquals(
            null,
            updatedOldAccount.Primary_Contact_Email__c,
            'Old Account email should become null.'
        );

        System.assertEquals(
            'rahul@test.com',
            updatedNewAccount.Primary_Contact_Email__c,
            'New Account email should be updated.'
        );
    }

    // 10. Negative: Insert a Primary Contact without an Account.
    @IsTest
    static void testInsertPrimaryContactWithoutAccount() {

        Contact con = new Contact(
            FirstName = 'Karan',
            LastName = 'Mehta',
            Email = 'karan@test.com',
            Is_Primary__c = true
        );

        Test.startTest();
        insert con;
        Test.stopTest();

        Contact insertedContact = [
            SELECT Id, AccountId, Is_Primary__c
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            null,
            insertedContact.AccountId,
            'Contact should be inserted without an Account.'
        );

        System.assertEquals(
            true,
            insertedContact.Is_Primary__c,
            'Contact should retain its Primary status.'
        );
    }

    // 11. Negative: Update Primary Contact email to null.
    @IsTest
    static void testUpdatePrimaryContactEmailToNull() {

        Contact con = getContact('rahul@test.com');

        con.Email = null;

        Test.startTest();
        update con;
        Test.stopTest();

        Account updatedAccount = getAccount('Test Employer A');

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'Account email should become null when Primary Contact email is null.'
        );
    }

    // 12. Negative: Account has no Primary Contact.
    @IsTest
    static void testAccountWithoutPrimaryContact() {

        Account acc = getAccount('Test Employer D');

        System.assertEquals(
            null,
            acc.Primary_Contact_Email__c,
            'Account without Primary Contact should have a null Primary Contact Email.'
        );
    }
}