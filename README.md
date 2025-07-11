# Salesforce Transcript Redactor & AI Analyzer

A secure Salesforce Lightning Web Component that redacts PII (Personally Identifiable Information) from call transcripts and generates AI insights using OpenAI's GPT API.

## Features

### 🔒 PII Redaction
- **Email Addresses**: `user@domain.com` → `[REDACTED EMAIL]`
- **Phone Numbers**: `(555) 123-4567` → `[REDACTED PHONE]`
- **Credit Card Numbers**: `1234-5678-9012-3456` → `[REDACTED CARD]`

### 🤖 AI Analysis
- **Summary**: Concise overview of the call
- **Sentiment Analysis**: Customer sentiment throughout the call
- **Coaching Tips**: Agent performance recommendations
- **Next Steps**: Action items and follow-ups

### 🛡️ Security Features
- PII is automatically redacted before sending to OpenAI
- Secure API calls using Salesforce Named Credentials
- Comprehensive error handling and logging
- Token limit management to prevent API failures

## Setup Instructions

### 1. Named Credential Configuration

Create a Named Credential in Salesforce Setup:

1. Go to **Setup** → **Security** → **Named Credentials**
2. Click **New Named Credential**
3. Configure as follows:
   - **Label**: `OpenAI_API`
   - **Name**: `OpenAI_API`
   - **URL**: `https://api.openai.com`
   - **Identity Type**: `Named Principal`
   - **Authentication Protocol**: `OAuth 2.0`
   - **Authentication Provider**: Create a new Auth Provider for OpenAI
   - **Scope**: `openai`
   - **Authentication Status**: `Authenticated`

### 2. Authentication Provider Setup

1. Go to **Setup** → **Security** → **Auth. Providers**
2. Click **New**
3. Configure as follows:
   - **Provider Type**: `OpenAI`
   - **Name**: `OpenAI`
   - **Client ID**: Your OpenAI API key
   - **Client Secret**: Leave blank (not required for API key auth)
   - **Authorize Endpoint URL**: `https://api.openai.com/v1/auth`
   - **Token Endpoint URL**: `https://api.openai.com/v1/token`

### 3. Deploy Components

Deploy the following components to your Salesforce org:

#### Apex Classes
- `TranscriptRedactionService.cls` - PII redaction service
- `OpenAITranscriptAnalyzer.cls` - OpenAI integration service
- `TranscriptRedactionServiceTest.cls` - Test class for redaction service
- `OpenAITranscriptAnalyzerTest.cls` - Test class for OpenAI service

#### Lightning Web Components
- `transcriptRedactor/` - Main LWC component with UI

### 4. API Key Configuration

**Important**: Never hardcode API keys in Apex code. Use Named Credentials instead.

For testing purposes, you can temporarily modify the `OpenAITranscriptAnalyzer.cls` to use a custom setting or environment variable for the API key, but this is not recommended for production.

## Usage

### Basic Redaction
1. Paste your call transcript into the input area
2. Click **"Redact PII"** to remove sensitive information
3. Copy the redacted transcript for safe storage

### AI Analysis
1. Paste your call transcript into the input area
2. Select an analysis type from the dropdown:
   - **Summary**: Get a concise overview
   - **Sentiment**: Analyze customer sentiment
   - **Coaching**: Get agent performance tips
   - **Next Steps**: Identify action items
3. Click **"Analyze with AI"**
4. Review the AI-generated insights

## Sample Prompts

The system uses the following prompt templates for different analysis types:

### Summary
```
Analyze the following customer service call transcript and provide insights. 
The transcript has been redacted for privacy. 
Provide your response in JSON format with the specified fields.

Transcript:
[REDACTED TRANSCRIPT]

Provide a concise summary (2-3 sentences) of the call in JSON format: {"summary": "call summary here"}
```

### Sentiment
```
Analyze the following customer service call transcript and provide insights. 
The transcript has been redacted for privacy. 
Provide your response in JSON format with the specified fields.

Transcript:
[REDACTED TRANSCRIPT]

Analyze the customer sentiment throughout the call in JSON format: {"overall_sentiment": "positive/negative/neutral", "sentiment_details": "explanation of sentiment changes"}
```

