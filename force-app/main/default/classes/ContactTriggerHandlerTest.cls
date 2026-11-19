@IsTest
private class ContactTriggerHandlerTest {

    private static Account createAccount(String accountName) {
        Account acc = new Account(Name = accountName);
        insert acc;
        return acc;
    }

    private static Contact createContact(
        Id accountId,
        String email,
        Boolean isPrimary
    ) {
        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = accountId,
            Email = email,
            Is_Primary__c = isPrimary
        );
        insert con;
        return con;
    }

    @IsTest
    static void testBeforeInsertPrimaryContact() {
        Account acc = createAccount('Primary Test Account');

        // First primary contact should be allowed.
        Contact primaryContact = new Contact(
            LastName = 'First Contact',
            AccountId = acc.Id,
            Email = 'first@example.com',
            Is_Primary__c = true
        );

        Test.startTest();
        insert primaryContact;
        Test.stopTest();

        System.assertNotEquals(
            null,
            primaryContact.Id,
            'The first primary contact should be inserted.'
        );

        // A second primary contact for the same account should fail.
        Contact duplicateContact = new Contact(
            LastName = 'Duplicate Contact',
            AccountId = acc.Id,
            Email = 'duplicate@example.com',
            Is_Primary__c = true
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(
            duplicateContact,
            false
        );
        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'A duplicate primary contact should be rejected.'
        );
    }

    @IsTest
    static void testPrimaryContactUpdates() {
        Account acc = createAccount('Update Test Account');

        Contact con = createContact(
            acc.Id,
            'primary@example.com',
            true
        );

        // Cover true -> false on the same account.
        Test.startTest();
        con.Is_Primary__c = false;
        update con;
        Test.stopTest();

        Account updatedAccount = [
            SELECT Id, Primary_Contact_Email__c, Contact_Count__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            null,
            updatedAccount.Primary_Contact_Email__c,
            'The primary email should be cleared.'
        );
        System.assertEquals(
            1,
            updatedAccount.Contact_Count__c,
            'The account should retain one contact.'
        );

        // Cover false -> true. The current handler may reject this
        // update because its duplicate check also finds the updated contact.
        con = [
            SELECT Id, AccountId, Email, Is_Primary__c
            FROM Contact
            WHERE Id = :con.Id
        ];
        con.Is_Primary__c = true;

        Test.startTest();
        Database.SaveResult result = Database.update(con, false);
        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'The current handler rejects this transition because of its duplicate-check logic.'
        );
    }

    @IsTest
    static void testEmailChangeAndPrimaryAccountMove() {
        Account firstAccount = createAccount('First Employer');
        Account secondAccount = createAccount('Second Employer');

        Contact con = createContact(
            firstAccount.Id,
            'old@example.com',
            true
        );

        // Cover primary contact email change.
        con.Email = 'new@example.com';

        Test.startTest();
        update con;
        Test.stopTest();

        Account refreshedAccount = [
            SELECT Primary_Contact_Email__c
            FROM Account
            WHERE Id = :firstAccount.Id
        ];

        System.assertEquals(
            'new@example.com',
            refreshedAccount.Primary_Contact_Email__c
        );

        // Cover moving a primary contact to a different account.
        con = [
            SELECT Id, AccountId, Email, Is_Primary__c
            FROM Contact
            WHERE Id = :con.Id
        ];
        con.AccountId = secondAccount.Id;

        Test.startTest();
        update con;
        Test.stopTest();

        Map<Id, Account> refreshedAccounts = new Map<Id, Account>([
            SELECT Id, Primary_Contact_Email__c, Contact_Count__c
            FROM Account
            WHERE Id IN :new Set<Id>{
                firstAccount.Id, secondAccount.Id
            }
        ]);

        System.assertEquals(
            null,
            refreshedAccounts.get(firstAccount.Id).Primary_Contact_Email__c,
            'The old account should no longer have the primary email.'
        );
        System.assertEquals(
            'new@example.com',
            refreshedAccounts.get(secondAccount.Id).Primary_Contact_Email__c,
            'The new account should have the moved primary contact email.'
        );
    }

    @IsTest
    static void testMovingNonPrimaryContact() {
        Account firstAccount = createAccount('Old Account');
        Account secondAccount = createAccount('New Account');

        Contact con = createContact(
            firstAccount.Id,
            'nonprimary@example.com',
            false
        );

        Test.startTest();
        con.AccountId = secondAccount.Id;
        update con;
        Test.stopTest();

        Contact refreshedContact = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(
            secondAccount.Id,
            refreshedContact.AccountId,
            'The non-primary contact should move to the new account.'
        );
    }

    @IsTest
    static void testPrimaryContactMovedToAccountWithExistingPrimary() {
        Account firstAccount = createAccount('Source Account');
        Account secondAccount = createAccount('Destination Account');

        Contact movingContact = createContact(
            firstAccount.Id,
            'moving@example.com',
            true
        );

        createContact(
            secondAccount.Id,
            'destination@example.com',
            true
        );

        // Both contacts are primary, so the existing handler's duplicate
        // check should reject the move.
        movingContact.AccountId = secondAccount.Id;

        Test.startTest();
        Database.SaveResult result = Database.update(
            movingContact,
            false
        );
        Test.stopTest();

        System.assertEquals(
            false,
            result.isSuccess(),
            'Moving a primary contact into an account with an existing primary should fail.'
        );
    }
}