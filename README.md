# AWS Infrastructure Automation

[![Terraform CI](https://github.com/<your-username>/aws-infrastructure-automation/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/<your-username>/aws-infrastructure-automation/actions)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud%20Infrastructure-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An enterprise-ready Infrastructure as Code (IaC) project demonstrating automated provisioning, validation, remote administration, and safe destruction of AWS network and compute resources using **Terraform** and **GitHub Actions**.

---

## 📌 Project Highlights & Resume Points

- **Infrastructure as Code (IaC):** Automated reproducible AWS network (`VPC`, `Public Subnet`, `Internet Gateway`, `Route Tables`) and compute (`EC2 Amazon Linux 2023`, `Security Groups`) provisioning using modular Terraform configurations, eliminating manual console drift.
- **CI/CD Pipeline:** Built an automated GitHub Actions CI pipeline executing Terraform syntax validation, style checks (`terraform fmt`), and automated plan generation on pull requests and branch pushes.
- **Security & Least Privilege:** Enforced cloud security best practices by externalizing secrets, restricting SSH inbound CIDRs, implementing principle of least privilege, and excluding Terraform state and sensitive variables from version control.
- **Automated Verification & Zero-Cost Teardown:** Implemented cross-platform verification scripts (Bash and PowerShell) to confirm web server health and AWS instance state, with documented teardown workflows to ensure zero ongoing cloud costs.

---

## 🏗️ Architecture Overview

The Terraform configuration provisions an isolated, secure, and internet-accessible cloud environment:

```
+-----------------------------------------------------------------------+
|  AWS Cloud (Region: us-east-1)                                        |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |  VPC (10.0.0.0/16)                                              |  |
|  |                                                                 |  |
|  |   +--------------------------+    +--------------------------+  |  |
|  |   | Internet Gateway         |    | Route Table              |  |  |
|  |   | (igw)                    |<-->| (0.0.0.0/0 -> igw)       |  |  |
|  |   +--------------------------+    +--------------------------+  |  |
|  |                                                |                 |  |
|  |                                                v                 |  |
|  |   +-----------------------------------------------------------+ |  |
|  |   | Public Subnet (10.0.1.0/24)                               | |  |
|  |   |                                                           | |  |
|  |   |   +----------------------------------------------------+  | |  |
|  |   |   | Security Group                                     |  | |  |
|  |   |   |   - Ingress: Port 22 (SSH), Port 80 (HTTP)         |  | |  |
|  |   |   |   - Egress:  All Outbound Traffic                  |  | |  |
|  |   |   |                                                    |  | |  |
|  |   |   |   +----------------------------------------------+ |  | |  |
|  |   |   |   | EC2 Instance (t2.micro / t3.micro)           | |  | |  |
|  |   |   |   | OS: Amazon Linux 2023                        | |  | |  |
|  |   |   |   | User Data: Systemd HTTP Service              | |  | |  |
|  |   |   |   | Public IP: Dynamic Elastic/Public IPv4       | |  | |  |
|  |   |   |   +----------------------------------------------+ |  | |  |
|  |   |   +----------------------------------------------------+  | |  |
|  |   +-----------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

---

## 📂 Repository Structure

```text
aws-infrastructure-automation/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml      # CI workflow for format, validate, and plan
├── terraform/
│   ├── versions.tf               # Terraform and AWS provider versions
│   ├── providers.tf              # AWS provider configuration & default tags
│   ├── variables.tf              # Configurable parameters (region, CIDRs, keys)
│   ├── main.tf                   # Locals and shared data sources
│   ├── networking.tf             # VPC, Subnet, Internet Gateway, and Route Tables
│   ├── security.tf               # Security Group ingress and egress rules
│   ├── compute.tf                # EC2 instance, AMI lookup, and user-data script
│   ├── outputs.tf                # Outputs for IPs, URLs, IDs, and SSH strings
│   └── terraform.tfvars.example  # Sample variable overrides template
├── scripts/
│   ├── verify.sh                 # Linux/macOS automated deployment check
│   └── verify.ps1                # Windows PowerShell automated deployment check
├── .gitignore                    # Excludes .tfstate, keys, secrets, and cache
├── README.md                     # Documentation and execution guide
└── LICENSE                       # MIT License
```

---

## ⚙️ Prerequisites & Tool Installation

### 1. Install Required Tools

#### Windows (via winget or choco):
```powershell
# Install Terraform
winget install Hashicorp.Terraform

# Install AWS CLI
winget install Amazon.AWSCLI
```

#### macOS (via Homebrew):
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform awscli
```

#### Linux (Ubuntu/Debian):
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform awscli
```

### 2. Configure AWS Credentials

Ensure your IAM user or role has permissions for VPC and EC2 provisioning (`AmazonEC2FullAccess` or a tailored least-privilege policy):

```bash
aws configure
# AWS Access Key ID [None]: <YOUR_ACCESS_KEY>
# AWS Secret Access Key [None]: <YOUR_SECRET_KEY>
# Default region name [None]: us-east-1
# Default output format [None]: json
```

Verify authentication:
```bash
aws sts get-caller-identity
```

---

## 🚀 Step-by-Step Deployment Guide

### Step 1: Clone Repository & Review Configuration

```bash
git clone https://github.com/<your-username>/aws-infrastructure-automation.git
cd aws-infrastructure-automation/terraform
```

Optional: Copy the example variables file to customize settings:
```bash
cp terraform.tfvars.example terraform.tfvars
```
*(Tip: Update `allowed_ssh_cidr` with your personal IP address to restrict access securely).*

### Step 2: Initialize Terraform

Downloads the AWS provider plugin and initializes working state:
```bash
terraform init
```

### Step 3: Validate and Format Configuration

```bash
# Check formatting
terraform fmt -check

# Validate configuration syntax
terraform validate
```

### Step 4: Generate Execution Plan

Inspect the 6 resources scheduled for creation:
```bash
terraform plan -out=tfplan
```

### Step 5: Provision Infrastructure

Apply the plan to create the resources in AWS:
```bash
terraform apply tfplan
```
*Deployment typically completes in ~30–45 seconds.*

Outputs displayed upon completion:
- `instance_public_ip`
- `verification_url`
- `vpc_id`
- `ssh_command`

---

## 🧪 Verification & Testing

### Option A: Using the Automated Verification Script

#### Windows (PowerShell):
```powershell
.\scripts\verify.ps1
```

#### Linux / macOS (Bash):
```bash
chmod +x scripts/verify.sh
./scripts/verify.sh
```

### Option B: Manual Testing

1. **Browser / HTTP Check:** Open the `verification_url` output (e.g. `http://<instance-public-ip>`) in your browser or run:
   ```bash
   curl http://<instance-public-ip>
   ```
   You will see the deployment status confirmation card:
   > **Deployment Status: HEALTHY** (Provisioned by Terraform)

2. **SSH Connection (Optional):**
   If an SSH key pair was provided in `terraform.tfvars`:
   ```bash
   ssh -i /path/to/private-key.pem ec2-user@<instance-public-ip>
   ```

---

## 🔄 GitHub Actions CI Setup

The repository includes `.github/workflows/terraform-ci.yml`.

Every pull request or push triggers automated checks:
1. **Terraform Formatting (`terraform fmt -check`)**
2. **Terraform Initialization (`terraform init -backend=false`)**
3. **Terraform Validation (`terraform validate`)**
4. **Terraform Plan (`terraform plan`)** *(Runs if repository secrets are provided)*

### Adding GitHub Secrets (Optional for Live Plan Step):
Navigate to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**:
- `AWS_ACCESS_KEY_ID`: Your IAM user access key
- `AWS_SECRET_ACCESS_KEY`: Your IAM user secret key
- `AWS_REGION`: `us-east-1` (optional)

*Note: The CI workflow is strictly validation and planning; it does not automatically modify or apply changes to AWS.*

---

## 🧹 Resource Cleanup (Teardown)

To avoid incurring unexpected charges, always destroy the resources after completing your demonstration or tests:

```bash
cd terraform
terraform destroy -auto-approve
```

Verify that all resources have been removed:
```bash
terraform show
```

---

## 💰 Cost Optimization & Free Tier Compliance

- **Compute:** Default is configured for `t2.micro` (or `t3.micro`), which falls under the AWS 12-Month Free Tier (750 hours/month).
- **Networking:** Basic VPC, Subnets, and Internet Gateways do not incur hourly charges in AWS.
- **Teardown Discipline:** Destroying the infrastructure when inactive guarantees zero billable footprint.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
