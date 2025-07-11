/**
 * @description Test class for TranscriptRedactionService
 * @author AI Assistant
 * @version 1.0
 */
@isTest
private class TranscriptRedactionServiceTest {
    
    /**
     * @description Test redaction of email addresses
     */
    @isTest
    static void testEmailRedaction() {
        // Test data with various email formats
        String testText = 'Contact us at john.doe@example.com or support@company.co.uk. ' +
                         'Also try admin@test-domain.org for technical issues.';
        
        // Perform redaction
        String result = TranscriptRedactionService.redactTranscript(testText);
        
        // Verify emails are redacted
        System.assert(result.contains('[REDACTED EMAIL]'), 'Email should be redacted');
        System.assert(!result.contains('john.doe@example.com'), 'Original email should not appear');
        System.assert(!result.contains('support@company.co.uk'), 'Original email should not appear');
        System.assert(!result.contains('admin@test-domain.org'), 'Original email should not appear');
        
        // Verify other text remains unchanged
        System.assert(result.contains('Contact us at'), 'Other text should remain');
        System.assert(result.contains('Also try'), 'Other text should remain');
    }
    
    /**
     * @description Test redaction of phone numbers
     */
    @isTest
    static void testPhoneRedaction() {
        // Test data with various phone formats
        String testText = 'Call us at (555) 123-4567 or 555-987-6543. ' +
                         'International: +1-555-123-4567 or +1 (555) 987-6543. ' +
                         'Also try 555.123.4567 or 5551234567.';
        
        // Perform redaction
        String result = TranscriptRedactionService.redactTranscript(testText);
        
        // Verify phone numbers are redacted
        System.assert(result.contains('[REDACTED PHONE]'), 'Phone should be redacted');
        System.assert(!result.contains('(555) 123-4567'), 'Original phone should not appear');
        System.assert(!result.contains('555-987-6543'), 'Original phone should not appear');
        System.assert(!result.contains('+1-555-123-4567'), 'Original phone should not appear');
        System.assert(!result.contains('+1 (555) 987-6543'), 'Original phone should not appear');
        System.assert(!result.contains('555.123.4567'), 'Original phone should not appear');
        System.assert(!result.contains('5551234567'), 'Original phone should not appear');
        
        // Verify other text remains unchanged
        System.assert(result.contains('Call us at'), 'Other text should remain');
        System.assert(result.contains('International:'), 'Other text should remain');
    }
    
    /**
     * @description Test redaction of credit card numbers
     */
    @isTest
    static void testCreditCardRedaction() {
        // Test data with various card formats
        String testText = 'Card number: 1234-5678-9012-3456. ' +
                         'Also try 1234 5678 9012 3456 or 1234567890123456. ' +
                         'Amex: 1234-567890-12345.';
        
        // Perform redaction
        String result = TranscriptRedactionService.redactTranscript(testText);
        
        // Verify credit cards are redacted
        System.assert(result.contains('[REDACTED CARD]'), 'Credit card should be redacted');
        System.assert(!result.contains('1234-5678-9012-3456'), 'Original card should not appear');
        System.assert(!result.contains('1234 5678 9012 3456'), 'Original card should not appear');
        System.assert(!result.contains('1234567890123456'), 'Original card should not appear');
        System.assert(!result.contains('1234-567890-12345'), 'Original Amex card should not appear');
        
        // Verify other text remains unchanged
        System.assert(result.contains('Card number:'), 'Other text should remain');
        System.assert(result.contains('Also try'), 'Other text should remain');
        System.assert(result.contains('Amex:'), 'Other text should remain');
    }
    
    /**
     * @description Test redaction of all PII types together
     */
    @isTest
    static void testCompleteRedaction() {
        // Test data with all PII types
        String testText = 'Customer: Hi, my email is john.smith@example.com and phone is (555) 123-4567. ' +
                         'I need to update my card 1234-5678-9012-3456. ' +
                         'Also contact me at sarah.jones@company.com or 555-987-6543.';
        
        // Perform redaction
        String result = TranscriptRedactionService.redactTranscript(testText);
        
        // Verify all PII types are redacted
        System.assert(result.contains('[REDACTED EMAIL]'), 'Emails should be redacted');
        System.assert(result.contains('[REDACTED PHONE]'), 'Phones should be redacted');
        System.assert(result.contains('[REDACTED CARD]'), 'Cards should be redacted');
        
        // Verify original PII is not present
        System.assert(!result.contains('john.smith@example.com'), 'Original email should not appear');
        System.assert(!result.contains('sarah.jones@company.com'), 'Original email should not appear');
        System.assert(!result.contains('(555) 123-4567'), 'Original phone should not appear');
        System.assert(!result.contains('555-987-6543'), 'Original phone should not appear');
        System.assert(!result.contains('1234-5678-9012-3456'), 'Original card should not appear');
        
        // Verify other text remains unchanged
        System.assert(result.contains('Customer: Hi,'), 'Other text should remain');
        System.assert(result.contains('I need to update my card'), 'Other text should remain');
        System.assert(result.contains('Also contact me at'), 'Other text should remain');
    }
    
