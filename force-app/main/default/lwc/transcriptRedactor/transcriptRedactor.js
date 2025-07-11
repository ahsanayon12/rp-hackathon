import { LightningElement, track, wire } from 'lwc';
import redactTranscript from '@salesforce/apex/TranscriptRedactionService.redactTranscript';
import getSampleRedactedText from '@salesforce/apex/TranscriptRedactionService.getSampleRedactedText';
import analyzeTranscript from '@salesforce/apex/OpenAITranscriptAnalyzer.analyzeTranscript';
import getSampleAnalysis from '@salesforce/apex/OpenAITranscriptAnalyzer.getSampleAnalysis';

/**
 * @description Lightning Web Component for redacting PII from call transcripts
 * @author AI Assistant
 * @version 1.0
 */
export default class TranscriptRedactor extends LightningElement {
    
    // Track component state
    @track originalText = '';
    @track redactedText = '';
    @track isLoading = false;
    @track errorMessage = '';
    @track showSample = false;
    
    // AI Analysis state
    @track analysisResult = null;
    @track selectedAnalysisType = 'summary';
    @track showAIAnalysis = false;
    
    // Sample transcript data for testing
    sampleTranscripts = [
        {
            name: 'Customer Service Call',
            text: `Agent: Hello, thank you for calling our support line. How can I help you today?
Customer: Hi, I need help with my order. My email is john.smith@example.com and my phone is (555) 123-4567.
Agent: I can help you with that. Can you provide your order number?
Customer: Sure, it's ORD-12345. Also, I need to update my payment method. My card is 1234-5678-9012-3456.
Agent: I'll help you update that. What's the new card number?
Customer: The new one is 9876-5432-1098-7654. Can you confirm my email is still john.smith@example.com?
Agent: Yes, I can see your email is john.smith@example.com. Is there anything else you need help with?
Customer: No, that's all. Thanks!`
        },
        {
            name: 'Sales Call',
            text: `Sales Rep: Good afternoon! I'm calling about your recent inquiry. Is this 555-987-6543?
Customer: Yes, this is Sarah Johnson. My email is sarah.johnson@company.com.
Sales Rep: Perfect! I see you're interested in our premium package. The cost is $299/month.
Customer: That sounds good. I can pay with my card 4567-8901-2345-6789.
Sales Rep: Great! I'll process that for you. Can you confirm your phone number is 555-987-6543?
Customer: Yes, that's correct. My work email is sarah.johnson@company.com.
Sales Rep: Excellent! Your account is now set up. You'll receive a confirmation at sarah.johnson@company.com.`
        },
        {
            name: 'Technical Support',
            text: `Tech Support: Hello, this is technical support. How can I assist you?
Customer: Hi, I'm having trouble with my account. My email is tech.user@email.com.
Tech Support: I can help you with that. What's your phone number for verification?
Customer: It's 555.123.4567. Also, I need to update my billing info.
Tech Support: Sure, what's your current card number?
Customer: It's 1111-2222-3333-4444. My backup email is backup@email.com.
Tech Support: Got it. I'll update your information. Is 555.123.4567 still your primary contact?
Customer: Yes, that's correct. Thanks for your help!`
        }
    ];
    
    /**
     * @description Handles input changes in the original text area
     * @param {Event} event - The input change event
     */
    handleOriginalTextChange(event) {
        this.originalText = event.target.value;
        this.errorMessage = ''; // Clear any previous errors
    }
    
