@echo off
echo ========================================
echo Salesforce Transcript Redactor Deployment
echo ========================================
echo.

echo Deploying Apex Classes...
sfdx force:source:deploy -p force-app/main/default/classes/TranscriptRedactionService.cls
sfdx force:source:deploy -p force-app/main/default/classes/TranscriptRedactionService.cls-meta.xml
sfdx force:source:deploy -p force-app/main/default/classes/TranscriptRedactionServiceTest.cls
sfdx force:source:deploy -p force-app/main/default/classes/TranscriptRedactionServiceTest.cls-meta.xml

echo.
echo Deploying OpenAI Integration Classes...
sfdx force:source:deploy -p force-app/main/default/classes/OpenAITranscriptAnalyzer.cls
sfdx force:source:deploy -p force-app/main/default/classes/OpenAITranscriptAnalyzer.cls-meta.xml
sfdx force:source:deploy -p force-app/main/default/classes/OpenAITranscriptAnalyzerTest.cls
sfdx force:source:deploy -p force-app/main/default/classes/OpenAITranscriptAnalyzerTest.cls-meta.xml

echo.
echo Deploying Lightning Web Component...
sfdx force:source:deploy -p force-app/main/default/lwc/transcriptRedactor/

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Configure Named Credential 'OpenAI_API' in Salesforce Setup
echo 2. Set up Authentication Provider for OpenAI
echo 3. Test the component with sample data
echo.
pause 