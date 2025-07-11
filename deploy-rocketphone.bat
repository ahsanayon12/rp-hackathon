@echo off
echo ========================================
echo Rocketphone AI Redaction Deployment
echo ========================================
echo.

REM Check if SFDX is installed
sfdx --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: SFDX CLI is not installed or not in PATH
    echo Please install SFDX CLI first: https://developer.salesforce.com/tools/sfdxcli
    pause
    exit /b 1
)

echo Step 1: Validating deployment...
echo.

REM Validate the deployment
sfdx force:source:deploy -p . --checkonly --json
if %errorlevel% neq 0 (
    echo ERROR: Deployment validation failed
    echo Please check the errors above and fix them before proceeding
    pause
    exit /b 1
)

echo.
echo Step 2: Deploying to Sandbox...
echo.

REM Deploy to sandbox (replace 'your-sandbox-alias' with your actual sandbox alias)
sfdx force:source:deploy -p . -u your-sandbox-alias --json
if %errorlevel% neq 0 (
    echo ERROR: Sandbox deployment failed
    pause
    exit /b 1
)

echo.
echo Step 3: Running tests...
echo.

REM Run tests
sfdx force:apex:test:run -u your-sandbox-alias --json
if %errorlevel% neq 0 (
    echo WARNING: Some tests failed, but deployment may still be successful
    echo Check the test results above
)

echo.
echo Step 4: Assigning permission sets...
echo.

REM Assign permission sets (create these first in your org)
REM sfdx force:user:permset:assign -n "AI_Redaction_User" -u your-sandbox-alias

echo.
echo Step 5: Setting up named credentials...
echo.
echo IMPORTANT: You need to manually configure the following named credentials:
echo - OpenAI_API
echo - Azure_Cognitive_Services  
echo - AWS_Comprehend
echo - HuggingFace_API
echo.
echo Go to Setup > Security > Named Credentials to configure them.
echo.

echo Step 6: Setting up remote site settings...
echo.
echo IMPORTANT: You need to manually add the following remote site settings:
echo - https://api.openai.com
echo - https://api.cognitive.microsoft.com
echo - https://comprehend.amazonaws.com
echo - https://api-inference.huggingface.co
echo.
echo Go to Setup > Security > Remote Site Settings to add them.
echo.

echo Step 7: Creating custom objects...
echo.
echo IMPORTANT: You need to manually create the Transcript_Record__c custom object
echo with the following fields:
echo - Original_Transcript__c (Long Text Area)
echo - Redacted_Transcript__c (Long Text Area)
echo - Processing_Status__c (Picklist)
echo - Redaction_Level__c (Picklist)
echo - Model_Used__c (Text)
echo - Confidence_Score__c (Number)
echo - Processing_Time__c (Number)
echo - Error_Message__c (Long Text Area)
echo - Rocketphone_Call_Id__c (Text)
echo - AI_Analysis_Results__c (Long Text Area)
echo.

echo Step 8: Adding fields to Call object...
echo.
echo IMPORTANT: You need to manually add these fields to your Call__c object:
echo - Transcript__c (Long Text Area)
echo - Redaction_Processed__c (Checkbox)
echo - Redaction_Record_Id__c (Text)
echo - Redaction_Error__c (Long Text Area)
echo.

echo ========================================
echo Deployment to Sandbox Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Test the functionality in sandbox
echo 2. Configure named credentials with your API keys
echo 3. Set up remote site settings
echo 4. Create custom objects and fields
echo 5. Deploy to production when ready
echo.
echo To deploy to production, run:
echo sfdx force:source:deploy -p . -u your-prod-alias
echo.

pause 