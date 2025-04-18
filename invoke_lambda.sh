#!/bin/bash

# Variables
FUNCTION_NAME="lambda_playwright_generic"
S3_BUCKET="your_bucket_name"  # Replace with your bucket name
OUTPUT_KEY="your_saved_webpage_name.html"

# Get URL from command line argument or use default
URL="${1:-https://your_webpage.com/}"

echo "Invoking Lambda function..."
echo "URL: $URL"
echo "Output will be saved to: s3://${S3_BUCKET}/${OUTPUT_KEY}"

# Create the payload with formatted JSON
PAYLOAD=$(cat << EOF
{
    "url": "${URL}",
    "bucket": "${S3_BUCKET}",
    "outputKey": "${OUTPUT_KEY}"
}
EOF
)

# Invoke Lambda and save response
aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload "$PAYLOAD" \
    --cli-binary-format raw-in-base64-out \
    response.json

# Check if invocation was successful
if [ $? -eq 0 ]; then
    echo "Lambda invoked successfully!"
    echo "Response saved to response.json"
    cat response.json
else
    echo "Error invoking Lambda function"
    exit 1
fi