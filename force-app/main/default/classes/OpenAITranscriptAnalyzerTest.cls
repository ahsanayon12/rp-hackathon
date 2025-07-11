/**
 * @description Test class for OpenAITranscriptAnalyzer
 * @author AI Assistant
 * @version 1.0
 */
@IsTest
private class OpenAITranscriptAnalyzerTest {
    
    /**
     * @description Test successful transcript analysis
     */
    @IsTest
    static void testSuccessfulAnalysis() {
        // Arrange
        String testTranscript = 'Agent: Hello, how can I help you today?\n' +
                               'Customer: Hi, I need help with my order. My email is test@example.com.\n' +
                               'Agent: I can help you with that. What\'s your order number?\n' +
                               'Customer: It\'s ORD-12345. Thanks!';
        
        // Act
        Test.startTest();
        OpenAITranscriptAnalyzer.TranscriptAnalysisResult result = 
            OpenAITranscriptAnalyzer.analyzeTranscript(testTranscript, 'summary');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.isSuccess, 'Analysis should be successful');
        System.assertEquals('summary', result.analysisType, 'Analysis type should match');
        System.assertNotEquals(null, result.redactedTranscript, 'Redacted transcript should not be null');
        System.assertNotEquals(null, result.aiInsights, 'AI insights should not be null');
        System.assertNotEquals(null, result.timestamp, 'Timestamp should not be null');
    }
    
    /**
     * @description Test analysis with different types
     */
    @IsTest
    static void testDifferentAnalysisTypes() {
        String testTranscript = 'Agent: Hello, how can I help you today?\n' +
                               'Customer: Hi, I need help with my order.\n' +
                               'Agent: I can help you with that.';
        
        List<String> analysisTypes = new List<String>{'summary', 'sentiment', 'coaching', 'next_steps'};
        
        for (String analysisType : analysisTypes) {
            Test.startTest();
            OpenAITranscriptAnalyzer.TranscriptAnalysisResult result = 
                OpenAITranscriptAnalyzer.analyzeTranscript(testTranscript, analysisType);
            Test.stopTest();
            
            System.assertEquals(analysisType, result.analysisType, 'Analysis type should match: ' + analysisType);
            System.assertEquals(true, result.isSuccess, 'Analysis should be successful for: ' + analysisType);
        }
    }
    
    /**
     * @description Test with empty transcript
     */
    @IsTest
    static void testEmptyTranscript() {
        // Act
        Test.startTest();
        OpenAITranscriptAnalyzer.TranscriptAnalysisResult result = 
            OpenAITranscriptAnalyzer.analyzeTranscript('', 'summary');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.isSuccess, 'Should fail with empty transcript');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }
    
    /**
     * @description Test with null transcript
     */
    @IsTest
    static void testNullTranscript() {
        // Act
        Test.startTest();
        OpenAITranscriptAnalyzer.TranscriptAnalysisResult result = 
            OpenAITranscriptAnalyzer.analyzeTranscript(null, 'summary');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result.isSuccess, 'Should fail with null transcript');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }
    
    /**
     * @description Test with very long transcript (should be truncated)
     */
    @IsTest
    static void testLongTranscript() {
        // Create a very long transcript
        String longTranscript = '';
        for (Integer i = 0; i < 1000; i++) {
            longTranscript += 'Agent: Hello, how can I help you today? This is a very long conversation that should be truncated. ';
        }
        
        // Act
        Test.startTest();
        OpenAITranscriptAnalyzer.TranscriptAnalysisResult result = 
            OpenAITranscriptAnalyzer.analyzeTranscript(longTranscript, 'summary');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        // The transcript should be processed (either successfully or with error)
        System.assertNotEquals(null, result.redactedTranscript, 'Redacted transcript should not be null');
    }
    
    /**
     * @description Test sample analysis method
     */
    @IsTest
    static void testSampleAnalysis() {
        // Act
        Test.startTest();
        OpenAITranscriptAnalyzer.TranscriptAnalysisResult result = 
            OpenAITranscriptAnalyzer.getSampleAnalysis();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Sample result should not be null');
        System.assertEquals('summary', result.analysisType, 'Sample should use summary analysis');
        System.assertNotEquals(null, result.redactedTranscript, 'Sample should have redacted transcript');
    }
    
    /**
     * @description Test with PII in transcript (should be redacted)
     */
    @IsTest
    static void testPIIRedaction() {
        // Arrange
        String testTranscript = 'Agent: Hello, how can I help you today?\n' +
                               'Customer: Hi, my email is john.doe@example.com and my phone is (555) 123-4567.\n' +
                               'Agent: I can help you with that. What\'s your card number?\n' +
                               'Customer: It\'s 1234-5678-9012-3456. Thanks!';
        
        // Act
        Test.startTest();
        OpenAITranscriptAnalyzer.TranscriptAnalysisResult result = 
            OpenAITranscriptAnalyzer.analyzeTranscript(testTranscript, 'summary');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.redactedTranscript, 'Redacted transcript should not be null');
        
        // Check that PII is redacted
        String redactedText = result.redactedTranscript;
        System.assert(redactedText.contains('[REDACTED EMAIL]'), 'Email should be redacted');
        System.assert(redactedText.contains('[REDACTED PHONE]'), 'Phone should be redacted');
        System.assert(redactedText.contains('[REDACTED CARD]'), 'Card should be redacted');
    }
} 