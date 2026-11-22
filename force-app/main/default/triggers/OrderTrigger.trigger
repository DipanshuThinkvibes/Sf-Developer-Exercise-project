trigger OrderTrigger on Order (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            OrderTriggerHandler.updateOrderStatus(Trigger.new,Trigger.oldMap);
            OrderShippingService.updateAssetStatus(Trigger.new, Trigger.oldMap);
            ContactDripCampaignService.updateContactDripCampaigns(Trigger.new, Trigger.oldMap);
            OrderShippingEmailService.sendShippingEmail(Trigger.new, Trigger.oldMap);
        }
    }

}