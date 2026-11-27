public with sharing class OrderTriggerHandler {
    public static void updateOrderStatus(List<Order> newOrders,Map<Id, Order> oldOrderMap) {
    
       Set<Id> accountIds=new Set<Id>();
       for(Order ord:newOrders){
           if(ord.Status=='Activated'){
               accountIds.add(ord.AccountId);
           }
        }
     
        // 1. Collect Orders that have just been activated.
        Map<Id, Order> activatedOrders = new Map<Id, Order>();

        for (Order ord : newOrders) {

            Order oldOrd = oldOrderMap.get(ord.Id);

            if (oldOrd.Status != 'Activated' && ord.Status == 'Activated' ) {
                activatedOrders.put(ord.Id, ord);
            }
        }

        if (activatedOrders.isEmpty()) {
            return;
        }

        // 2. Get all Order Products.
       List<OrderItem> orderItems = [
    SELECT Id,
           OrderId,
           Quantity,
           UnitPrice,
           Product2Id,
           Product2.Name,
           Product2.ProductCode,
           Product2.Family
    FROM OrderItem
    WHERE OrderId IN :activatedOrders.keySet()
    AND Order.AccountId IN :accountIds
];

        // 3. Find Assets already created for these Orders.
        List<Asset> existingAssets = [
            SELECT Id, Source_Order__c, Product2Id
            FROM Asset
            WHERE Source_Order__c IN :activatedOrders.keySet()
        ];

        // Count existing Assets for each Order and Product.
        Map<String, Integer> existingCounts = new Map<String, Integer>();
        for (Asset asset : existingAssets) {

            String key = String.valueOf(asset.Source_Order__c)
                       + '-' + String.valueOf(asset.Product2Id);

            Integer count = existingCounts.containsKey(key)
                ? existingCounts.get(key)
                : 0;

            existingCounts.put(key, count + 1);
        }

        // 4. Prepare new Assets.
        List<Asset> assetsToInsert = new List<Asset>();

        for (OrderItem item : orderItems) {
            if (item.Product2.Family != 'Software') {
                continue;
            }


            Order ord = activatedOrders.get(item.OrderId);

            String key = String.valueOf(item.OrderId)
                       + '-' + String.valueOf(item.Product2Id);

            Integer alreadyCreated = existingCounts.containsKey(key)
                ? existingCounts.get(key)
                : 0;

            Integer requiredQuantity = item.Quantity.intValue();

            String orderName = ord.OrderNumber;

            for (Integer i = alreadyCreated + 1;i <= requiredQuantity;i++
            ) {

                Asset newAsset = new Asset();

                newAsset.Name =
                    'Asset ' + orderName + ' ' +
                    item.Product2.ProductCode + ' - ' + i;

                newAsset.AccountId = ord.AccountId;
                newAsset.Product2Id = item.Product2Id;
                newAsset.Quantity = 1;
                newAsset.Price = item.UnitPrice;

                newAsset.PurchaseDate =
                    ord.ActivatedDate.date();

                newAsset.Status = 'Purchased';

                newAsset.Source_Order__c = ord.Id;

                assetsToInsert.add(newAsset);
                 alreadyCreated++;
            }
            existingCounts.put(key, alreadyCreated);
        }

        // 5. Insert all Assets together.
        if (!assetsToInsert.isEmpty()) {
            insert assetsToInsert;
        }
    }
}