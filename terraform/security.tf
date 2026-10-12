# ---------------------------------------------------------------------------------------------------------------------
# SECURITY: SECURITY GROUP FOR COMPUTE INSTANCES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for EC2 instance allowing SSH and HTTP traffic"
  vpc_id      = aws_vpc.main.id

  # Inbound SSH rule
  ingress {
    description = "Allow SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # Inbound HTTP rule (used for verification)
  ingress {
    description = "Allow HTTP inbound for verification"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule (allow all traffic out)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}