    /**
     * @description Test empty input handling
     */
    @isTest
    static void testEmptyInput() {
        // Test empty string
        String result1 = TranscriptRedactionService.redactTranscript('');
        System.assertEquals('', result1, 'Empty input should return empty string');
        
        // Test null input
        String result2 = TranscriptRedactionService.redactTranscript(null);
        System.assertEquals('', result2, 'Null input should return empty string');
        
        // Test whitespace only
        String result3 = TranscriptRedactionService.redactTranscript('   ');
        System.assertEquals('', result3, 'Whitespace only should return empty string');
    }
    
    /**
     * @description Test text without PII
     */
    @isTest
    static void testNoPII() {
        String testText = 'This is a normal transcript without any sensitive information. ' +
                         'It contains regular text and numbers like 12345 and 67890. ' +
                         'No emails, phones, or credit cards here.';
        
        String result = TranscriptRedactionService.redactTranscript(testText);
        
        // Verify text remains unchanged
        System.assertEquals(testText, result, 'Text without PII should remain unchanged');
    }
    
    /**
     * @description Test sample redacted text method
     */
    @isTest
    static void testGetSampleRedactedText() {
        String result = TranscriptRedactionService.getSampleRedactedText();
        
        // Verify the sample text is redacted
        System.assert(result.contains('[REDACTED EMAIL]'), 'Sample should contain redacted email');
        System.assert(result.contains('[REDACTED PHONE]'), 'Sample should contain redacted phone');
        System.assert(result.contains('[REDACTED CARD]'), 'Sample should contain redacted card');
        
        // Verify original PII is not present
        System.assert(!result.contains('john.doe@example.com'), 'Original email should not appear');
        System.assert(!result.contains('(555) 123-4567'), 'Original phone should not appear');
        System.assert(!result.contains('1234-5678-9012-3456'), 'Original card should not appear');
    }
    
    /**
     * @description Test large text handling
     */
    @isTest
    static void testLargeText() {
        // Create a large text with PII scattered throughout
        String largeText = '';
        for (Integer i = 0; i < 100; i++) {
            largeText += 'This is paragraph ' + i + '. Contact us at test' + i + '@example.com. ' +
                        'Call us at (555) 123-' + String.valueOf(i).leftPad(4, '0') + '. ' +
                        'Card: 1234-5678-9012-' + String.valueOf(i).leftPad(4, '0') + '. ';
        }
        
        // Perform redaction
        String result = TranscriptRedactionService.redactTranscript(largeText);
        
        // Verify redaction still works
        System.assert(result.contains('[REDACTED EMAIL]'), 'Large text should still redact emails');
        System.assert(result.contains('[REDACTED PHONE]'), 'Large text should still redact phones');
        System.assert(result.contains('[REDACTED CARD]'), 'Large text should still redact cards');
        
        // Verify original PII is not present
        System.assert(!result.contains('test0@example.com'), 'Original email should not appear');
        System.assert(!result.contains('(555) 123-0000'), 'Original phone should not appear');
        System.assert(!result.contains('1234-5678-9012-0000'), 'Original card should not appear');
    }
    
    /**
     * @description Test error handling
     */
    @isTest
    static void testErrorHandling() {
        // This test ensures the method handles errors gracefully
        // The actual error handling is minimal in this implementation,
        // but we can test that the method doesn't throw unexpected exceptions
        
        String testText = 'Normal text with some PII: test@example.com and (555) 123-4567';
        
        try {
            String result = TranscriptRedactionService.redactTranscript(testText);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (Exception e) {
            System.assert(false, 'Method should not throw unexpected exceptions: ' + e.getMessage());
        }
    }
} 