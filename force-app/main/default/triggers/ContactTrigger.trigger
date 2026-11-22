
trigger ContactTrigger on Contact (before insert,before update,after insert,after update,after delete,after undelete) {

    // BEFORE EVENTS
    if (Trigger.isBefore) {

        // Rule 1: Validate Primary Contact during insert.
        if (Trigger.isInsert) {
           ContactTriggerValidPrimaryHandler.checkInsertedPrimaryContact(Trigger.new);
        }

        // Rule 1: Validate Primary Contact during update.
        if (Trigger.isUpdate) {
            ContactTriggerValidPrimaryHandler.checkUpdatedPrimaryContact(Trigger.oldMap,Trigger.new);
        }
    }

    // AFTER EVENTS
    if (Trigger.isAfter) {

        // After Insert
        if (Trigger.isInsert) {

            // Rule 2: Synchronize Primary Contact Email.
            ContactTriggerSyncPrimaryEmail.syncPrimaryContactEmail(Trigger.new,null);

            // Rule 3: Synchronize Contact Count.
            ContactTriggerSyncCount.updateContactCount(Trigger.new,null);
        }

        // After Update
        if (Trigger.isUpdate) {

            // Rule 2: Synchronize Primary Contact Email.
            ContactTriggerSyncPrimaryEmail.syncPrimaryContactEmail(Trigger.new,Trigger.old);

            // Rule 3: Synchronize Contact Count.
            ContactTriggerSyncCount.updateContactCount(Trigger.new,Trigger.old);
        }

        // After Delete
        if (Trigger.isDelete) {

            // Rule 2: Synchronize Primary Contact Email.
            ContactTriggerSyncPrimaryEmail.syncPrimaryContactEmail(null,Trigger.old);

            // Rule 3: Synchronize Contact Count.
            ContactTriggerSyncCount.updateContactCount(null,Trigger.old);
        }

        // After Undelete
        if (Trigger.isUndelete) {

            // Rule 2: Synchronize Primary Contact Email.
            ContactTriggerSyncPrimaryEmail.syncPrimaryContactEmail(Trigger.new,null);

            // Rule 3: Synchronize Contact Count.
            ContactTriggerSyncCount.updateContactCount(Trigger.new,null);
        }
    }
}
