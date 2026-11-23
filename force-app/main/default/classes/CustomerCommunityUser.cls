
public with sharing class CustomerCommunityUser implements Queueable {
    // Store Contact IDs
    private List<Contact> contacts;
    public CustomerCommunityUser(List<Contact> contacts) {
        this.contacts = contacts;
    }
    public void execute(QueueableContext context) {
        set<Id> contactIds = new Set<Id>();
        for (Contact con : contacts) {
            if(String.isBlank(con.Email)) {
                continue;
            }
            contactIds.add(con.Id);
        }
        // Get Customer Community Login User Profile
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
        Set<Id> foundContactIds = new Set<Id>();

        List<User> existingUsers = [SELECT Id, ContactId, IsActive FROM User WHERE ContactId IN :contactIds AND ProfileId = :communityProfile.Id];
        List<User> usersToInsert = new List<User>();
        List<User> usersToActivate = new List<User>();

        // Check Existing Users
        for (User existingUser : existingUsers) {
            foundContactIds.add(existingUser.ContactId);
            // Activate Inactive Users
            if (!existingUser.IsActive) {
                existingUser.IsActive = true;
                usersToActivate.add(existingUser);
            }
        }
        // Create Users for Contacts Without Users
        for (Contact con : contacts) {
            if (foundContactIds.contains(con.Id)) {
                continue;
            }
            User newUser = new User();
            newUser.FirstName = con.FirstName;
            newUser.LastName = String.isBlank(con.LastName)? 'Unknown': con.LastName;
            newUser.Email = con.Email;
            newUser.Username =con.Email + '.' + String.valueOf(con.Id) +'@community.example.com';
            newUser.Alias = ('User' + String.valueOf(con.Id)).left(8);
            newUser.CommunityNickname ='User' + String.valueOf(con.Id);
            newUser.ProfileId = communityProfile.Id;
            newUser.ContactId = con.Id;
            newUser.IsActive = true;
            newUser.TimeZoneSidKey = 'Asia/Kolkata';
            newUser.LocaleSidKey = 'en_IN';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.LanguageLocaleKey = 'en_US';
            usersToInsert.add(newUser);
        }

        // Update Existing Inactive Users
        if (!usersToActivate.isEmpty()) {
            update usersToActivate;
        }

        // Insert New Community Users
        if (!usersToInsert.isEmpty()) {
            insert usersToInsert;
        }
    }
}
