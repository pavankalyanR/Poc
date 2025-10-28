# MediaLake Deployment Quick Reference Guide

## Essential Information

### Account Details
- **Account**: `ti-studios-prod`
- **Profile**: `ti-studios-profile`
- **Role**: `ITJenkinsCrossAcctRole`
- **Region**: `us-east-1`

### User Information
- **Email**: `shilpa.katragadda@people.inc`
- **Name**: `Shilpa Katragadda`
- **Environment**: `Dev`

### Required Tags (SCP Compliance)
```
owner = it-engineering@people.inc
env = poc
dept = ee
cc = it
```

## Quick Commands

### 1. Verify AWS Access
```bash
aws sts get-caller-identity --profile ti-studios-profile
```

### 2. Clone Repository
```bash
git clone https://github.com/aws-solutions-library-samples/guidance-for-medialake-on-aws.git
cd guidance-for-medialake-on-aws
```

### 3. Setup Environment
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
npm install
```

### 4. Create Service-Linked Roles
```bash
aws iam create-service-linked-role --aws-service-name es.amazonaws.com --profile ti-studios-profile
aws iam create-service-linked-role --aws-service-name opensearchservice.amazonaws.com --profile ti-studios-profile
aws iam create-service-linked-role --aws-service-name osis.amazonaws.com --profile ti-studios-profile
```

### 5. Bootstrap CDK
```bash
cdk bootstrap --profile ti-studios-profile --region us-east-1
```

### 6. Deploy All Stacks
```bash
cdk deploy --all --profile ti-studios-profile --region us-east-1
```

## Automated Deployment

### Using the Deployment Script
```bash
# Make script executable (if not already)
chmod +x deploy-medialake.sh

# Run automated deployment
./deploy-medialake.sh
```

## Configuration

### Copy Configuration Template
```bash
cp config-ti-studios-prod.json config.json
```

### Update Account ID
Replace `REPLACE_WITH_TI_STUDIOS_PROD_ACCOUNT_ID` in `config.json` with actual account ID.

## Expected Deployment Time
- **Initial Deployment**: ~1 hour
- **Subsequent Deployments**: 15-30 minutes

## Post-Deployment Checklist

- [ ] All CloudFormation stacks show `CREATE_COMPLETE`
- [ ] Welcome email received by `shilpa.katragadda@people.inc`
- [ ] Application URL accessible
- [ ] User can log in with provided credentials
- [ ] All resources have required SCP compliance tags

## Troubleshooting

### Common Issues
1. **Service-Linked Role Errors**: Create roles before deployment
2. **Permission Denied**: Verify role assumption and admin privileges
3. **CDK Bootstrap Failed**: Check AWS credentials and region
4. **Stack Creation Failed**: Check CloudFormation events for details

### Support Contacts
- **IT Engineering**: it-engineering@people.inc
- **AWS Support**: Via AWS Console
- **MediaLake Issues**: GitHub Issues page

## Cost Information
- **Base Cost**: ~$423.62/month (small deployment)
- **Variable Costs**: Based on usage
- **Recommendation**: Set up AWS Budget alerts

## Security Features
- AWS Cognito authentication
- KMS encryption
- VPC deployment
- IAM least privilege
- WAF protection

---

**Note**: This is a quick reference. For detailed instructions, refer to the complete deployment guide and task list documents.


