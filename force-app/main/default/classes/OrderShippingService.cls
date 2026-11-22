public with sharing class OrderShippingService {

    public static void updateAssetStatus( List<Order> newOrders, Map<Id, Order> oldOrderMap ) {
        Set<Id> shippedOrderIds = new Set<Id>();
        Map<Id, Date> orderShipDateMap = new Map<Id, Date>();

        // Find Orders whose status changed to Shipped
        for (Order ord : newOrders) {
            Order oldOrd = oldOrderMap.get(ord.Id);

            if (oldOrd.Status != 'Shipped' && ord.Status == 'Shipped') {
                shippedOrderIds.add(ord.Id);
               orderShipDateMap.put(ord.Id,ord.Ship_Date__c != null? ord.Ship_Date__c: Date.today());
            }
        }

        if (shippedOrderIds.isEmpty()) {
            return;
        }

        // Get Assets associated with these Orders
        List<Asset> assetsToUpdate = new List<Asset>();

        for (Asset ast : [
            SELECT Id, Status, Actual_Ship_Date__c,
                   Source_Order__c
            FROM Asset
            WHERE Source_Order__c IN :shippedOrderIds
        ]) {

            ast.Status = 'Shipped';

            ast.Actual_Ship_Date__c = orderShipDateMap.get(ast.Source_Order__c);

            assetsToUpdate.add(ast);
        }

        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
    }
}