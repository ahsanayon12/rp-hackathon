/**
 * @description Trigger to automatically process Rocketphone calls with AI redaction
 * @author AI Assistant
 * @version 1.0
 */
trigger RocketphoneCallTrigger on Call__c (after insert, after update) {
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        List<Call__c> callsToProcess = new List<Call__c>();
        
        for (Call__c call : Trigger.new) {
            // Check if call has transcript and hasn't been processed yet
            if (String.isNotBlank(call.Transcript__c) && 
                (call.Redaction_Processed__c == false || call.Redaction_Processed__c == null)) {
                callsToProcess.add(call);
            }
        }
        
        if (!callsToProcess.isEmpty()) {
            // Queue the processing to avoid governor limits
            System.enqueueJob(new RocketphoneRedactionQueueable(callsToProcess));
        }
    }
}

/**
 * @description Queueable class to process Rocketphone calls with AI redaction
 */
public class RocketphoneRedactionQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Call__c> callsToProcess;
    
    public RocketphoneRedactionQueueable(List<Call__c> callsToProcess) {
        this.callsToProcess = callsToProcess;
    }
    
    public void execute(QueueableContext context) {
        List<Call__c> callsToUpdate = new List<Call__c>();
        
        for (Call__c call : callsToProcess) {
            try {
                // Process the call with AI redaction
                String recordId = RocketphoneRedactionService.processRocketphoneCall(
                    call.Id, 
                    call.Transcript__c, 
                    'Enhanced' // Default to enhanced redaction
                );
                
                // Mark call as processed
                call.Redaction_Processed__c = true;
                call.Redaction_Record_Id__c = recordId;
                callsToUpdate.add(call);
                
                System.debug('Successfully processed call ' + call.Id + ' with record ' + recordId);
                
            } catch (Exception e) {
                System.debug('Error processing call ' + call.Id + ': ' + e.getMessage());
                
                // Mark call as failed but don't prevent other calls from processing
                call.Redaction_Processed__c = false;
                call.Redaction_Error__c = e.getMessage();
                callsToUpdate.add(call);
            }
        }
        
        // Update the calls
        if (!callsToUpdate.isEmpty()) {
            try {
                update callsToUpdate;
            } catch (Exception e) {
                System.debug('Error updating calls: ' + e.getMessage());
            }
        }
    }
} 