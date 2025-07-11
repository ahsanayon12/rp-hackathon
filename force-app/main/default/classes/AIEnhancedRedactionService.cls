/**
 * @description AI-Enhanced Redaction Service using multiple AI models for intelligent PII detection
 * @author AI Assistant
 * @version 2.0
 */
public with sharing class AIEnhancedRedactionService {
    
    // Named credential for AI services
    private static final String OPENAI_CREDENTIAL = 'OpenAI_API';
    private static final String AZURE_CREDENTIAL = 'Azure_Cognitive_Services';
    
    // AI Models and endpoints
    private static final String OPENAI_MODEL = 'gpt-4';
    private static final String AZURE_LANGUAGE_ENDPOINT = 'https://api.cognitive.microsoft.com/text/analytics/v3.2/entities/recognition/general';
    
    // Redaction confidence thresholds
    private static final Double HIGH_CONFIDENCE_THRESHOLD = 0.85;
    private static final Double MEDIUM_CONFIDENCE_THRESHOLD = 0.70;
    
    /**
     * @description Enhanced redaction using multiple AI models
     * @param transcriptText The original transcript text
     * @param redactionLevel The level of redaction (basic, enhanced, strict)
     * @return AIEnhancedRedactionResult The redaction result with detailed analysis
     */
    @AuraEnabled(cacheable=false)
    public static AIEnhancedRedactionResult enhancedRedact(String transcriptText, String redactionLevel) {
        try {
            // Validate input
            if (String.isBlank(transcriptText)) {
                return createErrorResult('Transcript text cannot be empty');
            }
            
            if (String.isBlank(redactionLevel)) {
                redactionLevel = 'enhanced'; // Default to enhanced
            }
            
            AIEnhancedRedactionResult result = new AIEnhancedRedactionResult();
            result.originalText = transcriptText;
            result.redactionLevel = redactionLevel;
            result.timestamp = Datetime.now();
            
            // Step 1: Basic regex redaction (fast, reliable)
            String basicRedacted = performBasicRedaction(transcriptText);
            result.basicRedactedText = basicRedacted;
            
            // Step 2: AI-powered entity recognition
            List<AIEntity> aiEntities = detectEntitiesWithAI(transcriptText);
            result.detectedEntities = aiEntities;
            
            // Step 3: Context-aware redaction
            String aiRedacted = performContextAwareRedaction(basicRedacted, aiEntities, redactionLevel);
            result.aiRedactedText = aiRedacted;
            
            // Step 4: Confidence scoring
            result.confidenceScore = calculateConfidenceScore(aiEntities);
            
            // Step 5: Generate redaction report
            result.redactionReport = generateRedactionReport(aiEntities, redactionLevel);
            
            result.isSuccess = true;
            return result;
            
        } catch (Exception e) {
            System.debug('Error in enhancedRedact: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return createErrorResult('Enhanced redaction failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Performs basic regex-based redaction
     * @param text The text to redact
     * @return String The redacted text
     */
    private static String performBasicRedaction(String text) {
        String redactedText = text;
        
        // Enhanced regex patterns
        // Emails
        redactedText = redactedText.replaceAll('\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b', '[REDACTED EMAIL]');
        
        // Phone numbers (enhanced patterns)
        redactedText = redactedText.replaceAll('(\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4})|(\\+?1?[\\s.-]?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4})|(\\d{10,11})', '[REDACTED PHONE]');
        
        // Credit cards
        redactedText = redactedText.replaceAll('\\b(?:\\d{4}[\\s-]?){3}\\d{4}\\b|\\b\\d{4}[\\s-]?\\d{6}[\\s-]?\\d{5}\\b', '[REDACTED CARD]');
        
        // Social Security Numbers
        redactedText = redactedText.replaceAll('\\b\\d{3}-\\d{2}-\\d{4}\\b|\\b\\d{9}\\b', '[REDACTED SSN]');
        
        // IP Addresses
        redactedText = redactedText.replaceAll('\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b', '[REDACTED IP]');
        
        return redactedText;
    }
    
    /**
     * @description Detects entities using AI services
     * @param text The text to analyze
     * @return List<AIEntity> List of detected entities
     */
    private static List<AIEntity> detectEntitiesWithAI(String text) {
        List<AIEntity> entities = new List<AIEntity>();
        
        try {
            // Use OpenAI for entity detection
            String prompt = 'Analyze the following text and identify all personally identifiable information (PII). ' +
                          'Return the results in JSON format with the following structure: ' +
                          '{"entities": [{"text": "entity_text", "type": "entity_type", "confidence": 0.95, "start": 0, "end": 10}]} ' +
                          'Entity types should include: PERSON, EMAIL, PHONE, CREDIT_CARD, SSN, ADDRESS, ORGANIZATION, DATE, ACCOUNT_NUMBER. ' +
                          'Text to analyze: ' + text;
            
            String aiResponse = callOpenAI(prompt);
            entities = parseAIEntities(aiResponse);
            
            // Add Azure Cognitive Services for additional validation
            List<AIEntity> azureEntities = callAzureEntityRecognition(text);
            entities.addAll(azureEntities);
            
        } catch (Exception e) {
            System.debug('Error in detectEntitiesWithAI: ' + e.getMessage());
            // Fallback to basic entity detection
            entities = performBasicEntityDetection(text);
        }
        
        return entities;
    }
    
    /**
     * @description Performs context-aware redaction based on AI entities
     * @param basicRedactedText The text after basic redaction
     * @param entities The AI-detected entities
     * @param redactionLevel The redaction level
     * @return String The context-aware redacted text
     */
    private static String performContextAwareRedaction(String basicRedactedText, List<AIEntity> entities, String redactionLevel) {
        String redactedText = basicRedactedText;
        
        for (AIEntity entity : entities) {
            // Apply confidence-based redaction
            if (entity.confidence >= getConfidenceThreshold(redactionLevel)) {
                String redactionLabel = getRedactionLabel(entity.type);
                redactedText = redactedText.replace(entity.text, redactionLabel);
            }
        }
        
        return redactedText;
    }
    
    /**
     * @description Calls OpenAI API for entity detection
     * @param prompt The prompt to send
     * @return String The AI response
     */
    private static String callOpenAI(String prompt) {
        try {
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('model', OPENAI_MODEL);
            requestBody.put('max_tokens', 2000);
            requestBody.put('temperature', 0.1); // Low temperature for consistent results
            
            List<Map<String, String>> messages = new List<Map<String, String>>();
            Map<String, String> message = new Map<String, String>();
            message.put('role', 'user');
            message.put('content', prompt);
            messages.add(message);
            requestBody.put('messages', messages);
            
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + OPENAI_CREDENTIAL + '/v1/chat/completions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> choices = (List<Object>) responseMap.get('choices');
                
                if (choices != null && !choices.isEmpty()) {
                    Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
                    Map<String, Object> messageObj = (Map<String, Object>) firstChoice.get('message');
                    return (String) messageObj.get('content');
                }
            }
            
            throw new CalloutException('OpenAI API returned error: ' + res.getStatusCode());
            
        } catch (Exception e) {
            System.debug('Error calling OpenAI: ' + e.getMessage());
            throw new CalloutException('Failed to call OpenAI: ' + e.getMessage());
        }
    }
    
    /**
     * @description Calls Azure Cognitive Services for entity recognition
     * @param text The text to analyze
     * @return List<AIEntity> List of detected entities
     */
    private static List<AIEntity> callAzureEntityRecognition(String text) {
        List<AIEntity> entities = new List<AIEntity>();
        
        try {
            Map<String, Object> requestBody = new Map<String, Object>();
            List<Map<String, String>> documents = new List<Map<String, String>>();
            Map<String, String> document = new Map<String, String>();
            document.put('id', '1');
            document.put('text', text);
            documents.add(document);
            requestBody.put('documents', documents);
            
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + AZURE_CREDENTIAL + '/text/analytics/v3.2/entities/recognition/general');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> documentsList = (List<Object>) responseMap.get('documents');
                
                if (documentsList != null && !documentsList.isEmpty()) {
                    Map<String, Object> firstDoc = (Map<String, Object>) documentsList[0];
                    List<Object> entitiesList = (List<Object>) firstDoc.get('entities');
                    
                    for (Object entityObj : entitiesList) {
                        Map<String, Object> entityMap = (Map<String, Object>) entityObj;
                        AIEntity entity = new AIEntity();
                        entity.text = (String) entityMap.get('text');
                        entity.type = (String) entityMap.get('category');
                        entity.confidence = (Double) entityMap.get('confidenceScore');
                        entity.start = (Integer) entityMap.get('offset');
                        entity.end = entity.start + entity.text.length();
                        entities.add(entity);
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error calling Azure: ' + e.getMessage());
        }
        
        return entities;
    }
    
    /**
     * @description Parses AI entities from OpenAI response
     * @param aiResponse The AI response
     * @return List<AIEntity> List of parsed entities
     */
    private static List<AIEntity> parseAIEntities(String aiResponse) {
        List<AIEntity> entities = new List<AIEntity>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(aiResponse);
            List<Object> entitiesList = (List<Object>) responseMap.get('entities');
            
            if (entitiesList != null) {
                for (Object entityObj : entitiesList) {
                    Map<String, Object> entityMap = (Map<String, Object>) entityObj;
                    AIEntity entity = new AIEntity();
                    entity.text = (String) entityMap.get('text');
                    entity.type = (String) entityMap.get('type');
                    entity.confidence = (Double) entityMap.get('confidence');
                    entity.start = (Integer) entityMap.get('start');
                    entity.end = (Integer) entityMap.get('end');
                    entities.add(entity);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error parsing AI entities: ' + e.getMessage());
        }
        
        return entities;
    }
    
    /**
     * @description Performs basic entity detection as fallback
     * @param text The text to analyze
     * @return List<AIEntity> List of detected entities
     */
    private static List<AIEntity> performBasicEntityDetection(String text) {
        List<AIEntity> entities = new List<AIEntity>();
        
        // Simple pattern matching for common PII
        Pattern emailPattern = Pattern.compile('\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b');
        Matcher emailMatcher = emailPattern.matcher(text);
        
        while (emailMatcher.find()) {
            AIEntity entity = new AIEntity();
            entity.text = emailMatcher.group();
            entity.type = 'EMAIL';
            entity.confidence = 0.95;
            entity.start = emailMatcher.start();
            entity.end = emailMatcher.end();
            entities.add(entity);
        }
        
        return entities;
    }
    
    /**
     * @description Gets confidence threshold based on redaction level
     * @param redactionLevel The redaction level
     * @return Double The confidence threshold
     */
    private static Double getConfidenceThreshold(String redactionLevel) {
        switch on redactionLevel.toLowerCase() {
            when 'strict' {
                return 0.60; // Lower threshold for strict redaction
            }
            when 'enhanced' {
                return MEDIUM_CONFIDENCE_THRESHOLD;
            }
            when 'basic' {
                return HIGH_CONFIDENCE_THRESHOLD;
            }
            when else {
                return MEDIUM_CONFIDENCE_THRESHOLD;
            }
        }
    }
    
    /**
     * @description Gets redaction label for entity type
     * @param entityType The entity type
     * @return String The redaction label
     */
    private static String getRedactionLabel(String entityType) {
        switch on entityType.toUpperCase() {
            when 'PERSON' {
                return '[REDACTED NAME]';
            }
            when 'EMAIL' {
                return '[REDACTED EMAIL]';
            }
            when 'PHONE' {
                return '[REDACTED PHONE]';
            }
            when 'CREDIT_CARD' {
                return '[REDACTED CARD]';
            }
            when 'SSN' {
                return '[REDACTED SSN]';
            }
            when 'ADDRESS' {
                return '[REDACTED ADDRESS]';
            }
            when 'ORGANIZATION' {
                return '[REDACTED ORGANIZATION]';
            }
            when 'ACCOUNT_NUMBER' {
                return '[REDACTED ACCOUNT]';
            }
            when else {
                return '[REDACTED PII]';
            }
        }
    }
    
    /**
     * @description Calculates confidence score for the redaction
     * @param entities The detected entities
     * @return Double The confidence score
     */
    private static Double calculateConfidenceScore(List<AIEntity> entities) {
        if (entities.isEmpty()) {
            return 0.0;
        }
        
        Double totalConfidence = 0.0;
        for (AIEntity entity : entities) {
            totalConfidence += entity.confidence;
        }
        
        return totalConfidence / entities.size();
    }
    
    /**
     * @description Generates a detailed redaction report
     * @param entities The detected entities
     * @param redactionLevel The redaction level
     * @return Map<String, Object> The redaction report
     */
    private static Map<String, Object> generateRedactionReport(List<AIEntity> entities, String redactionLevel) {
        Map<String, Object> report = new Map<String, Object>();
        
        // Count entities by type
        Map<String, Integer> entityCounts = new Map<String, Integer>();
        for (AIEntity entity : entities) {
            String type = entity.type.toUpperCase();
            entityCounts.put(type, entityCounts.containsKey(type) ? entityCounts.get(type) + 1 : 1);
        }
        
        report.put('total_entities', entities.size());
        report.put('entity_counts', entityCounts);
        report.put('redaction_level', redactionLevel);
        report.put('timestamp', Datetime.now());
        
        return report;
    }
    
    /**
     * @description Creates an error result
     * @param errorMessage The error message
     * @return AIEnhancedRedactionResult The error result
     */
    private static AIEnhancedRedactionResult createErrorResult(String errorMessage) {
        AIEnhancedRedactionResult result = new AIEnhancedRedactionResult();
        result.isSuccess = false;
        result.errorMessage = errorMessage;
        result.timestamp = Datetime.now();
        return result;
    }
    
    /**
     * @description Test method for enhanced redaction
     * @return AIEnhancedRedactionResult Sample result
     */
    @AuraEnabled(cacheable=true)
    public static AIEnhancedRedactionResult getSampleEnhancedRedaction() {
        String sampleText = 'Customer John Smith (john.smith@example.com) called about their order. ' +
                           'Phone: (555) 123-4567, Card: 1234-5678-9012-3456. ' +
                           'SSN: 123-45-6789. Address: 123 Main St, Anytown, USA.';
        
        return enhancedRedact(sampleText, 'enhanced');
    }
    
    /**
     * @description AI Entity wrapper class
     */
    public class AIEntity {
        @AuraEnabled public String text;
        @AuraEnabled public String type;
        @AuraEnabled public Double confidence;
        @AuraEnabled public Integer start;
        @AuraEnabled public Integer end;
    }
    
    /**
     * @description Enhanced redaction result wrapper class
     */
    public class AIEnhancedRedactionResult {
        @AuraEnabled public String originalText;
        @AuraEnabled public String basicRedactedText;
        @AuraEnabled public String aiRedactedText;
        @AuraEnabled public String redactionLevel;
        @AuraEnabled public List<AIEntity> detectedEntities;
        @AuraEnabled public Double confidenceScore;
        @AuraEnabled public Map<String, Object> redactionReport;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Datetime timestamp;
    }
} 