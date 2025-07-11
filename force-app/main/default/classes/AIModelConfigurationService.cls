/**
 * @description AI Model Configuration Service for managing different ML models and their configurations
 * @author AI Assistant
 * @version 1.0
 */
public with sharing class AIModelConfigurationService {
    
    // Model configurations
    private static final Map<String, ModelConfig> MODEL_CONFIGS = new Map<String, ModelConfig>{
        'bert-base' => new ModelConfig('bert-base-uncased', 'HuggingFace', 0.8, 'NER'),
        'bert-large' => new ModelConfig('bert-large-cased', 'HuggingFace', 0.85, 'NER'),
        'gpt-3.5' => new ModelConfig('gpt-3.5-turbo', 'OpenAI', 0.75, 'PII_DETECTION'),
        'gpt-4' => new ModelConfig('gpt-4', 'OpenAI', 0.9, 'PII_DETECTION'),
        'roberta' => new ModelConfig('roberta-base', 'HuggingFace', 0.8, 'SENTIMENT'),
        'distilbert' => new ModelConfig('distilbert-base-uncased', 'HuggingFace', 0.75, 'NER'),
        'aws-comprehend' => new ModelConfig('comprehend', 'AWS', 0.8, 'ENTITY_RECOGNITION'),
        'azure-cognitive' => new ModelConfig('text-analytics', 'Azure', 0.8, 'ENTITY_RECOGNITION')
    };
    
    // Use case configurations
    private static final Map<String, UseCaseConfig> USE_CASE_CONFIGS = new Map<String, UseCaseConfig>{
        'high_accuracy' => new UseCaseConfig(['gpt-4', 'bert-large', 'aws-comprehend'], 0.85, 'Ensemble'),
        'fast_processing' => new UseCaseConfig(['distilbert', 'gpt-3.5'], 0.7, 'Single'),
        'cost_effective' => new UseCaseConfig(['bert-base', 'roberta'], 0.75, 'Dual'),
        'comprehensive' => new UseCaseConfig(['gpt-4', 'bert-large', 'aws-comprehend', 'azure-cognitive'], 0.9, 'Ensemble')
    };
    
    /**
     * @description Gets the best model configuration for a given use case
     * @param useCase The use case (high_accuracy, fast_processing, cost_effective, comprehensive)
     * @param textLength The length of text to process
     * @return ModelSelectionResult The recommended model configuration
     */
    @AuraEnabled(cacheable=true)
    public static ModelSelectionResult getOptimalModelConfiguration(String useCase, Integer textLength) {
        try {
            ModelSelectionResult result = new ModelSelectionResult();
            result.useCase = useCase;
            result.textLength = textLength;
            result.timestamp = Datetime.now();
            
            // Get use case configuration
            UseCaseConfig useCaseConfig = USE_CASE_CONFIGS.get(useCase);
            if (useCaseConfig == null) {
                useCaseConfig = USE_CASE_CONFIGS.get('high_accuracy'); // Default
            }
            
            result.recommendedModels = new List<String>();
            result.modelConfigurations = new List<ModelConfig>();
            
            // Select models based on use case and text length
            for (String modelName : useCaseConfig.modelNames) {
                ModelConfig modelConfig = MODEL_CONFIGS.get(modelName);
                if (modelConfig != null) {
                    // Adjust configuration based on text length
                    ModelConfig adjustedConfig = adjustModelForTextLength(modelConfig, textLength);
                    result.modelConfigurations.add(adjustedConfig);
                    result.recommendedModels.add(modelName);
                }
            }
            
            // Calculate estimated processing time and cost
            result.estimatedProcessingTime = calculateProcessingTime(result.modelConfigurations, textLength);
            result.estimatedCost = calculateEstimatedCost(result.modelConfigurations, textLength);
            result.confidenceThreshold = useCaseConfig.confidenceThreshold;
            result.ensembleStrategy = useCaseConfig.ensembleStrategy;
            
            result.isSuccess = true;
            return result;
            
        } catch (Exception e) {
            System.debug('Error in getOptimalModelConfiguration: ' + e.getMessage());
            ModelSelectionResult errorResult = new ModelSelectionResult();
            errorResult.isSuccess = false;
            errorResult.errorMessage = 'Failed to get model configuration: ' + e.getMessage();
            return errorResult;
        }
    }
    
    /**
     * @description Adjusts model configuration based on text length
     * @param modelConfig The original model configuration
     * @param textLength The text length
     * @return ModelConfig The adjusted configuration
     */
    private static ModelConfig adjustModelForTextLength(ModelConfig modelConfig, Integer textLength) {
        ModelConfig adjustedConfig = modelConfig.clone();
        
        // Adjust batch size and processing parameters based on text length
        if (textLength > 10000) {
            adjustedConfig.batchSize = 32;
            adjustedConfig.maxTokens = 2048;
        } else if (textLength > 5000) {
            adjustedConfig.batchSize = 64;
            adjustedConfig.maxTokens = 1024;
        } else {
            adjustedConfig.batchSize = 128;
            adjustedConfig.maxTokens = 512;
        }
        
        return adjustedConfig;
    }
    
    /**
     * @description Calculates estimated processing time
     * @param modelConfigs The model configurations
     * @param textLength The text length
     * @return Integer Estimated processing time in seconds
     */
    private static Integer calculateProcessingTime(List<ModelConfig> modelConfigs, Integer textLength) {
        Integer totalTime = 0;
        
        for (ModelConfig config : modelConfigs) {
            // Base processing time per model
            Integer baseTime = 2; // seconds
            
            // Adjust for text length
            Integer lengthFactor = Math.ceil(textLength / 1000.0);
            
            // Adjust for model complexity
            Double complexityFactor = 1.0;
            if (config.modelName.contains('large')) {
                complexityFactor = 1.5;
            } else if (config.modelName.contains('distil')) {
                complexityFactor = 0.7;
            }
            
            totalTime += Math.round(baseTime * lengthFactor * complexityFactor);
        }
        
        return totalTime;
    }
    
    /**
     * @description Calculates estimated cost
     * @param modelConfigs The model configurations
     * @param textLength The text length
     * @return Double Estimated cost in USD
     */
    private static Double calculateEstimatedCost(List<ModelConfig> modelConfigs, Integer textLength) {
        Double totalCost = 0.0;
        
        for (ModelConfig config : modelConfigs) {
            Double costPerToken = 0.0;
            
            // Cost per 1K tokens (approximate)
            switch on config.provider {
                when 'OpenAI' {
                    if (config.modelName.contains('gpt-4')) {
                        costPerToken = 0.03; // $0.03 per 1K tokens
                    } else {
                        costPerToken = 0.002; // $0.002 per 1K tokens
                    }
                }
                when 'HuggingFace' {
                    costPerToken = 0.001; // $0.001 per 1K tokens
                }
                when 'AWS' {
                    costPerToken = 0.0005; // $0.0005 per 1K tokens
                }
                when 'Azure' {
                    costPerToken = 0.001; // $0.001 per 1K tokens
                }
            }
            
            Integer estimatedTokens = Math.ceil(textLength / 4.0); // Rough estimation
            totalCost += (estimatedTokens / 1000.0) * costPerToken;
        }
        
        return totalCost;
    }
    
    /**
     * @description Gets available model configurations
     * @return List<ModelConfig> List of available models
     */
    @AuraEnabled(cacheable=true)
    public static List<ModelConfig> getAvailableModels() {
        List<ModelConfig> availableModels = new List<ModelConfig>();
        
        for (String modelName : MODEL_CONFIGS.keySet()) {
            ModelConfig config = MODEL_CONFIGS.get(modelName);
            availableModels.add(config);
        }
        
        return availableModels;
    }
    
    /**
     * @description Gets available use cases
     * @return List<UseCaseConfig> List of available use cases
     */
    @AuraEnabled(cacheable=true)
    public static List<UseCaseConfig> getAvailableUseCases() {
        List<UseCaseConfig> availableUseCases = new List<UseCaseConfig>();
        
        for (String useCaseName : USE_CASE_CONFIGS.keySet()) {
            UseCaseConfig config = USE_CASE_CONFIGS.get(useCaseName);
            config.name = useCaseName;
            availableUseCases.add(config);
        }
        
        return availableUseCases;
    }
    
    /**
     * @description Validates model configuration
     * @param modelName The model name
     * @param provider The provider
     * @return Boolean Whether the configuration is valid
     */
    @AuraEnabled(cacheable=true)
    public static Boolean validateModelConfiguration(String modelName, String provider) {
        for (ModelConfig config : MODEL_CONFIGS.values()) {
            if (config.modelName == modelName && config.provider == provider) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @description Gets model performance metrics
     * @param modelName The model name
     * @return ModelPerformanceMetrics The performance metrics
     */
    @AuraEnabled(cacheable=true)
    public static ModelPerformanceMetrics getModelPerformanceMetrics(String modelName) {
        ModelPerformanceMetrics metrics = new ModelPerformanceMetrics();
        metrics.modelName = modelName;
        
        // Simulated performance metrics (in real implementation, these would come from actual usage data)
        switch on modelName {
            when 'gpt-4' {
                metrics.accuracy = 0.95;
                metrics.precision = 0.92;
                metrics.recall = 0.94;
                metrics.f1Score = 0.93;
                metrics.averageResponseTime = 2.5;
            }
            when 'bert-large' {
                metrics.accuracy = 0.88;
                metrics.precision = 0.85;
                metrics.recall = 0.87;
                metrics.f1Score = 0.86;
                metrics.averageResponseTime = 1.8;
            }
            when 'distilbert' {
                metrics.accuracy = 0.82;
                metrics.precision = 0.80;
                metrics.recall = 0.81;
                metrics.f1Score = 0.80;
                metrics.averageResponseTime = 0.8;
            }
            when else {
                metrics.accuracy = 0.80;
                metrics.precision = 0.78;
                metrics.recall = 0.79;
                metrics.f1Score = 0.78;
                metrics.averageResponseTime = 1.5;
            }
        }
        
        return metrics;
    }
    
    /**
     * @description Model Configuration wrapper class
     */
    public class ModelConfig {
        @AuraEnabled public String modelName;
        @AuraEnabled public String provider;
        @AuraEnabled public Double baseAccuracy;
        @AuraEnabled public String taskType;
        @AuraEnabled public Integer batchSize = 64;
        @AuraEnabled public Integer maxTokens = 1024;
        @AuraEnabled public Double temperature = 0.1;
        @AuraEnabled public Boolean enableCaching = true;
        
        public ModelConfig(String modelName, String provider, Double baseAccuracy, String taskType) {
            this.modelName = modelName;
            this.provider = provider;
            this.baseAccuracy = baseAccuracy;
            this.taskType = taskType;
        }
        
        public ModelConfig clone() {
            ModelConfig cloned = new ModelConfig(this.modelName, this.provider, this.baseAccuracy, this.taskType);
            cloned.batchSize = this.batchSize;
            cloned.maxTokens = this.maxTokens;
            cloned.temperature = this.temperature;
            cloned.enableCaching = this.enableCaching;
            return cloned;
        }
    }
    
    /**
     * @description Use Case Configuration wrapper class
     */
    public class UseCaseConfig {
        @AuraEnabled public String name;
        @AuraEnabled public List<String> modelNames;
        @AuraEnabled public Double confidenceThreshold;
        @AuraEnabled public String ensembleStrategy;
        
        public UseCaseConfig(List<String> modelNames, Double confidenceThreshold, String ensembleStrategy) {
            this.modelNames = modelNames;
            this.confidenceThreshold = confidenceThreshold;
            this.ensembleStrategy = ensembleStrategy;
        }
    }
    
    /**
     * @description Model Selection Result wrapper class
     */
    public class ModelSelectionResult {
        @AuraEnabled public String useCase;
        @AuraEnabled public Integer textLength;
        @AuraEnabled public List<String> recommendedModels;
        @AuraEnabled public List<ModelConfig> modelConfigurations;
        @AuraEnabled public Integer estimatedProcessingTime;
        @AuraEnabled public Double estimatedCost;
        @AuraEnabled public Double confidenceThreshold;
        @AuraEnabled public String ensembleStrategy;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Datetime timestamp;
    }
    
    /**
     * @description Model Performance Metrics wrapper class
     */
    public class ModelPerformanceMetrics {
        @AuraEnabled public String modelName;
        @AuraEnabled public Double accuracy;
        @AuraEnabled public Double precision;
        @AuraEnabled public Double recall;
        @AuraEnabled public Double f1Score;
        @AuraEnabled public Double averageResponseTime;
    }
} 