    /**
     * @description Initiates the redaction process
     */
    async handleRedact() {
        if (!this.originalText.trim()) {
            this.errorMessage = 'Please enter some text to redact.';
            return;
        }
        
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            // Call the Apex method to redact the transcript
            this.redactedText = await redactTranscript({ transcriptText: this.originalText });
            
            // Scroll to the redacted text section
            this.scrollToRedactedText();
            
        } catch (error) {
            console.error('Error during redaction:', error);
            this.errorMessage = 'An error occurred while processing the transcript. Please try again.';
            this.redactedText = '';
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * @description Initiates AI analysis of the transcript
     */
    async handleAnalyze() {
        if (!this.originalText.trim()) {
            this.errorMessage = 'Please enter some text to analyze.';
            return;
        }
        
        this.isLoading = true;
        this.errorMessage = '';
        this.analysisResult = null;
        
        try {
            // Call the Apex method to analyze the transcript with AI
            this.analysisResult = await analyzeTranscript({ 
                transcriptText: this.originalText, 
                analysisType: this.selectedAnalysisType 
            });
            
            if (this.analysisResult.isSuccess) {
                this.redactedText = this.analysisResult.redactedTranscript;
                this.showAIAnalysis = true;
                this.scrollToAnalysis();
            } else {
                this.errorMessage = this.analysisResult.errorMessage || 'Analysis failed. Please try again.';
            }
            
        } catch (error) {
            console.error('Error during analysis:', error);
            this.errorMessage = 'An error occurred while analyzing the transcript. Please try again.';
            this.analysisResult = null;
        } finally {
            this.isLoading = false;
        }
    }
    
    /**
     * @description Loads a sample transcript for testing
     * @param {Event} event - The click event
     */
    handleLoadSample(event) {
        const sampleIndex = parseInt(event.target.dataset.index);
        if (sampleIndex >= 0 && sampleIndex < this.sampleTranscripts.length) {
            this.originalText = this.sampleTranscripts[sampleIndex].text;
            this.errorMessage = '';
        }
    }
    
    /**
     * @description Clears all text and resets the component
     */
    handleClear() {
        this.originalText = '';
        this.redactedText = '';
        this.errorMessage = '';
        this.analysisResult = null;
        this.showAIAnalysis = false;
    }
    
    /**
     * @description Toggles the sample data visibility
     */
    handleToggleSamples() {
        this.showSample = !this.showSample;
    }
    
    /**
     * @description Scrolls to the redacted text section for better UX
     */
    scrollToRedactedText() {
        // Use setTimeout to ensure the DOM has updated
        setTimeout(() => {
            const redactedSection = this.template.querySelector('.redacted-section');
            if (redactedSection) {
                redactedSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);
    }
    
    /**
     * @description Scrolls to the AI analysis section for better UX
     */
    scrollToAnalysis() {
        // Use setTimeout to ensure the DOM has updated
        setTimeout(() => {
            const analysisSection = this.template.querySelector('.analysis-section');
            if (analysisSection) {
                analysisSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);
    }
    
    /**
     * @description Gets CSS classes for the redacted text container
     * @returns {String} CSS classes
     */
    get redactedTextClass() {
        return this.redactedText ? 'redacted-text-container' : 'redacted-text-container hidden';
    }
    
    /**
     * @description Gets CSS classes for the error message
     * @returns {String} CSS classes
     */
    get errorClass() {
        return this.errorMessage ? 'error-message' : 'error-message hidden';
    }
    
    /**
     * @description Gets CSS classes for the sample data section
     * @returns {String} CSS classes
     */
    get sampleClass() {
        return this.showSample ? 'sample-section' : 'sample-section hidden';
    }
    
    /**
     * @description Gets CSS classes for the AI analysis section
     * @returns {String} CSS classes
     */
    get analysisClass() {
        return this.showAIAnalysis && this.analysisResult ? 'analysis-section' : 'analysis-section hidden';
    }
    
    /**
     * @description Gets the analysis type options for the dropdown
     * @returns {Array} Analysis type options
     */
    get analysisTypeOptions() {
        return [
            { label: 'Summary', value: 'summary' },
            { label: 'Sentiment Analysis', value: 'sentiment' },
            { label: 'Coaching Tips', value: 'coaching' },
            { label: 'Next Steps', value: 'next_steps' }
        ];
    }
    
    /**
     * @description Copies the redacted text to clipboard
     */
    handleCopyRedacted() {
        if (!this.redactedText) {
            return;
        }
        
        // Create a temporary textarea to copy text
        const textArea = document.createElement('textarea');
        textArea.value = this.redactedText;
        document.body.appendChild(textArea);
        textArea.select();
        
        try {
            document.execCommand('copy');
            // Show success message (you could add a toast notification here)
            console.log('Redacted text copied to clipboard');
        } catch (err) {
            console.error('Failed to copy text: ', err);
        }
        
        document.body.removeChild(textArea);
    }
    
    /**
     * @description Handles analysis type selection change
     * @param {Event} event - The change event
     */
    handleAnalysisTypeChange(event) {
        this.selectedAnalysisType = event.target.value;
    }
    
    /**
     * @description Loads a sample AI analysis for testing
     */
    async handleLoadSampleAnalysis() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            this.analysisResult = await getSampleAnalysis();
            if (this.analysisResult.isSuccess) {
                this.originalText = this.analysisResult.redactedTranscript;
                this.redactedText = this.analysisResult.redactedTranscript;
                this.showAIAnalysis = true;
                this.scrollToAnalysis();
            } else {
                this.errorMessage = this.analysisResult.errorMessage || 'Sample analysis failed.';
            }
        } catch (error) {
            console.error('Error loading sample analysis:', error);
            this.errorMessage = 'An error occurred while loading the sample analysis.';
        } finally {
            this.isLoading = false;
        }
    }
} 