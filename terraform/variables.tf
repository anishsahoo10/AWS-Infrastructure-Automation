variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix used for naming and tagging resources"
  type        = string
  default     = "aws-infra-automation"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the Virtual Private Cloud (VPC)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro is the standard AWS Free Tier eligible type)"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "List of CIDR blocks allowed to connect via SSH. For production or personal testing, restrict to your public IP (e.g., ['203.0.113.50/32'])"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_public_key" {
  description = "Optional SSH public key string (e.g., contents of ~/.ssh/id_rsa.pub or generated key). If provided, an EC2 Key Pair will be provisioned."
  type        = string
  default     = ""
}

variable "existing_key_pair_name" {
  description = "Optional name of an existing EC2 Key Pair in AWS to attach to the instance (used if ssh_public_key is not set)"
  type        = string
  default     = ""
}
