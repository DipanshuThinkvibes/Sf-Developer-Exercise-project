
trigger AssetEntitlementTrigger on Asset (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        EntitlementService.createEntitlements(Trigger.new);
    }

}
