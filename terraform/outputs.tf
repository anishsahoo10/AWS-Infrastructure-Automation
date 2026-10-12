# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS: USEFUL NON-SENSITIVE DEPLOYMENT INFORMATION
# ---------------------------------------------------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the Public Subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "The ID of the EC2 Security Group"
  value       = aws_security_group.ec2_sg.id
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name assigned to the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "verification_url" {
  description = "Direct HTTP URL to verify the deployment in a web browser or via curl"
  value       = "http://${aws_instance.app_server.public_ip}"
}

output "ssh_command" {
  description = "Helper SSH command to log in to the Linux instance (replace path to private key if applicable)"
  value       = "ssh -i <path-to-private-key.pem> ec2-user@${aws_instance.app_server.public_ip}"
}
