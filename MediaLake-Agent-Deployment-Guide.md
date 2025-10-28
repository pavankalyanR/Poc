# MediaLake Agent Deployment Guide

## Overview

This guide provides comprehensive instructions for agents to deploy AWS MediaLake into the `ti-studios-prod` AWS account using the `ti-studios-profile` user to assume the `ITJenkinsCrossAcctRole` role with admin privileges.

## Prerequisites

### AWS Account Information
- **Target Account**: `ti-studios-prod`
- **AWS Profile**: `ti-studios-profile`
- **Cross-Account Role**: `ITJenkinsCrossAcctRole`
- **Role Location**: `aws-ti-studios-prod` under `~/cursor/mcp.json`

### Required Tags (SCP Compliance)
All infrastructure must be tagged with the following mandatory tags:
- `owner = it-engineering@people.inc`
- `env = poc`
- `dept = ee`
- `cc = it`

### Initial User Configuration
- **Email**: `shilpa.katragadda@people.inc`
- **First Name**: `Shilpa`
- **Last Name**: `Katragadda`

### Environment Configuration
- **MediaLake Environment Name**: `Dev`

## Deployment Architecture

MediaLake is a comprehensive, serverless, and scalable platform for media ingestion, processing, management, metadata management, and workflow orchestration on AWS. The solution includes:

- **Storage Connectors**: S3 integration with EventBridge/S3 event handling
- **Processing Pipelines**: FIFO queue-based media processing with Step Functions orchestration
- **User Interface**: React TypeScript frontend with Cognito authentication
- **API Layer**: RESTful API with API Gateway
- **Search & Analytics**: OpenSearch for semantic search capabilities
- **Security**: AWS Cognito, KMS encryption, IAM roles, and VPC deployment options

## Required Tools and Dependencies

### System Requirements
- **AWS CLI** configured with appropriate credentials
- **AWS CDK CLI** (`npm install -g aws-cdk`)
- **Node.js** (v20.x or later)
- **Python** (3.12)
- **Docker** (for local development)
- **Git** for repository management

### Python Dependencies
```bash
aws-cdk-lib>=2.177.0
constructs>=10.0.0,<11.0.0
aws_cdk.aws_lambda_python_alpha
aws_cdk.aws_cognito_identitypool_alpha
boto3
cdk_nag
python-dotenv
pydantic
Jinja2>=3.1.5
aws-lambda-powertools
click
```

## Configuration Setup

### 1. Create Configuration File

Create a `config.json` file in the project root with the following configuration:

```json
{
  "account_id": "YOUR_AWS_ACCOUNT_ID",
  "api_path": "v1",
  "authZ": {
    "identity_providers": [
      {
        "identity_provider_method": "cognito"
      }
    ]
  },
  "environment": "dev",
  "global_prefix": "medialake",
  "initial_user": {
    "email": "shilpa.katragadda@people.inc",
    "first_name": "Shilpa",
    "last_name": "Katragadda"
  },
  "logging": {
    "api_gateway_retention_days": 90,
    "cloudwatch_retention_days": 90,
    "retention_days": 90,
    "s3_retention_days": 90,
    "waf_retention_days": 90
  },
  "opensearch_cluster_settings": {
    "availability_zone_count": 2,
    "data_node_count": 2,
    "data_node_instance_type": "t3.small.search",
    "data_node_volume_iops": 3000,
    "data_node_volume_size": 10,
    "data_node_volume_type": "gp3",
    "master_node_count": 3,
    "master_node_instance_type": "t3.small.search",
    "multi_az_with_standby_enabled": false,
    "off_peak_window_enabled": true,
    "off_peak_window_start": "20:00"
  },
  "primary_region": "us-east-1",
  "resource_application_tag": "medialake",
  "resource_prefix": "medialake",
  "vpc": {
    "new_vpc": {
      "cidr": "10.0.0.0/16",
      "enable_dns_hostnames": true,
      "enable_dns_support": true,
      "max_azs": 3,
      "vpc_name": "MediaLakeVPC"
    },
    "security_groups": {
      "new_groups": {
        "media_lake_sg": {
          "description": "MediaLake Security Group",
          "name": "MediaLakeSecurityGroup"
        },
        "opensearch_sg": {
          "description": "Allow limited access to OpenSearch",
          "name": "OpenSearchSG"
        }
      },
      "use_existing_groups": false
    },
    "use_existing_vpc": false
  }
}
```

### 2. Environment Setup

#### Python Virtual Environment
```bash
python3 -m venv .venv
source .venv/bin/activate      # Mac/Linux
# OR for Windows
.venv\Scripts\activate.bat     # Windows
```

#### Install Dependencies
```bash
pip install -r requirements.txt
npm install
```

For development:
```bash
pip install -r requirements-dev.txt
```

## Pre-Deployment Steps

### 1. AWS Service-Linked Roles Creation

Create required service-linked roles to prevent deployment issues:

```bash
aws iam create-service-linked-role --aws-service-name es.amazonaws.com --profile ti-studios-profile
aws iam create-service-linked-role --aws-service-name opensearchservice.amazonaws.com --profile ti-studios-profile
aws iam create-service-linked-role --aws-service-name osis.amazonaws.com --profile ti-studios-profile
```

**Note**: If you receive an error indicating the role already exists, you can proceed to the next step.

### 2. CDK Bootstrap

Bootstrap your AWS account for CDK deployment:

```bash
cdk bootstrap --profile ti-studios-profile --region us-east-1
```

