public with sharing class EmployerSearchController {

    @AuraEnabled
    public static List<Account> searchEmployers(
        String employerName,
        String domain,
        String industry,
        String billingCity
    ) {

        String query = 'SELECT Id, Name, Domain__c, Industry, BillingCity ' +
                       'FROM Account WHERE Id != null';

        if (String.isNotBlank(employerName)) {
            query += ' AND Name LIKE \'%' +
                     String.escapeSingleQuotes(employerName) + '%\'';
        }

        if (String.isNotBlank(domain)) {
            query += ' AND Domain__c = \'' +
                     String.escapeSingleQuotes(domain) + '\'';
        }

        if (String.isNotBlank(industry)) {
            query += ' AND Industry = \'' +
                     String.escapeSingleQuotes(industry) + '\'';
        }

        if (String.isNotBlank(billingCity)) {
            query += ' AND BillingCity LIKE \'%' +
                     String.escapeSingleQuotes(billingCity) + '%\'';
        }

        query += ' ORDER BY Name';

        return Database.query(query, AccessLevel.USER_MODE);
    }
}