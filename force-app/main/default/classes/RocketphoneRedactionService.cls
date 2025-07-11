/**
 * @description Integration service for Rocketphone AI redaction
 * @author AI Assistant
 * @version 1.0
 */
public with sharing class RocketphoneRedactionService {
    
    /**
     * @description Process Rocketphone call transcript with AI redaction
     * @param callId The Rocketphone call ID
     * @param transcriptText The original transcript text
     * @param redactionLevel The redaction level (basic, enhanced, strict)
     * @return String The transcript record ID
     */
    @AuraEnabled(cacheable=false)
    public static String processRocketphoneCall(String callId, String transcriptText, String redactionLevel) {
        try {
            // Validate inputs
            if (String.isBlank(callId)) {
                throw new IllegalArgumentException('Call ID cannot be empty');
            }
            
            if (String.isBlank(transcriptText)) {
                throw new IllegalArgumentException('Transcript text cannot be empty');
            }
            
            if (String.isBlank(redactionLevel)) {
                redactionLevel = 'Enhanced'; // Default to enhanced
            }
            
            // Create transcript record
            Transcript_Record__c record = new Transcript_Record__c();
            record.Original_Transcript__c = transcriptText;
            record.Rocketphone_Call_Id__c = callId;
            record.Redaction_Level__c = redactionLevel;
            record.Processing_Status__c = 'Processing';
            record.CreatedDate = Datetime.now();
            
            insert record;
            
            // Process with AI enhanced redaction
            AIEnhancedRedactionResult result = AIEnhancedRedactionService.enhancedRedact(transcriptText, redactionLevel);
            
            // Update record with results
            record.Redacted_Transcript__c = result.aiRedactedText;
            record.Processing_Status__c = 'Completed';
            record.Model_Used__c = 'AI Enhanced';
            record.Confidence_Score__c = result.confidenceScore;
            record.Processing_Time__c = result.processingTime;
            
            // Store AI analysis results
            if (result.redactionReport != null) {
                record.AI_Analysis_Results__c = JSON.serialize(result.redactionReport);
            }
            
            update record;
            
            // Log successful processing
            System.debug('Successfully processed call ' + callId + ' with confidence score: ' + result.confidenceScore);
            
            return record.Id;
            
        } catch (Exception e) {
            // Handle error and update record
            try {
                List<Transcript_Record__c> existingRecords = [
                    SELECT Id FROM Transcript_Record__c 
                    WHERE Rocketphone_Call_Id__c = :callId 
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                
                if (!existingRecords.isEmpty()) {
                    Transcript_Record__c record = existingRecords[0];
                    record.Processing_Status__c = 'Failed';
                    record.Error_Message__c = e.getMessage();
                    update record;
                }
            } catch (Exception updateError) {
                System.debug('Error updating failed record: ' + updateError.getMessage());
            }
            
            System.debug('Error processing call ' + callId + ': ' + e.getMessage());
            throw new AuraHandledException('Processing failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Process call with deep learning redaction
     * @param callId The Rocketphone call ID
     * @param transcriptText The original transcript text
     * @param modelType The model type (bert, gpt, ensemble)
     * @return String The transcript record ID
     */
    @AuraEnabled(cacheable=false)
    public static String processRocketphoneCallWithDeepLearning(String callId, String transcriptText, String modelType) {
        try {
            // Validate inputs
            if (String.isBlank(callId)) {
                throw new IllegalArgumentException('Call ID cannot be empty');
            }
            
            if (String.isBlank(transcriptText)) {
                throw new IllegalArgumentException('Transcript text cannot be empty');
            }
            
            if (String.isBlank(modelType)) {
                modelType = 'ensemble'; // Default to ensemble
            }
            
            // Create transcript record
            Transcript_Record__c record = new Transcript_Record__c();
            record.Original_Transcript__c = transcriptText;
            record.Rocketphone_Call_Id__c = callId;
            record.Redaction_Level__c = 'Deep Learning';
            record.Processing_Status__c = 'Processing';
            record.CreatedDate = Datetime.now();
            
            insert record;
            
            // Process with deep learning
            DeepLearningRedactionResult result = DeepLearningRedactionService.deepLearningRedact(transcriptText, modelType);
            
            // Update record with results
            record.Redacted_Transcript__c = result.redactedText;
            record.Processing_Status__c = 'Completed';
            record.Model_Used__c = 'Deep Learning - ' + modelType;
            record.Confidence_Score__c = result.modelConfidence;
            record.Processing_Time__c = result.processingTime;
            
            // Store accuracy metrics
            if (result.accuracyMetrics != null) {
                record.AI_Analysis_Results__c = JSON.serialize(result.accuracyMetrics);
            }
            
            update record;
            
            return record.Id;
            
        } catch (Exception e) {
            // Handle error
            try {
                List<Transcript_Record__c> existingRecords = [
                    SELECT Id FROM Transcript_Record__c 
                    WHERE Rocketphone_Call_Id__c = :callId 
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                
                if (!existingRecords.isEmpty()) {
                    Transcript_Record__c record = existingRecords[0];
                    record.Processing_Status__c = 'Failed';
                    record.Error_Message__c = e.getMessage();
                    update record;
                }
            } catch (Exception updateError) {
                System.debug('Error updating failed record: ' + updateError.getMessage());
            }
            
            throw new AuraHandledException('Deep learning processing failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get all transcripts for a specific call
     * @param callId The Rocketphone call ID
     * @return List<Transcript_Record__c> List of transcript records
     */
    @AuraEnabled(cacheable=true)
    public static List<Transcript_Record__c> getCallTranscripts(String callId) {
        try {
            return [
                SELECT Id, Name, Original_Transcript__c, Redacted_Transcript__c, 
                       Processing_Status__c, Redaction_Level__c, Confidence_Score__c,
                       Processing_Time__c, CreatedDate, AI_Analysis_Results__c,
                       Error_Message__c, Model_Used__c
                FROM Transcript_Record__c 
                WHERE Rocketphone_Call_Id__c = :callId 
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            System.debug('Error retrieving transcripts for call ' + callId + ': ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve transcripts: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get transcript processing statistics
     * @param callId The Rocketphone call ID
     * @return Map<String, Object> Processing statistics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProcessingStatistics(String callId) {
        Map<String, Object> stats = new Map<String, Object>();
        
        try {
            List<Transcript_Record__c> transcripts = [
                SELECT Processing_Status__c, Confidence_Score__c, Processing_Time__c,
                       Redaction_Level__c, Model_Used__c
                FROM Transcript_Record__c 
                WHERE Rocketphone_Call_Id__c = :callId
            ];
            
            Integer totalProcessed = 0;
            Integer totalCompleted = 0;
            Integer totalFailed = 0;
            Double totalConfidence = 0;
            Double totalTime = 0;
            
            for (Transcript_Record__c record : transcripts) {
                totalProcessed++;
                
                if (record.Processing_Status__c == 'Completed') {
                    totalCompleted++;
                    if (record.Confidence_Score__c != null) {
                        totalConfidence += record.Confidence_Score__c;
                    }
                    if (record.Processing_Time__c != null) {
                        totalTime += record.Processing_Time__c;
                    }
                } else if (record.Processing_Status__c == 'Failed') {
                    totalFailed++;
                }
            }
            
            stats.put('totalProcessed', totalProcessed);
            stats.put('totalCompleted', totalCompleted);
            stats.put('totalFailed', totalFailed);
            stats.put('successRate', totalProcessed > 0 ? (totalCompleted * 100.0 / totalProcessed) : 0);
            stats.put('avgConfidence', totalCompleted > 0 ? (totalConfidence / totalCompleted) : 0);
            stats.put('avgProcessingTime', totalCompleted > 0 ? (totalTime / totalCompleted) : 0);
            
        } catch (Exception e) {
            System.debug('Error calculating statistics: ' + e.getMessage());
            stats.put('error', e.getMessage());
        }
        
        return stats;
    }
    
    /**
     * @description Batch process multiple calls
     * @param callIds List of call IDs to process
     * @param redactionLevel The redaction level
     * @return List<String> List of transcript record IDs
     */
    @AuraEnabled(cacheable=false)
    public static List<String> batchProcessCalls(List<String> callIds, String redactionLevel) {
        List<String> recordIds = new List<String>();
        
        for (String callId : callIds) {
            try {
                // Get transcript for this call (you'll need to implement this based on your Rocketphone setup)
                String transcriptText = getTranscriptForCall(callId);
                
                if (String.isNotBlank(transcriptText)) {
                    String recordId = processRocketphoneCall(callId, transcriptText, redactionLevel);
                    recordIds.add(recordId);
                }
            } catch (Exception e) {
                System.debug('Error processing call ' + callId + ': ' + e.getMessage());
                // Continue with other calls
            }
        }
        
        return recordIds;
    }
    
    /**
     * @description Get transcript text for a specific call
     * @param callId The Rocketphone call ID
     * @return String The transcript text
     */
    private static String getTranscriptForCall(String callId) {
        // This method needs to be implemented based on your Rocketphone data structure
        // You might need to query a custom object or external system
        
        // Example implementation (adjust based on your setup):
        try {
            // Query your call object for transcript
            List<Call__c> calls = [SELECT Transcript__c FROM Call__c WHERE Id = :callId LIMIT 1];
            
            if (!calls.isEmpty() && String.isNotBlank(calls[0].Transcript__c)) {
                return calls[0].Transcript__c;
            }
        } catch (Exception e) {
            System.debug('Error retrieving transcript for call ' + callId + ': ' + e.getMessage());
        }
        
        return null;
    }
    
    /**
     * @description Get optimal model configuration for call processing
     * @param callId The Rocketphone call ID
     * @param useCase The use case (high_accuracy, fast_processing, cost_effective)
     * @return ModelSelectionResult The optimal model configuration
     */
    @AuraEnabled(cacheable=true)
    public static ModelSelectionResult getOptimalModelForCall(String callId, String useCase) {
        try {
            // Get transcript length for optimization
            String transcriptText = getTranscriptForCall(callId);
            Integer textLength = transcriptText != null ? transcriptText.length() : 1000;
            
            return AIModelConfigurationService.getOptimalModelConfiguration(useCase, textLength);
            
        } catch (Exception e) {
            System.debug('Error getting optimal model for call ' + callId + ': ' + e.getMessage());
            throw new AuraHandledException('Failed to get optimal model: ' + e.getMessage());
        }
    }
} 