## Deployment Process

### 1. Deploy All Stacks

Deploy all MediaLake stacks using CDK:

```bash
cdk deploy --all --profile ti-studios-profile --region us-east-1
```

### 2. Monitor Deployment

The deployment process will create multiple CloudFormation stacks:

1. **MediaLakeCloudFrontWAF** - WAF configuration (us-east-1)
2. **MediaLakeBaseInfrastructure** - Core infrastructure
3. **MediaLakeCognito** - Authentication services
4. **MediaLakeApiGatewayCore** - API Gateway core
5. **MediaLakeAuthorizationStack** - Authorization services
6. **MediaLakeStack** - Main application stack
7. **MediaLakeApiGatewayDeployment** - API deployment
8. **MediaLakeUserInterface** - Frontend application
9. **MediaLakeCognitoUpdate** - Cognito updates
10. **MediaLakeCleanupStack** - Cleanup resources

### 3. Expected Deployment Time

- **Initial deployment**: Approximately 1 hour
- **Subsequent deployments**: 15-30 minutes (depending on changes)

## Post-Deployment Validation

### 1. Verify Stack Status

Check CloudFormation console to ensure all stacks are in `CREATE_COMPLETE` status.

### 2. Welcome Email

The initial user (`shilpa.katragadda@people.inc`) will receive a welcome email containing:
- MediaLake application URL
- Username (email address)
- Temporary password

### 3. Application Access

1. Log in using the provided credentials
2. Verify the MediaLake user interface loads correctly
3. Test basic functionality (navigation, settings access)

## Infrastructure Components

### Core AWS Services

**Compute & Processing:**
- AWS Lambda (serverless compute for API handlers and media processing)
- AWS Step Functions (workflow orchestration)
- AWS MediaConvert (media transcoding)

**Storage & Database:**
- Amazon S3 (object storage for media assets and metadata)
- Amazon DynamoDB (asset metadata and configuration storage)
- Amazon OpenSearch (search and analytics engine)

**Networking & Security:**
- Amazon VPC (network isolation)
- AWS Cognito (user authentication and authorization)
- AWS KMS (encryption key management)
- AWS IAM (resource access control)
- AWS WAF (web application firewall)

**API & Integration:**
- Amazon API Gateway (REST API endpoint management)
- Amazon EventBridge (event routing and pipeline triggers)
- Amazon SQS (queues for ordered media processing)

**Monitoring & Logging:**
- Amazon CloudWatch (metrics, logging, and alerting)
- AWS X-Ray (distributed trace monitoring)

### Supported Media Types

**Audio Files:** WAV, AIFF/AIF, MP3, PCM, M4A
**Video Files:** FLV, MP4, MOV, AVI, MKV, WEBM, MXF
**Image Files:** PSD, TIF, JPG/JPEG, PNG, WEBP, GIF, SVG

## Cost Considerations

### Base Infrastructure Cost (Small Deployment)
- **Monthly cost estimate**: ~$423.62 (US East N. Virginia)
- **Variable costs**: Based on media processing volume, storage, and usage patterns

### Cost Management
- Set up AWS Budget alerts
- Monitor usage through AWS Cost Explorer
- Review and optimize OpenSearch cluster size as needed

## Security Features

- AWS Cognito authentication with support for local username/password and SAML federation
- KMS encryption for sensitive data
- CORS-enabled API endpoints
- VPC deployment for network isolation
- WAF protection for API and web traffic

## Troubleshooting

### Common Issues

1. **Service-Linked Role Errors**
   - Solution: Create required service-linked roles before deployment

2. **OpenSearch VPC Access Issues**
   - Solution: Ensure VPC configuration includes sufficient private subnets

3. **CDK Bootstrap Issues**
   - Solution: Verify AWS credentials and permissions

4. **Stack Creation Failures**
   - Solution: Check CloudFormation events for specific error details

### Support Resources

- GitHub Issues: [MediaLake Issues](https://github.com/aws-solutions-library-samples/guidance-for-medialake/issues)
- AWS Documentation: [Media Lake Guidance](https://aws.amazon.com/solutions/guidance/a-media-lake-on-aws/)

## Cleanup Procedures

### Manual Cleanup (AWS Console)
1. Go to CloudFormation console
2. Delete all stacks with prefix "Media Lake" and `medialake-cf`
3. **Important**: Manually empty and delete S3 buckets created by MediaLake
4. Delete any other associated resources as needed

**Warning**: This will permanently remove all MediaLake data and resources.

## Change Log Template

Use this template to track deployment progress:

```markdown
## Deployment Change Log

### [Date] - Deployment Initiated
- **Agent**: [Agent Name]
- **Environment**: Dev
- **Account**: ti-studios-prod
- **Status**: In Progress

### Completed Tasks
- [ ] Environment setup and dependency installation
- [ ] Configuration file creation
- [ ] Service-linked roles creation
- [ ] CDK bootstrap
- [ ] Stack deployment
- [ ] Post-deployment validation
- [ ] User access verification

### Issues Encountered
- [List any issues and resolutions]

### Next Steps
- [List remaining tasks or follow-up actions]
```

## Contact Information

- **Primary Contact**: it-engineering@people.inc
- **Initial User**: shilpa.katragadda@people.inc
- **Department**: EE (Engineering Excellence)
- **Environment**: POC (Proof of Concept)

---

*This guide is based on the AWS MediaLake solution and customized for the ti-studios-prod deployment requirements.*


