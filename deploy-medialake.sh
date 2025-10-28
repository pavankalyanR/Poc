#!/bin/bash

# MediaLake Deployment Script for ti-studios-prod
# This script automates the deployment process for agents

set -e  # Exit on any error

# Configuration
AWS_PROFILE="ti-studios-profile"
AWS_REGION="us-east-1"
PROJECT_DIR="$(pwd)"
LOG_FILE="medialake-deployment-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check AWS profile
check_aws_profile() {
    log "Checking AWS profile configuration..."
    
    if ! aws configure list --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        error "AWS profile '$AWS_PROFILE' not found. Please configure it first."
    fi
    
    # Get caller identity
    CALLER_INFO=$(aws sts get-caller-identity --profile "$AWS_PROFILE" 2>/dev/null)
    if [ $? -ne 0 ]; then
        error "Failed to get caller identity. Please check your AWS credentials."
    fi
    
    ACCOUNT_ID=$(echo "$CALLER_INFO" | jq -r '.Account')
    USER_ARN=$(echo "$CALLER_INFO" | jq -r '.Arn')
    
    log "Connected to AWS Account: $ACCOUNT_ID"
    log "User/Role: $USER_ARN"
    
    # Update config file with actual account ID
    if [ -f "config-ti-studios-prod.json" ]; then
        sed -i.bak "s/REPLACE_WITH_TI_STUDIOS_PROD_ACCOUNT_ID/$ACCOUNT_ID/g" config-ti-studios-prod.json
        cp config-ti-studios-prod.json config.json
        success "Updated config.json with account ID: $ACCOUNT_ID"
    else
        error "config-ti-studios-prod.json not found. Please ensure it exists."
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check required commands
    local missing_commands=()
    
    if ! command_exists aws; then
        missing_commands+=("aws")
    fi
    
    if ! command_exists cdk; then
        missing_commands+=("aws-cdk")
    fi
    
    if ! command_exists node; then
        missing_commands+=("node")
    fi
    
    if ! command_exists python3; then
        missing_commands+=("python3")
    fi
    
    if ! command_exists jq; then
        missing_commands+=("jq")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        error "Missing required commands: ${missing_commands[*]}. Please install them first."
    fi
    
    # Check versions
    log "Checking tool versions..."
    aws --version | tee -a "$LOG_FILE"
    cdk --version | tee -a "$LOG_FILE"
    node --version | tee -a "$LOG_FILE"
    python3 --version | tee -a "$LOG_FILE"
    
    success "All prerequisites met"
}

# Function to setup Python environment
setup_python_env() {
    log "Setting up Python virtual environment..."
    
    if [ ! -d ".venv" ]; then
        python3 -m venv .venv
        success "Created Python virtual environment"
    else
        log "Python virtual environment already exists"
    fi
    
    source .venv/bin/activate
    success "Activated Python virtual environment"
}

# Function to install dependencies
install_dependencies() {
    log "Installing Python dependencies..."
    pip install -r requirements.txt
    success "Python dependencies installed"
    
    log "Installing Node.js dependencies..."
    npm install
    success "Node.js dependencies installed"
}

# Function to create service-linked roles
create_service_linked_roles() {
    log "Creating required service-linked roles..."
    
    local roles=(
        "es.amazonaws.com"
        "opensearchservice.amazonaws.com"
        "osis.amazonaws.com"
    )
    
    for role in "${roles[@]}"; do
        log "Creating service-linked role: $role"
        if aws iam create-service-linked-role --aws-service-name "$role" --profile "$AWS_PROFILE" 2>/dev/null; then
            success "Created service-linked role: $role"
        else
            warning "Service-linked role $role may already exist (this is normal)"
        fi
    done
}

# Function to bootstrap CDK
bootstrap_cdk() {
    log "Bootstrapping CDK..."
    
    if cdk bootstrap --profile "$AWS_PROFILE" --region "$AWS_REGION"; then
        success "CDK bootstrap completed"
    else
        error "CDK bootstrap failed"
    fi
}

# Function to deploy stacks
deploy_stacks() {
    log "Starting CDK deployment..."
    log "This may take up to 1 hour for initial deployment..."
    
    if cdk deploy --all --profile "$AWS_PROFILE" --region "$AWS_REGION" --require-approval never; then
        success "CDK deployment completed successfully"
    else
        error "CDK deployment failed"
    fi
}

# Function to validate deployment
validate_deployment() {
    log "Validating deployment..."
    
    # Check CloudFormation stacks
    log "Checking CloudFormation stacks..."
    local stacks=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --profile "$AWS_PROFILE" --region "$AWS_REGION" --query 'StackSummaries[?contains(StackName, `MediaLake`)].StackName' --output text)
    
    if [ -n "$stacks" ]; then
        success "Found MediaLake stacks: $stacks"
    else
        warning "No MediaLake stacks found in CREATE_COMPLETE status"
    fi
    
    # Check for welcome email (this would need to be done manually)
    log "Please check the email for shilpa.katragadda@people.inc for the welcome email with application URL and credentials"
}

# Function to display deployment summary
display_summary() {
    log "=== DEPLOYMENT SUMMARY ==="
    log "AWS Account: $(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text)"
    log "Region: $AWS_REGION"
    log "Profile: $AWS_PROFILE"
    log "Environment: Dev"
    log "Initial User: shilpa.katragadda@people.inc"
    log "Log File: $LOG_FILE"
    log ""
    log "Next Steps:"
    log "1. Check email for shilpa.katragadda@people.inc for welcome email"
    log "2. Access the MediaLake application using provided URL and credentials"
    log "3. Verify all resources have required tags for SCP compliance"
    log "4. Test basic functionality of the application"
    log ""
    log "Required Tags (SCP Compliance):"
    log "- owner = it-engineering@people.inc"
    log "- env = poc"
    log "- dept = ee"
    log "- cc = it"
}

# Main deployment function
main() {
    log "Starting MediaLake deployment for ti-studios-prod"
    log "Log file: $LOG_FILE"
    
    # Pre-deployment checks
    check_prerequisites
    check_aws_profile
    
    # Environment setup
    setup_python_env
    install_dependencies
    
    # Pre-deployment tasks
    create_service_linked_roles
    bootstrap_cdk
    
    # Deployment
    deploy_stacks
    
    # Post-deployment validation
    validate_deployment
    
    # Display summary
    display_summary
    
    success "MediaLake deployment completed successfully!"
}

# Error handling
trap 'error "Deployment failed at line $LINENO"' ERR

# Run main function
main "$@"


