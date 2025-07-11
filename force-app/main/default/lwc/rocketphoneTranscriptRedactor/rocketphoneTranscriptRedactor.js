import { LightningElement, track, wire, api } from 'lwc';
import processRocketphoneCall from '@salesforce/apex/RocketphoneRedactionService.processRocketphoneCall';
import processRocketphoneCallWithDeepLearning from '@salesforce/apex/RocketphoneRedactionService.processRocketphoneCallWithDeepLearning';
import getCallTranscripts from '@salesforce/apex/RocketphoneRedactionService.getCallTranscripts';
import getProcessingStatistics from '@salesforce/apex/RocketphoneRedactionService.getProcessingStatistics';
import getOptimalModelForCall from '@salesforce/apex/RocketphoneRedactionService.getOptimalModelForCall';

/**
 * @description Lightning Web Component for Rocketphone AI transcript redaction
 * @author AI Assistant
 * @version 1.0
 */
export default class RocketphoneTranscriptRedactor extends LightningElement {
    
    // Public properties
    @api recordId; // The call record ID
    @api callId; // Alternative call ID property
    
    // Track component state
    @track transcriptText = '';
    @track redactedText = '';
    @track isLoading = false;
    @track errorMessage = '';
    @track showResults = false;
    
    // Configuration options
    @track selectedRedactionLevel = 'Enhanced';
    @track selectedModelType = 'ensemble';
    @track selectedUseCase = 'high_accuracy';
    
    // Results tracking
    @track transcripts = [];
    @track processingStats = {};
    @track optimalModel = null;
    @track showModelConfig = false;
    
    // Performance metrics
    @track processingMetrics = {
        startTime: null,
        endTime: null,
        processingTime: 0,
        modelUsed: '',
        confidenceScore: 0
    };
    
    // Sample transcript for testing
    sampleTranscript = `Agent: Hello, thank you for calling Rocketphone support. How can I help you today?
Customer: Hi, I'm having trouble with my account. My email is john.doe@example.com and my phone is (555) 123-4567.
Agent: I can help you with that. Can you provide your account number?
Customer: Sure, it's ACC-12345. Also, I need to update my payment method. My card is 1234-5678-9012-3456.
Agent: I'll help you update that. What's the new card number?
Customer: The new one is 9876-5432-1098-7654. Can you confirm my email is still john.doe@example.com?
Agent: Yes, I can see your email is john.doe@example.com. Is there anything else you need help with?
Customer: No, that's all. Thanks!`;
    
    /**
     * @description Handles input changes in the transcript text area
     * @param {Event} event - The input change event
     */
    handleTranscriptChange(event) {
        this.transcriptText = event.target.value;
        this.errorMessage = ''; // Clear any previous errors
    }
    
    /**
     * @description Handles redaction level change
     * @param {Event} event - The change event
     */
    handleRedactionLevelChange(event) {
        this.selectedRedactionLevel = event.target.value;
    }
    
    /**
     * @description Handles model type change
     * @param {Event} event - The change event
     */
    handleModelTypeChange(event) {
        this.selectedModelType = event.target.value;
    }
    
    /**
     * @description Handles use case change
     * @param {Event} event - The change event
     */
    handleUseCaseChange(event) {
        this.selectedUseCase = event.target.value;
    }
    
    /**
     * @description Initiates basic AI redaction process
     */
    async handleProcessTranscript() {
        if (!this.transcriptText.trim()) {
            this.errorMessage = 'Please enter transcript text.';
            return;
        }
        
        this.startProcessing('AI Enhanced Redaction');
        
        try {
            const callId = this.recordId || this.callId;
            
            // Process the transcript
            const recordId = await processRocketphoneCall({
                callId: callId,
                transcriptText: this.transcriptText,
                redactionLevel: this.selectedRedactionLevel
            });
            
            // Load updated transcripts
            await this.loadTranscripts();
            
            // Show success message
            this.showToast('Success', 'Transcript processed successfully!', 'success');
            
        } catch (error) {
            console.error('Error processing transcript:', error);
            this.errorMessage = 'Error processing transcript: ' + error.message;
            this.showToast('Error', 'Failed to process transcript', 'error');
        } finally {
            this.endProcessing();
        }
    }
    
    /**
     * @description Initiates deep learning redaction process
     */
    async handleDeepLearningProcess() {
        if (!this.transcriptText.trim()) {
            this.errorMessage = 'Please enter transcript text.';
            return;
        }
        
        this.startProcessing('Deep Learning Redaction');
        
        try {
            const callId = this.recordId || this.callId;
            
            // Process with deep learning
            const recordId = await processRocketphoneCallWithDeepLearning({
                callId: callId,
                transcriptText: this.transcriptText,
                modelType: this.selectedModelType
            });
            
            // Load updated transcripts
            await this.loadTranscripts();
            
            // Show success message
            this.showToast('Success', 'Deep learning processing completed!', 'success');
            
        } catch (error) {
            console.error('Error in deep learning processing:', error);
            this.errorMessage = 'Error in deep learning processing: ' + error.message;
            this.showToast('Error', 'Deep learning processing failed', 'error');
        } finally {
            this.endProcessing();
        }
    }
    
