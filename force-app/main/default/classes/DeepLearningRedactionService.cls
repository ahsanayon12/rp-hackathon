/**
 * @description Deep Learning Redaction Service using external ML models for advanced PII detection
 * @author AI Assistant
 * @version 1.0
 */
public with sharing class DeepLearningRedactionService {
    
    // Named credentials for ML services
    private static final String HUGGINGFACE_CREDENTIAL = 'HuggingFace_API';
    private static final String GOOGLE_ML_CREDENTIAL = 'Google_ML_API';
    private static final String AWS_COMPREHEND_CREDENTIAL = 'AWS_Comprehend';
    
    // ML Model endpoints
    private static final String HUGGINGFACE_ENDPOINT = 'https://api-inference.huggingface.co/models/';
    private static final String GOOGLE_ML_ENDPOINT = 'https://ml.googleapis.com/v1/projects/';
    private static final String AWS_COMPREHEND_ENDPOINT = 'https://comprehend.amazonaws.com/';
    
    // Model configurations
    private static final String NER_MODEL = 'dbmdz/bert-large-cased-finetuned-conll03-english';
    private static final String PII_DETECTION_MODEL = 'microsoft/DialoGPT-medium';
    
    /**
     * @description Advanced redaction using deep learning models
     * @param transcriptText The original transcript text
     * @param modelType The type of ML model to use (bert, gpt, ensemble)
     * @return DeepLearningRedactionResult The redaction result with ML insights
     */
    @AuraEnabled(cacheable=false)
    public static DeepLearningRedactionResult deepLearningRedact(String transcriptText, String modelType) {
        try {
            // Validate input
            if (String.isBlank(transcriptText)) {
                return createErrorResult('Transcript text cannot be empty');
            }
            
            if (String.isBlank(modelType)) {
                modelType = 'ensemble'; // Default to ensemble approach
            }
            
            DeepLearningRedactionResult result = new DeepLearningRedactionResult();
            result.originalText = transcriptText;
            result.modelType = modelType;
            result.timestamp = Datetime.now();
            
            // Step 1: Preprocess text for ML models
            String preprocessedText = preprocessText(transcriptText);
            result.preprocessedText = preprocessedText;
            
            // Step 2: Run ML model inference
            List<MLPrediction> predictions = runMLInference(preprocessedText, modelType);
            result.mlPredictions = predictions;
            
            // Step 3: Apply ensemble voting for better accuracy
            List<EnsembleEntity> ensembleEntities = applyEnsembleVoting(predictions);
            result.ensembleEntities = ensembleEntities;
            
            // Step 4: Generate redacted text
            String redactedText = generateRedactedText(transcriptText, ensembleEntities);
            result.redactedText = redactedText;
            
            // Step 5: Calculate model confidence and accuracy
            result.modelConfidence = calculateModelConfidence(predictions);
            result.accuracyMetrics = calculateAccuracyMetrics(ensembleEntities);
            
            result.isSuccess = true;
            return result;
            
        } catch (Exception e) {
            System.debug('Error in deepLearningRedact: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return createErrorResult('Deep learning redaction failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Preprocesses text for ML models
     * @param text The text to preprocess
     * @return String The preprocessed text
     */
    private static String preprocessText(String text) {
        // Clean and normalize text for ML models
        String preprocessed = text;
        
        // Remove extra whitespace
        preprocessed = preprocessed.replaceAll('\\s+', ' ').trim();
        
        // Normalize quotes and apostrophes
        preprocessed = preprocessed.replaceAll('[''']', "'");
        preprocessed = preprocessed.replaceAll('[""]', '"');
        
        // Handle special characters
        preprocessed = preprocessed.replaceAll('[^\x00-\x7F]', '');
        
        return preprocessed;
    }
    
    /**
     * @description Runs ML model inference
     * @param text The preprocessed text
     * @param modelType The model type
     * @return List<MLPrediction> List of ML predictions
     */
    private static List<MLPrediction> runMLInference(String text, String modelType) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        try {
            switch on modelType.toLowerCase() {
                when 'bert' {
                    predictions = callBERTModel(text);
                }
                when 'gpt' {
                    predictions = callGPTModel(text);
                }
                when 'ensemble' {
                    // Run multiple models and combine results
                    List<MLPrediction> bertPredictions = callBERTModel(text);
                    List<MLPrediction> gptPredictions = callGPTModel(text);
                    List<MLPrediction> awsPredictions = callAWSComprehend(text);
                    
                    predictions.addAll(bertPredictions);
                    predictions.addAll(gptPredictions);
                    predictions.addAll(awsPredictions);
                }
                when else {
                    predictions = callBERTModel(text); // Default to BERT
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in runMLInference: ' + e.getMessage());
            // Fallback to basic prediction
            predictions = createBasicPredictions(text);
        }
        
        return predictions;
    }
    
    /**
     * @description Calls BERT model for NER
     * @param text The text to analyze
     * @return List<MLPrediction> BERT predictions
     */
    private static List<MLPrediction> callBERTModel(String text) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        try {
            // Prepare request for HuggingFace BERT model
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('inputs', text);
            
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + HUGGINGFACE_CREDENTIAL + '/' + NER_MODEL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(60000); // 60 seconds for ML inference
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                List<Object> responseList = (List<Object>) JSON.deserializeUntyped(res.getBody());
                predictions = parseBERTResponse(responseList, text);
            }
            
        } catch (Exception e) {
            System.debug('Error calling BERT model: ' + e.getMessage());
        }
        
        return predictions;
    }
    
    /**
     * @description Calls GPT model for PII detection
     * @param text The text to analyze
     * @return List<MLPrediction> GPT predictions
     */
    private static List<MLPrediction> callGPTModel(String text) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        try {
            // Use OpenAI GPT for PII detection
            String prompt = 'Analyze the following text and identify all personally identifiable information (PII). ' +
                          'Return the results in JSON format with the following structure: ' +
                          '{"entities": [{"text": "entity_text", "type": "entity_type", "confidence": 0.95, "start": 0, "end": 10}]} ' +
                          'Text to analyze: ' + text;
            
            String aiResponse = callOpenAI(prompt);
            predictions = parseGPTResponse(aiResponse, text);
            
        } catch (Exception e) {
            System.debug('Error calling GPT model: ' + e.getMessage());
        }
        
        return predictions;
    }
    
    /**
     * @description Calls AWS Comprehend for entity recognition
     * @param text The text to analyze
     * @return List<MLPrediction> AWS predictions
     */
    private static List<MLPrediction> callAWSComprehend(String text) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        try {
            // Prepare request for AWS Comprehend
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('Text', text);
            requestBody.put('LanguageCode', 'en');
            
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + AWS_COMPREHEND_CREDENTIAL + '/detect-entities');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Amz-Target', 'Comprehend_20171127.DetectEntities');
            req.setBody(jsonBody);
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                predictions = parseAWSResponse(responseMap, text);
            }
            
        } catch (Exception e) {
            System.debug('Error calling AWS Comprehend: ' + e.getMessage());
        }
        
        return predictions;
    }
    
    /**
     * @description Calls OpenAI API
     * @param prompt The prompt to send
     * @return String The AI response
     */
    private static String callOpenAI(String prompt) {
        try {
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('model', 'gpt-4');
            requestBody.put('max_tokens', 2000);
            requestBody.put('temperature', 0.1);
            
            List<Map<String, String>> messages = new List<Map<String, String>>();
            Map<String, String> message = new Map<String, String>();
            message.put('role', 'user');
            message.put('content', prompt);
            messages.add(message);
            requestBody.put('messages', messages);
            
            String jsonBody = JSON.serialize(requestBody);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:OpenAI_API/v1/chat/completions');
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
     * @description Parses BERT model response
     * @param responseList The BERT response
     * @param originalText The original text
     * @return List<MLPrediction> Parsed predictions
     */
    private static List<MLPrediction> parseBERTResponse(List<Object> responseList, String originalText) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        try {
            for (Object responseObj : responseList) {
                Map<String, Object> responseMap = (Map<String, Object>) responseObj;
                String entity = (String) responseMap.get('entity_group');
                String word = (String) responseMap.get('word');
                Double score = (Double) responseMap.get('score');
                
                if (score > 0.7) { // Confidence threshold
                    MLPrediction prediction = new MLPrediction();
                    prediction.text = word;
                    prediction.type = mapBERTEntityToPII(entity);
                    prediction.confidence = score;
                    prediction.model = 'BERT';
                    predictions.add(prediction);
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing BERT response: ' + e.getMessage());
        }
        
        return predictions;
    }
    
    /**
     * @description Parses GPT response
     * @param aiResponse The GPT response
     * @param originalText The original text
     * @return List<MLPrediction> Parsed predictions
     */
    private static List<MLPrediction> parseGPTResponse(String aiResponse, String originalText) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(aiResponse);
            List<Object> entitiesList = (List<Object>) responseMap.get('entities');
            
            if (entitiesList != null) {
                for (Object entityObj : entitiesList) {
                    Map<String, Object> entityMap = (Map<String, Object>) entityObj;
                    MLPrediction prediction = new MLPrediction();
                    prediction.text = (String) entityMap.get('text');
                    prediction.type = (String) entityMap.get('type');
                    prediction.confidence = (Double) entityMap.get('confidence');
                    prediction.model = 'GPT';
                    predictions.add(prediction);
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing GPT response: ' + e.getMessage());
        }
        
        return predictions;
    }
    
    /**
     * @description Parses AWS Comprehend response
     * @param responseMap The AWS response
     * @param originalText The original text
     * @return List<MLPrediction> Parsed predictions
     */
    private static List<MLPrediction> parseAWSResponse(Map<String, Object> responseMap, String originalText) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        try {
            List<Object> entitiesList = (List<Object>) responseMap.get('Entities');
            
            if (entitiesList != null) {
                for (Object entityObj : entitiesList) {
                    Map<String, Object> entityMap = (Map<String, Object>) entityObj;
                    MLPrediction prediction = new MLPrediction();
                    prediction.text = (String) entityMap.get('Text');
                    prediction.type = (String) entityMap.get('Type');
                    prediction.confidence = (Double) entityMap.get('Score');
                    prediction.model = 'AWS_Comprehend';
                    predictions.add(prediction);
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing AWS response: ' + e.getMessage());
        }
        
        return predictions;
    }
    
    /**
     * @description Maps BERT entity types to PII categories
     * @param bertEntity The BERT entity type
     * @return String The PII category
     */
    private static String mapBERTEntityToPII(String bertEntity) {
        switch on bertEntity.toUpperCase() {
            when 'PER' {
                return 'PERSON';
            }
            when 'ORG' {
                return 'ORGANIZATION';
            }
            when 'LOC' {
                return 'LOCATION';
            }
            when 'MISC' {
                return 'MISC';
            }
            when else {
                return 'UNKNOWN';
            }
        }
    }
    
    /**
     * @description Applies ensemble voting to combine predictions
     * @param predictions List of all predictions
     * @return List<EnsembleEntity> Ensemble results
     */
    private static List<EnsembleEntity> applyEnsembleVoting(List<MLPrediction> predictions) {
        List<EnsembleEntity> ensembleEntities = new List<EnsembleEntity>();
        Map<String, List<MLPrediction>> groupedPredictions = new Map<String, List<MLPrediction>>();
        
        // Group predictions by text
        for (MLPrediction prediction : predictions) {
            String key = prediction.text.toLowerCase();
            if (!groupedPredictions.containsKey(key)) {
                groupedPredictions.put(key, new List<MLPrediction>());
            }
            groupedPredictions.get(key).add(prediction);
        }
        
        // Apply voting for each group
        for (String text : groupedPredictions.keySet()) {
            List<MLPrediction> groupPredictions = groupedPredictions.get(text);
            
            // Calculate ensemble confidence
            Double totalConfidence = 0.0;
            Map<String, Integer> typeVotes = new Map<String, Integer>();
            
            for (MLPrediction pred : groupPredictions) {
                totalConfidence += pred.confidence;
                String type = pred.type.toUpperCase();
                typeVotes.put(type, typeVotes.containsKey(type) ? typeVotes.get(type) + 1 : 1);
            }
            
            // Find most voted type
            String ensembleType = '';
            Integer maxVotes = 0;
            for (String type : typeVotes.keySet()) {
                if (typeVotes.get(type) > maxVotes) {
                    maxVotes = typeVotes.get(type);
                    ensembleType = type;
                }
            }
            
            // Create ensemble entity
            EnsembleEntity entity = new EnsembleEntity();
            entity.text = groupPredictions[0].text; // Use first prediction's text
            entity.type = ensembleType;
            entity.confidence = totalConfidence / groupPredictions.size();
            entity.voteCount = maxVotes;
            entity.totalModels = groupPredictions.size();
            
            ensembleEntities.add(entity);
        }
        
        return ensembleEntities;
    }
    
    /**
     * @description Generates redacted text from ensemble entities
     * @param originalText The original text
     * @param entities The ensemble entities
     * @return String The redacted text
     */
    private static String generateRedactedText(String originalText, List<EnsembleEntity> entities) {
        String redactedText = originalText;
        
        for (EnsembleEntity entity : entities) {
            if (entity.confidence >= 0.7 && entity.voteCount >= 2) { // High confidence and multiple model agreement
                String redactionLabel = getRedactionLabel(entity.type);
                redactedText = redactedText.replace(entity.text, redactionLabel);
            }
        }
        
        return redactedText;
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
            when 'ORGANIZATION' {
                return '[REDACTED ORGANIZATION]';
            }
            when 'LOCATION' {
                return '[REDACTED LOCATION]';
            }
            when else {
                return '[REDACTED PII]';
            }
        }
    }
    
    /**
     * @description Calculates model confidence
     * @param predictions The ML predictions
     * @return Double The average confidence
     */
    private static Double calculateModelConfidence(List<MLPrediction> predictions) {
        if (predictions.isEmpty()) {
            return 0.0;
        }
        
        Double totalConfidence = 0.0;
        for (MLPrediction prediction : predictions) {
            totalConfidence += prediction.confidence;
        }
        
        return totalConfidence / predictions.size();
    }
    
    /**
     * @description Calculates accuracy metrics
     * @param entities The ensemble entities
     * @return Map<String, Object> Accuracy metrics
     */
    private static Map<String, Object> calculateAccuracyMetrics(List<EnsembleEntity> entities) {
        Map<String, Object> metrics = new Map<String, Object>();
        
        Integer totalEntities = entities.size();
        Integer highConfidenceEntities = 0;
        Integer multiModelAgreement = 0;
        
        for (EnsembleEntity entity : entities) {
            if (entity.confidence >= 0.8) {
                highConfidenceEntities++;
            }
            if (entity.totalModels >= 2) {
                multiModelAgreement++;
            }
        }
        
        metrics.put('total_entities', totalEntities);
        metrics.put('high_confidence_count', highConfidenceEntities);
        metrics.put('multi_model_agreement', multiModelAgreement);
        metrics.put('average_confidence', totalEntities > 0 ? calculateAverageConfidence(entities) : 0.0);
        
        return metrics;
    }
    
    /**
     * @description Calculates average confidence
     * @param entities The ensemble entities
     * @return Double The average confidence
     */
    private static Double calculateAverageConfidence(List<EnsembleEntity> entities) {
        if (entities.isEmpty()) {
            return 0.0;
        }
        
        Double totalConfidence = 0.0;
        for (EnsembleEntity entity : entities) {
            totalConfidence += entity.confidence;
        }
        
        return totalConfidence / entities.size();
    }
    
    /**
     * @description Creates basic predictions as fallback
     * @param text The text to analyze
     * @return List<MLPrediction> Basic predictions
     */
    private static List<MLPrediction> createBasicPredictions(String text) {
        List<MLPrediction> predictions = new List<MLPrediction>();
        
        // Simple pattern matching as fallback
        Pattern emailPattern = Pattern.compile('\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b');
        Matcher emailMatcher = emailPattern.matcher(text);
        
        while (emailMatcher.find()) {
            MLPrediction prediction = new MLPrediction();
            prediction.text = emailMatcher.group();
            prediction.type = 'EMAIL';
            prediction.confidence = 0.9;
            prediction.model = 'BASIC';
            predictions.add(prediction);
        }
        
        return predictions;
    }
    
    /**
     * @description Creates an error result
     * @param errorMessage The error message
     * @return DeepLearningRedactionResult The error result
     */
    private static DeepLearningRedactionResult createErrorResult(String errorMessage) {
        DeepLearningRedactionResult result = new DeepLearningRedactionResult();
        result.isSuccess = false;
        result.errorMessage = errorMessage;
        result.timestamp = Datetime.now();
        return result;
    }
    
    /**
     * @description Test method for deep learning redaction
     * @return DeepLearningRedactionResult Sample result
     */
    @AuraEnabled(cacheable=true)
    public static DeepLearningRedactionResult getSampleDeepLearningRedaction() {
        String sampleText = 'Customer John Smith from Acme Corp called about their order. ' +
                           'Contact: john.smith@acme.com, Phone: (555) 123-4567. ' +
                           'Address: 123 Main St, Anytown, USA.';
        
        return deepLearningRedact(sampleText, 'ensemble');
    }
    
    /**
     * @description ML Prediction wrapper class
     */
    public class MLPrediction {
        @AuraEnabled public String text;
        @AuraEnabled public String type;
        @AuraEnabled public Double confidence;
        @AuraEnabled public String model;
    }
    
    /**
     * @description Ensemble Entity wrapper class
     */
    public class EnsembleEntity {
        @AuraEnabled public String text;
        @AuraEnabled public String type;
        @AuraEnabled public Double confidence;
        @AuraEnabled public Integer voteCount;
        @AuraEnabled public Integer totalModels;
    }
    
    /**
     * @description Deep Learning Redaction Result wrapper class
     */
    public class DeepLearningRedactionResult {
        @AuraEnabled public String originalText;
        @AuraEnabled public String preprocessedText;
        @AuraEnabled public String redactedText;
        @AuraEnabled public String modelType;
        @AuraEnabled public List<MLPrediction> mlPredictions;
        @AuraEnabled public List<EnsembleEntity> ensembleEntities;
        @AuraEnabled public Double modelConfidence;
        @AuraEnabled public Map<String, Object> accuracyMetrics;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Datetime timestamp;
    }
} 