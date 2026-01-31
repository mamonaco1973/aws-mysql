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
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"

    # Open to all IPv4 addresses (unsafe for production).
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ----------------------------------------------------------------------------
  # OUTBOUND RULES
  # ----------------------------------------------------------------------------
  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

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
