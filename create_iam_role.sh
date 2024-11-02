#!/bin/bash

# Variables
ROLE_NAME="LambdaPlaywrightRole"
AWS_REGION="us-east-1"

echo "Creating IAM role for Lambda..."

# Create trust policy document for Lambda
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create policy document for Lambda permissions
cat > lambda-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy",
                "logs:GetLogEvents",
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::*/*",
                "arn:aws:s3:::*"
            ]
        }
    ]
}
EOF

# Check if role already exists
ROLE_EXISTS=$(aws iam get-role --role-name $ROLE_NAME 2>&1 || true)

if [[ $ROLE_EXISTS == *"NoSuchEntity"* ]]; then
    echo "Creating new role: $ROLE_NAME"
    
    # Create the IAM role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://trust-policy.json

    # Wait for role to be created
    echo "Waiting for role to be created..."
    sleep 10
else
    echo "Role $ROLE_NAME already exists. Updating policies..."
fi

# Create the custom policy
POLICY_NAME="${ROLE_NAME}Policy"
aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://lambda-policy.json \
    --description "Custom policy for Lambda Playwright function" \
    2>/dev/null || true

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Attach the custom policy to the role
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

# Attach AWS Lambda basic execution role
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

# Get and display the role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Clean up temporary files
rm -f trust-policy.json lambda-policy.json

echo "IAM role setup completed successfully!"