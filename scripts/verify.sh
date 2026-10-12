#!/usr/bin/env bash
# ==============================================================================
# AWS Infrastructure Automation - Verification Script
# ==============================================================================
# This script verifies that the provisioned AWS infrastructure is active,
# accessible over the internet, and responding correctly.
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   AWS Infrastructure Automation - Verification    ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Navigate to the terraform directory if not already there
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$REPO_ROOT/terraform"

if [ ! -d "$TERRAFORM_DIR" ]; then
  echo -e "${RED}[ERROR] terraform directory not found at: $TERRAFORM_DIR${NC}"
  exit 1
fi

cd "$TERRAFORM_DIR"

echo -e "\n${YELLOW}[1/4] Reading Terraform outputs...${NC}"

if ! terraform output > /dev/null 2>&1; then
  echo -e "${RED}[ERROR] No Terraform state found or 'terraform output' failed.${NC}"
  echo -e "Make sure you have run 'terraform apply' inside the 'terraform/' directory."
  exit 1
fi

INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
SUBNET_ID=$(terraform output -raw public_subnet_id 2>/dev/null || echo "")
VERIFY_URL=$(terraform output -raw verification_url 2>/dev/null || echo "")

if [ -z "$INSTANCE_IP" ]; then
  echo -e "${RED}[ERROR] Could not extract instance_public_ip output.${NC}"
  exit 1
fi

echo -e "  VPC ID:        ${GREEN}$VPC_ID${NC}"
echo -e "  Subnet ID:     ${GREEN}$SUBNET_ID${NC}"
echo -e "  Instance ID:   ${GREEN}$INSTANCE_ID${NC}"
echo -e "  Public IP:     ${GREEN}$INSTANCE_IP${NC}"
echo -e "  URL:           ${GREEN}$VERIFY_URL${NC}"

echo -e "\n${YELLOW}[2/4] Testing HTTP Connectivity via curl...${NC}"
echo "Sending HTTP GET request to: $VERIFY_URL"

MAX_RETRIES=6
RETRY_DELAY=5
SUCCESS=false

for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempt $i of $MAX_RETRIES..."
  if HTTP_RESPONSE=$(curl -s --connect-timeout 5 "$VERIFY_URL"); then
    if echo "$HTTP_RESPONSE" | grep -qi "AWS Infrastructure Automation"; then
      SUCCESS=true
      break
    fi
  fi
  if [ "$i" -lt "$MAX_RETRIES" ]; then
    echo "EC2 user-data script may still be initializing. Retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
  fi
done

if [ "$SUCCESS" = true ]; then
  echo -e "${GREEN}[SUCCESS] HTTP verification check passed!${NC}"
  echo -e "The EC2 web server responded successfully with healthy status."
else
  echo -e "${YELLOW}[WARNING] Could not reach HTTP endpoint or response was unexpected.${NC}"
  echo -e "The instance might still be booting or security group rules may restrict access."
fi

echo -e "\n${YELLOW}[3/4] Checking AWS CLI State (optional)...${NC}"
if command -v aws >/dev/null 2>&1; then
  echo "Querying EC2 instance status from AWS API..."
  aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]" --output table || true
else
  echo "AWS CLI is not installed locally. Skipping AWS API status check."
fi

echo -e "\n${YELLOW}[4/4] Remote SSH Access Information:${NC}"
SSH_CMD=$(terraform output -raw ssh_command 2>/dev/null || echo "")
echo -e "  Command: ${GREEN}$SSH_CMD${NC}"
echo -e "  (Requires that your public key was provided and port 22 is allowed)"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   Verification Complete!                           ${NC}"
echo -e "${GREEN}====================================================${NC}"