    /**
     * @description Gets optimal model configuration for the call
     */
    async handleGetOptimalModel() {
        try {
            const callId = this.recordId || this.callId;
            
            this.optimalModel = await getOptimalModelForCall({
                callId: callId,
                useCase: this.selectedUseCase
            });
            
            if (this.optimalModel.isSuccess) {
                this.showModelConfig = true;
                this.scrollToModelConfig();
            } else {
                this.errorMessage = this.optimalModel.errorMessage || 'Failed to get optimal model configuration.';
            }
            
        } catch (error) {
            console.error('Error getting optimal model:', error);
            this.errorMessage = 'Error getting optimal model: ' + error.message;
        }
    }
    
    /**
     * @description Loads sample transcript for testing
     */
    handleLoadSample() {
        this.transcriptText = this.sampleTranscript;
        this.errorMessage = '';
    }
    
    /**
     * @description Clears all data and resets the component
     */
    handleClear() {
        this.transcriptText = '';
        this.redactedText = '';
        this.errorMessage = '';
        this.showResults = false;
        this.showModelConfig = false;
        this.optimalModel = null;
    }
    
    /**
     * @description Loads transcripts for the current call
     */
    async loadTranscripts() {
        try {
            const callId = this.recordId || this.callId;
            
            if (callId) {
                this.transcripts = await getCallTranscripts({ callId: callId });
                this.loadProcessingStats();
            }
        } catch (error) {
            console.error('Error loading transcripts:', error);
        }
    }
    
    /**
     * @description Loads processing statistics
     */
    async loadProcessingStats() {
        try {
            const callId = this.recordId || this.callId;
            
            if (callId) {
                this.processingStats = await getProcessingStatistics({ callId: callId });
            }
        } catch (error) {
            console.error('Error loading processing stats:', error);
        }
    }
    
    /**
     * @description Starts processing timer
     * @param {String} processType - The type of process
     */
    startProcessing(processType) {
        this.isLoading = true;
        this.errorMessage = '';
        this.processingMetrics.startTime = new Date();
        this.processingMetrics.modelUsed = processType;
    }
    
    /**
     * @description Ends processing timer
     */
    endProcessing() {
        this.isLoading = false;
        this.processingMetrics.endTime = new Date();
        this.processingMetrics.processingTime = 
            (this.processingMetrics.endTime - this.processingMetrics.startTime) / 1000;
    }
    
    /**
     * @description Scrolls to the model configuration section
     */
    scrollToModelConfig() {
        setTimeout(() => {
            const modelConfigSection = this.template.querySelector('.model-config-section');
            if (modelConfigSection) {
                modelConfigSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);
    }
    
    /**
     * @description Shows a toast message
     * @param {String} title - The toast title
     * @param {String} message - The toast message
     * @param {String} variant - The toast variant
     */
    showToast(title, message, variant) {
        // Implementation for showing toast messages
        console.log(`${title}: ${message}`);
    }
    
    /**
     * @description Gets the redaction level options
     * @returns {Array} Redaction level options
     */
    get redactionLevelOptions() {
        return [
            { label: 'Basic', value: 'Basic' },
            { label: 'Enhanced', value: 'Enhanced' },
            { label: 'Strict', value: 'Strict' }
        ];
    }
    
    /**
     * @description Gets the model type options
     * @returns {Array} Model type options
     */
    get modelTypeOptions() {
        return [
            { label: 'BERT', value: 'bert' },
            { label: 'GPT', value: 'gpt' },
            { label: 'Ensemble', value: 'ensemble' }
        ];
    }
    
    /**
     * @description Gets the use case options
     * @returns {Array} Use case options
     */
    get useCaseOptions() {
        return [
            { label: 'High Accuracy', value: 'high_accuracy' },
            { label: 'Fast Processing', value: 'fast_processing' },
            { label: 'Cost Effective', value: 'cost_effective' },
            { label: 'Comprehensive', value: 'comprehensive' }
        ];
    }
    
    /**
     * @description Gets CSS classes for the model config section
     * @returns {String} CSS classes
     */
    get modelConfigClass() {
        return this.showModelConfig && this.optimalModel ? 'model-config-section' : 'model-config-section hidden';
    }
    
    /**
     * @description Gets CSS classes for the transcripts section
     * @returns {String} CSS classes
     */
    get transcriptsClass() {
        return this.transcripts.length > 0 ? 'transcripts-section' : 'transcripts-section hidden';
    }
    
    /**
     * @description Gets CSS classes for the stats section
     * @returns {String} CSS classes
     */
    get statsClass() {
        return Object.keys(this.processingStats).length > 0 ? 'stats-section' : 'stats-section hidden';
    }
    
    /**
     * @description Gets the latest transcript
     * @returns {Object} The latest transcript record
     */
    get latestTranscript() {
        return this.transcripts.length > 0 ? this.transcripts[0] : null;
    }
    
    /**
     * @description Gets the redacted text from the latest transcript
     * @returns {String} The redacted text
     */
    get latestRedactedText() {
        return this.latestTranscript ? this.latestTranscript.Redacted_Transcript__c : '';
    }
    
    /**
     * @description Gets the processing status from the latest transcript
     * @returns {String} The processing status
     */
    get latestProcessingStatus() {
        return this.latestTranscript ? this.latestTranscript.Processing_Status__c : '';
    }
    
    /**
     * @description Gets the confidence score from the latest transcript
     * @returns {Number} The confidence score
     */
    get latestConfidenceScore() {
        return this.latestTranscript ? this.latestTranscript.Confidence_Score__c : 0;
    }
} 