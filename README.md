# Serverless Web Scraping with Playwright and AWS Lambda

## Introduction
This project demonstrates a serverless approach to web scraping using [Playwright](https://playwright.dev/) and [AWS Lambda](https://aws.amazon.com/lambda/). Serverless web scraping is an efficient solution that allows you to scrape data without maintaining servers and only pay for compute time used during the scraping task.

The tutorial is structured around using Python with Playwright, AWS Lambda, and Docker. It covers everything from setting up IAM roles to deploying and running a containerized Lambda function on AWS.

## Prerequisites
Before starting, ensure you have the following:

- An AWS account with appropriate permissions
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Docker](https://www.docker.com/) installed on your local machine
- Basic knowledge of Python and AWS services

**Note for Windows Users:**  
This project uses shell scripts (`.sh` files). Windows users may need [WSL2](https://docs.microsoft.com/en-us/windows/wsl/) or can directly run the AWS CLI commands in the command prompt. Remember to make each script executable by running:
```bash
chmod +x script_name.sh
```

## Project Structure

```bash
├── create_iam_role.sh          # Sets up AWS IAM roles for Lambda permissions
├── deploy.sh                   # Builds Docker image and deploys to Lambda
├── invoke_lambda.sh            # Invokes the Lambda function
├── container/
│   ├── Dockerfile              # Configures the Lambda container
│   ├── lambda_function.py      # Core scraping logic
│   └── requirements.txt        # Python dependencies
```

File description:

- **create_iam_role.sh**: Sets up the necessary IAM roles with permissions for S3 and CloudWatch.
- **container/lambda_function.py**: The core scraping logic. It initializes Playwright, navigates to the target webpage, and stores the result in S3.
- **container/Dockerfile**: Defines the container environment, ensuring compatibility with Lambda and Playwright.
- **deploy.sh**: Builds the Docker image, pushes it to ECR, and deploys the Lambda function.
- **invoke_lambda.sh**: A utility script to trigger the Lambda function, specifying the target URL and S3 output location.

## Steps to Set Up and Run

### Step 1: Setting Up IAM Role

Run create_iam_role.sh to create a role named LambdaPlaywrightRole with the required permissions:

```bash
./create_iam_role.sh
```

## Step 2: Lambda Function Code

The Lambda function (lambda_function.py) uses Playwright to navigate to a given URL and upload the page's HTML content to S3.

Key Parts of the Code
- Asynchronous Execution: Allows Playwright to handle tasks concurrently.
- Scrolling: Automatically scrolls to the bottom of the page to load dynamic content.
- S3 Upload: Stores the page content in an S3 bucket for easy retrieval.

## Step 3: Deploying the Lambda Function

To handle complex dependencies, package the function in a Docker container using the Dockerfile. Run deploy.sh to build the Docker image, push it to ECR, and deploy it to Lambda.

```bash
./deploy.sh
```

Note: Modify ECR_ACCOUNT_ID, ECR_REGION, and LAMBDA_ROLE_ARN as needed in deploy.sh.

## Step 4: Testing the Lambda Function

Use invoke_lambda.sh to test the Lambda function. Customize the parameters to specify the target URL, S3 bucket, and output file name.

```bash
# Basic usage with default URL
./invoke_lambda.sh

# Specify a custom URL to scrape
./invoke_lambda.sh "https://example.com"
```

The script saves the Lambda response to response.json, allowing you to check the execution details.

## Dockerfile Details

The Dockerfile uses Microsoft's Playwright image, which includes all dependencies for running browsers in a headless environment. Additional libraries are installed for compatibility with AWS Lambda.

Example:

```dockerfile
FROM mcr.microsoft.com/playwright/python:v1.45.0-jammy
...
```

This image configuration avoids manual installation of system-level dependencies and ensures that Playwright functions properly within Lambda's limited environment.

## Conclusion

Using Playwright with AWS Lambda enables efficient, serverless web scraping. By packaging the function in a Docker container, we ensure that all dependencies are compatible with Lambda. This project serves as a scalable solution for periodic scraping tasks where traditional servers are too costly or inefficient.