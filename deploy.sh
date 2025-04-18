#!/bin/bash

# Set variables
ECR_REGION="us-east-1"
# ECR_ACCOUNT_ID="YOUR_ACCOUNT_NUMBER"
ECR_REPOSITORY_NAME="container-playwright"
IMAGE_TAG="latest"
IMAGE_URI="$ECR_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$IMAGE_TAG"
LAMBDA_FUNCTION_NAME="lambda_playwright_generic"
LAMBDA_ROLE_ARN="arn:aws:iam::$ECR_ACCOUNT_ID:role/LambdaPlaywrightRole"

cd container

# Build the Docker image
docker build --platform linux/amd64 -t docker-image:test .

# Authenticate Docker to the ECR registry
aws ecr get-login-password --region $ECR_REGION | docker login --username AWS --password-stdin $ECR_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com

# Check if the ECR repository exists and delete it if it does
REPO_EXISTS=$(aws ecr describe-repositories --region $ECR_REGION --repository-names $ECR_REPOSITORY_NAME 2>&1 || true)
if [[ $REPO_EXISTS != *"RepositoryNotFoundException"* ]]; then
    echo "ECR repository exists. Deleting..."
    aws ecr delete-repository --repository-name $ECR_REPOSITORY_NAME --region $ECR_REGION --force
fi

# Create the ECR repository
aws ecr create-repository --repository-name $ECR_REPOSITORY_NAME --region $ECR_REGION --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE

# Tag the Docker image
docker tag docker-image:test $IMAGE_URI

# Push the Docker image to ECR
docker push $IMAGE_URI

# Check if the Lambda function exists and delete it if it does
LAMBDA_EXISTS=$(aws lambda get-function --function-name $LAMBDA_FUNCTION_NAME 2>&1 || true)
if [[ $LAMBDA_EXISTS != *"ResourceNotFoundException"* ]]; then
    echo "Lambda function exists. Deleting..."
    aws lambda delete-function --function-name $LAMBDA_FUNCTION_NAME
fi

# Create the Lambda function
aws lambda create-function \
  --function-name $LAMBDA_FUNCTION_NAME \
  --memory-size 1024 \
  --timeout 900 \
  --package-type Image \
  --code ImageUri=$IMAGE_URI \
  --role $LAMBDA_ROLE_ARN 

echo "Lambda function created successfully!"