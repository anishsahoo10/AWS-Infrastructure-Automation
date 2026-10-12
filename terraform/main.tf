locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Fetch available Availability Zones in the chosen region
data "aws_availability_zones" "available" {
  state = "available"
}
