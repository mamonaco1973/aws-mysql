# ==============================================================================
# SECURITY GROUP: RDS MYSQL (PORT 3306)
# ==============================================================================
# Defines network access rules for MySQL-compatible RDS resources.
#
# Notes:
# - This security group allows inbound MySQL traffic on port 3306.
# - Inbound access is open to all IPv4 addresses (NOT production-safe).
# - Outbound traffic is unrestricted.
# - Intended for demos, labs, or tightly controlled test environments only.
# ==============================================================================

resource "aws_security_group" "rds_sg" {
  # ----------------------------------------------------------------------------
  # CORE IDENTIFIERS
  # ----------------------------------------------------------------------------
  # Name and description for the security group.
  name        = "rds-sg"
  description = "Allow MySQL (3306) inbound; unrestricted outbound access"

  # Associate this security group with the RDS VPC.
  vpc_id = aws_vpc.rds-vpc.id

  # ----------------------------------------------------------------------------
  # INBOUND RULES
  # ----------------------------------------------------------------------------
  # Allow MySQL traffic on TCP port 3306.
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    # Open to all IPv4 addresses (unsafe for production).
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ----------------------------------------------------------------------------
  # OUTBOUND RULES
  # ----------------------------------------------------------------------------
  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    # Unrestricted outbound access.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ----------------------------------------------------------------------------
  # TAGGING
  # ----------------------------------------------------------------------------
  tags = {
    Name = "rds-sg"
  }
}


# --------------------------------------------------------------------------------
# RESOURCE: aws_security_group.http_sg
# --------------------------------------------------------------------------------
# Description:
#   Security group for a web-facing component that serves HTTP traffic
#   on TCP port 80 (e.g., EC2, ALB, or containerized web service).
#
# Security:
#   Public HTTP access is acceptable only when paired with proper
#   hardening, authentication, and patching.
# --------------------------------------------------------------------------------
resource "aws_security_group" "http_sg" {
  name        = "http-sg"
  description = "Allow HTTP (80) inbound traffic and unrestricted egress."
  vpc_id      = aws_vpc.rds-vpc.id

  # ------------------------------------------------------------------------------
  # INGRESS: HTTP (TCP/80)
  # ------------------------------------------------------------------------------
  # Allows inbound HTTP traffic from any IPv4 address.
  # ------------------------------------------------------------------------------
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ------------------------------------------------------------------------------
  # EGRESS: All traffic
  # ------------------------------------------------------------------------------
  # Allows outbound access to backend services such as RDS or external APIs.
  # ------------------------------------------------------------------------------
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http-sg"
  }
}