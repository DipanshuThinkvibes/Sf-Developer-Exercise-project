
public with sharing class EntitlementService {

    public static void createEntitlements(List<Asset> newAssets) {

        List<Entitlement> entitlementsToInsert =new List<Entitlement>();
        List<Asset> eligibleAssets = new List<Asset>();
        Set<Id> assetIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();

        // 1. Collect Asset IDs and Order IDs
        for (Asset ast : newAssets) {

            if (ast.Id != null) {
                assetIds.add(ast.Id);
            }

            if (ast.Source_Order__c != null) {
                orderIds.add(ast.Source_Order__c);
            }
        }

        if (assetIds.isEmpty() || orderIds.isEmpty()) {
            return;
        }

        // 2. Get Opportunity IDs from Orders
        Set<Id> opportunityIds = new Set<Id>();

        Map<Id, Id> orderOpportunityMap = new Map<Id, Id>();

        for (Order ord : [SELECT Id, OpportunityId FROM Order WHERE Id IN :orderIds]) {
            if (ord.OpportunityId != null) {
                opportunityIds.add(ord.OpportunityId);
                orderOpportunityMap.put(ord.Id, ord.OpportunityId);
            }
        }
        if (opportunityIds.isEmpty()) {
            return;
        }

        // 3. Get Primary Support Contacts
        Map<Id, Set<Id>> opportunityContactMap =
            new Map<Id, Set<Id>>();

        for (OpportunityContactRole ocr : [SELECT Id, OpportunityId, ContactId,
                                            Contact.Name, Contact.Email
                                            FROM OpportunityContactRole
                                            WHERE OpportunityId IN :opportunityIds
                                            AND Role = 'Primary Support'])
        {
            if (!opportunityContactMap.containsKey(ocr.OpportunityId )) {
                opportunityContactMap.put(ocr.OpportunityId, new Set<Id>() );
            }
            opportunityContactMap.get(ocr.OpportunityId).add(ocr.ContactId);
        }

        // 4. Query Assets with Product details
        List<Asset> assets = [
            SELECT Id, Name, AccountId, Product2Id,
                   PurchaseDate, Source_Order__c,
                   Product2.POC__c
            FROM Asset
            WHERE Id IN :assetIds ];

        // 5. Create Entitlements
        for (Asset ast : assets) {

            if (ast.PurchaseDate == null ||ast.Source_Order__c == null) {
                continue;
            }

            Id opportunityId = orderOpportunityMap.get(ast.Source_Order__c );

            // POC = 90 days, Normal = 365 days
            Integer duration = ast.Product2.POC__c ? 90 : 365;

            Entitlement ent = new Entitlement();

            ent.Name = ast.Name.replace('Asset ', 'Ent ');
            ent.AccountId = ast.AccountId;
            ent.AssetId = ast.Id;
            ent.StartDate = ast.PurchaseDate;
            ent.EndDate = ast.PurchaseDate.addDays(duration);
            

            entitlementsToInsert.add(ent);

            // Keep Asset and Entitlement lists aligned
            eligibleAssets.add(ast);
        }

        if (entitlementsToInsert.isEmpty()) {
            return;
        }

        insert entitlementsToInsert;

        // 6. Associate Primary Support Contacts
        List<EntitlementContact> linksToInsert = new List<EntitlementContact>();

        for (Integer i = 0;i < entitlementsToInsert.size();i++) {

            Entitlement ent = entitlementsToInsert[i];

            Asset ast = eligibleAssets[i];

            Id opportunityId = orderOpportunityMap.get(ast.Source_Order__c);

            Set<Id> contactIds = opportunityContactMap.get(opportunityId);

            if (contactIds == null || contactIds.isEmpty()) {
                continue;
            }

            for (Id contactId : contactIds) {

                EntitlementContact link = new EntitlementContact();

                link.EntitlementId = ent.Id;
                link.ContactId = contactId;

                linksToInsert.add(link);
            }
        }

        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }
    }
}
