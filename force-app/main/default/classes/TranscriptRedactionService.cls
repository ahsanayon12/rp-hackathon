/**
 * @description Apex service class for redacting PII (Personally Identifiable Information) from call transcripts
 * @author AI Assistant
 * @version 1.0
 */
public with sharing class TranscriptRedactionService {
    
    /**
     * @description Redacts PII from transcript text using regex patterns
     * @param transcriptText The original transcript text containing PII
     * @return String The redacted transcript text
     */
    @AuraEnabled(cacheable=false)
    public static String redactTranscript(String transcriptText) {
        try {
            // Validate input
            if (String.isBlank(transcriptText)) {
                return '';
            }
            
            String redactedText = transcriptText;
            
            // Redact email addresses
            redactedText = redactEmails(redactedText);
            
            // Redact phone numbers
            redactedText = redactPhoneNumbers(redactedText);
            
            // Redact credit card numbers
            redactedText = redactCreditCards(redactedText);
            
            return redactedText;
            
        } catch (Exception e) {
            // Log error for debugging
            System.debug('Error in redactTranscript: ' + e.getMessage());
            throw new AuraHandledException('Error processing transcript: ' + e.getMessage());
        }
    }
    
    /**
     * @description Redacts email addresses from text
     * @param text The text to process
     * @return String Text with emails redacted
     */
    private static String redactEmails(String text) {
        // Regex pattern for email addresses
        // Matches: user@domain.com, user.name@domain.co.uk, etc.
        String emailPattern = '\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b';
        return text.replaceAll(emailPattern, '[REDACTED EMAIL]');
    }
    
    /**
     * @description Redacts phone numbers from text
     * @param text The text to process
     * @return String Text with phone numbers redacted
     */
    private static String redactPhoneNumbers(String text) {
        // Regex patterns for various phone number formats
        // US/Canada: (555) 123-4567, 555-123-4567, 555.123.4567, 5551234567
        // International: +1-555-123-4567, +1 (555) 123-4567
        String phonePatterns = '(\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4})|' +
                              '(\\+?1?[\\s.-]?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4})|' +
                              '(\\d{10,11})';
        
        return text.replaceAll(phonePatterns, '[REDACTED PHONE]');
    }
    
    /**
     * @description Redacts credit card numbers from text
     * @param text The text to process
     * @return String Text with credit card numbers redacted
     */
    private static String redactCreditCards(String text) {
        // Regex pattern for credit card numbers
        // Matches: 1234-5678-9012-3456, 1234 5678 9012 3456, 1234567890123456
        // Supports Visa, MasterCard, American Express, Discover
        String cardPattern = '\\b(?:\\d{4}[\\s-]?){3}\\d{4}\\b|' +
                           '\\b\\d{4}[\\s-]?\\d{6}[\\s-]?\\d{5}\\b'; // Amex format
        
        return text.replaceAll(cardPattern, '[REDACTED CARD]');
    }
    
    /**
     * @description Test method to validate redaction patterns
     * @return String Sample redacted text for testing
     */
    @AuraEnabled(cacheable=true)
    public static String getSampleRedactedText() {
        String sampleText = 'Customer called about their order. ' +
                           'Contact: john.doe@example.com, ' +
                           'Phone: (555) 123-4567, ' +
                           'Card: 1234-5678-9012-3456. ' +
                           'Also tried: 555.123.4567 and 1234567890123456';
        
        return redactTranscript(sampleText);
    }
} 