### Coaching
```
Analyze the following customer service call transcript and provide insights. 
The transcript has been redacted for privacy. 
Provide your response in JSON format with the specified fields.

Transcript:
[REDACTED TRANSCRIPT]

Provide coaching tips for the agent in JSON format: {"coaching_tips": ["tip1", "tip2", "tip3"], "overall_performance": "positive/needs_improvement"}
```

### Next Steps
```
Analyze the following customer service call transcript and provide insights. 
The transcript has been redacted for privacy. 
Provide your response in JSON format with the specified fields.

Transcript:
[REDACTED TRANSCRIPT]

Identify next steps and action items in JSON format: {"next_steps": ["step1", "step2"], "priority": "high/medium/low", "estimated_completion": "timeframe"}
```

## Example Responses

### Summary Response
```json
{
  "summary": "Customer called to update their payment method and confirm order details. Agent successfully processed the payment update and provided order confirmation. Call was resolved satisfactorily."
}
```

### Sentiment Response
```json
{
  "overall_sentiment": "positive",
  "sentiment_details": "Customer started with slight frustration but became satisfied after agent resolved their payment issue efficiently."
}
```

### Coaching Response
```json
{
  "coaching_tips": [
    "Excellent active listening skills",
    "Could improve by offering additional services proactively",
    "Good problem resolution time"
  ],
  "overall_performance": "positive"
}
```

### Next Steps Response
```json
{
  "next_steps": [
    "Send confirmation email to customer",
    "Update customer profile with new payment method",
    "Follow up in 24 hours to ensure satisfaction"
  ],
  "priority": "medium",
  "estimated_completion": "24 hours"
}
```

## Security Considerations

### PII Protection
- All transcripts are automatically redacted before sending to OpenAI
- No PII is ever transmitted to external APIs
- Redaction patterns are comprehensive and regularly updated

### API Security
- Uses Salesforce Named Credentials for secure API calls
- API keys are never exposed in client-side code
- All API calls are logged for audit purposes

### Error Handling
- Comprehensive exception handling prevents system crashes
- Failed API calls don't affect the redaction functionality
- Detailed error messages help with troubleshooting

## Configuration Options

### Token Limits
The system automatically manages OpenAI token limits:
- **Input Limit**: 3,000 tokens (≈12,000 characters)
- **Response Limit**: 1,000 tokens
- **Model**: GPT-3.5-turbo (configurable)

### Timeout Settings
- **API Timeout**: 30 seconds
- **Retry Logic**: Built-in error handling with fallback responses

## Troubleshooting

### Common Issues

1. **Named Credential Not Found**
   - Ensure the Named Credential is properly configured
   - Check that the name matches exactly: `OpenAI_API`

2. **API Authentication Errors**
   - Verify your OpenAI API key is valid
   - Check that the API key has sufficient credits

3. **Token Limit Exceeded**
   - The system automatically truncates long transcripts
   - Consider breaking very long calls into smaller segments

4. **JSON Parsing Errors**
   - The system includes fallback parsing for malformed responses
   - Check the debug logs for detailed error information

### Debug Information
Enable debug logs in Salesforce Setup to monitor:
- API call success/failure rates
- Token usage statistics
- Redaction effectiveness
- Error patterns

## Development

### Adding New Redaction Patterns
Edit `TranscriptRedactionService.cls` to add new regex patterns:

```apex
private static String redactNewPattern(String text) {
    String pattern = 'your-regex-pattern';
    return text.replaceAll(pattern, '[REDACTED TYPE]');
}
```

### Adding New Analysis Types
Edit `OpenAITranscriptAnalyzer.cls` to add new analysis types:

```apex
when 'new_type' {
    return basePrompt + 'Your custom prompt here';
}
```

### Customizing Prompts
Modify the `generatePrompt()` method to customize AI prompts for your specific use case.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions:
1. Check the debug logs in Salesforce Setup
2. Review the error messages in the component
3. Verify your OpenAI API configuration
4. Test with the sample data provided

## Changelog

### Version 1.0
- Initial release with PII redaction
- OpenAI GPT integration
- Four analysis types (summary, sentiment, coaching, next steps)
- Secure API handling with Named Credentials
- Comprehensive error handling and logging 