/**
 * @description Apex service class for securely analyzing call transcripts using OpenAI API
 * @author AI Assistant
 * @version 1.0
 */
public with sharing class OpenAITranscriptAnalyzer {
    
    // Named credential for OpenAI API (configure in Salesforce Setup)
    private static final String NAMED_CREDENTIAL = 'OpenAI_API';
    
    // OpenAI API endpoint
    private static final String OPENAI_ENDPOINT = 'https://api.openai.com/v1/chat/completions';
    
    // Maximum tokens for input (to stay within OpenAI limits)
    private static final Integer MAX_INPUT_TOKENS = 3000;
    
    // Maximum tokens for response
    private static final Integer MAX_RESPONSE_TOKENS = 1000;
    
    // OpenAI model to use
    private static final String OPENAI_MODEL = 'gpt-3.5-turbo';
    
    /**
     * @description Analyzes a transcript and returns AI insights
     * @param transcriptText The original transcript text
     * @param analysisType The type of analysis to perform (summary, sentiment, coaching, next_steps)
     * @return TranscriptAnalysisResult The analysis result with redacted transcript and AI insights
     */
    @AuraEnabled(cacheable=false)
    public static TranscriptAnalysisResult analyzeTranscript(String transcriptText, String analysisType) {
        try {
            // Validate inputs
            if (String.isBlank(transcriptText)) {
                throw new IllegalArgumentException('Transcript text cannot be empty');
            }
            
            if (String.isBlank(analysisType)) {
                analysisType = 'summary'; // Default to summary
            }
            
            // Step 1: Redact PII from transcript using existing service
            String redactedTranscript = TranscriptRedactionService.redactTranscript(transcriptText);
            
            // Step 2: Truncate transcript if it exceeds token limits
            String truncatedTranscript = truncateTranscript(redactedTranscript);
            
            // Step 3: Generate prompt based on analysis type
            String prompt = generatePrompt(truncatedTranscript, analysisType);
            
            // Step 4: Call OpenAI API
            String aiResponse = callOpenAI(prompt);
            
            // Step 5: Parse and structure the response
            TranscriptAnalysisResult result = new TranscriptAnalysisResult();
            result.redactedTranscript = redactedTranscript;
            result.analysisType = analysisType;
            result.aiInsights = parseAIResponse(aiResponse, analysisType);
            result.isSuccess = true;
            result.timestamp = Datetime.now();
            
            // Log successful analysis
            System.debug('Successfully analyzed transcript. Type: ' + analysisType + ', Input length: ' + transcriptText.length() + ', Redacted length: ' + redactedTranscript.length());
            
            return result;
            
        } catch (Exception e) {
            // Log error for debugging
            System.debug('Error in analyzeTranscript: ' + e.getMessage() + '\n' + e.getStackTraceString());
            
            // Return error result
            TranscriptAnalysisResult errorResult = new TranscriptAnalysisResult();
            errorResult.isSuccess = false;
            errorResult.errorMessage = 'Analysis failed: ' + e.getMessage();
            errorResult.timestamp = Datetime.now();
            
            return errorResult;
        }
    }
    
    /**
     * @description Truncates transcript to stay within OpenAI token limits
     * @param transcript The transcript to truncate
     * @return String The truncated transcript
     */
    private static String truncateTranscript(String transcript) {
        // Rough estimation: 1 token ≈ 4 characters
        Integer maxChars = MAX_INPUT_TOKENS * 4;
        
        if (transcript.length() <= maxChars) {
            return transcript;
        }
        
        // Truncate and add indicator
        return transcript.substring(0, maxChars) + '\n\n[Transcript truncated due to length limits]';
    }
    
    /**
     * @description Generates appropriate prompt for OpenAI based on analysis type
     * @param transcript The redacted transcript
     * @param analysisType The type of analysis
     * @return String The formatted prompt
     */
    private static String generatePrompt(String transcript, String analysisType) {
        String basePrompt = 'Analyze the following customer service call transcript and provide insights. ' +
                           'The transcript has been redacted for privacy. ' +
                           'Provide your response in JSON format with the specified fields.\n\n' +
                           'Transcript:\n' + transcript + '\n\n';
        
        switch on analysisType.toLowerCase() {
            when 'summary' {
                return basePrompt + 'Provide a concise summary (2-3 sentences) of the call in JSON format: {"summary": "call summary here"}';
            }
            when 'sentiment' {
                return basePrompt + 'Analyze the customer sentiment throughout the call in JSON format: {"overall_sentiment": "positive/negative/neutral", "sentiment_details": "explanation of sentiment changes"}';
            }
            when 'coaching' {
                return basePrompt + 'Provide coaching tips for the agent in JSON format: {"coaching_tips": ["tip1", "tip2", "tip3"], "overall_performance": "positive/needs_improvement"}';
            }
            when 'next_steps' {
                return basePrompt + 'Identify next steps and action items in JSON format: {"next_steps": ["step1", "step2"], "priority": "high/medium/low", "estimated_completion": "timeframe"}';
            }
            when else {
                return basePrompt + 'Provide a general analysis in JSON format: {"analysis": "general insights about the call"}';
            }
        }
    }
    
    /**
     * @description Makes secure callout to OpenAI API
     * @param prompt The prompt to send to OpenAI
     * @return String The AI response
     */
    private static String callOpenAI(String prompt) {
        try {
            // Prepare the request body
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('model', OPENAI_MODEL);
            requestBody.put('max_tokens', MAX_RESPONSE_TOKENS);
            requestBody.put('temperature', 0.7);
            
            List<Map<String, String>> messages = new List<Map<String, String>>();
            Map<String, String> message = new Map<String, String>();
            message.put('role', 'user');
            message.put('content', prompt);
            messages.add(message);
            requestBody.put('messages', messages);
            
            // Convert to JSON
            String jsonBody = JSON.serialize(requestBody);
            
            // Make the HTTP callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/' + OPENAI_ENDPOINT.substring(OPENAI_ENDPOINT.indexOf('/v1/')));
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            
            // Set timeout
            req.setTimeout(30000); // 30 seconds
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Handle response
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> choices = (List<Object>) responseMap.get('choices');
                
                if (choices != null && !choices.isEmpty()) {
                    Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
                    Map<String, Object> messageObj = (Map<String, Object>) firstChoice.get('message');
                    return (String) messageObj.get('content');
                }
            }
            
            // Handle error response
            System.debug('OpenAI API Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            throw new CalloutException('OpenAI API returned error: ' + res.getStatusCode() + ' - ' + res.getBody());
            
        } catch (Exception e) {
            System.debug('Error calling OpenAI API: ' + e.getMessage());
            throw new CalloutException('Failed to call OpenAI API: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parses the AI response into structured data
     * @param aiResponse The raw AI response
     * @param analysisType The type of analysis performed
     * @return Map<String, Object> The parsed response
     */
    private static Map<String, Object> parseAIResponse(String aiResponse, String analysisType) {
        try {
            // Try to parse as JSON first
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(aiResponse);
            return parsedResponse;
        } catch (Exception e) {
            // If JSON parsing fails, return as plain text
            Map<String, Object> fallbackResponse = new Map<String, Object>();
            fallbackResponse.put('raw_response', aiResponse);
            fallbackResponse.put('analysis_type', analysisType);
            fallbackResponse.put('parse_error', 'Response was not in expected JSON format');
            return fallbackResponse;
        }
    }
    
    /**
     * @description Test method to validate the integration
     * @return TranscriptAnalysisResult Sample analysis result
     */
    @AuraEnabled(cacheable=true)
    public static TranscriptAnalysisResult getSampleAnalysis() {
        String sampleTranscript = 'Agent: Hello, thank you for calling our support line. How can I help you today?\n' +
                                 'Customer: Hi, I need help with my order. My email is [REDACTED EMAIL] and my phone is [REDACTED PHONE].\n' +
                                 'Agent: I can help you with that. Can you provide your order number?\n' +
                                 'Customer: Sure, it\'s ORD-12345. Also, I need to update my payment method.\n' +
                                 'Agent: I\'ll help you update that. What\'s the new card number?\n' +
                                 'Customer: The new one is [REDACTED CARD]. Can you confirm my email is still [REDACTED EMAIL]?\n' +
                                 'Agent: Yes, I can see your email is [REDACTED EMAIL]. Is there anything else you need help with?\n' +
                                 'Customer: No, that\'s all. Thanks!';
        
        return analyzeTranscript(sampleTranscript, 'summary');
    }
    
    /**
     * @description Wrapper class for analysis results
     */
    public class TranscriptAnalysisResult {
        @AuraEnabled public String redactedTranscript;
        @AuraEnabled public String analysisType;
        @AuraEnabled public Map<String, Object> aiInsights;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Datetime timestamp;
    }
} 