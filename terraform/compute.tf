# ---------------------------------------------------------------------------------------------------------------------
# COMPUTE: EC2 LINUX INSTANCE AND OPTIONAL KEY PAIR
# ---------------------------------------------------------------------------------------------------------------------

# Dynamic lookup of the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Optional EC2 Key Pair created if public key is supplied
resource "aws_key_pair" "deployer" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${local.name_prefix}-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${local.name_prefix}-key"
  }
}

# EC2 Compute Instance in the Public Subnet
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  key_name = var.ssh_public_key != "" ? aws_key_pair.deployer[0].key_name : (var.existing_key_pair_name != "" ? var.existing_key_pair_name : null)

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                  <title>AWS Infrastructure Automation</title>
                  <style>
                      body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background-color: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
                      .card { background: #1e293b; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.5); border: 1px solid #334155; max-width: 500px; text-align: center; }
                      h1 { color: #38bdf8; margin-bottom: 0.5rem; font-size: 1.6rem; }
                      .badge { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 9999px; background: #22c55e20; color: #4ade80; border: 1px solid #22c55e40; font-weight: 600; font-size: 0.85rem; margin-bottom: 1.5rem; }
                      .detail { text-align: left; background: #0f172a; padding: 1rem; border-radius: 8px; font-family: monospace; font-size: 0.9rem; line-height: 1.6; }
                  </style>
              </head>
              <body>
                  <div class="card">
                      <h1>AWS Infrastructure Automation</h1>
                      <div class="badge">Deployment Status: HEALTHY</div>
                      <div class="detail">
                          <div><strong>Provisioned By:</strong> Terraform</div>
                          <div><strong>Cloud:</strong> Amazon Web Services</div>
                          <div><strong>Instance ID:</strong> $INSTANCE_ID</div>
                          <div><strong>Availability Zone:</strong> $AZ</div>
                      </div>
                  </div>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "${local.name_prefix}-instance"
  }
}
