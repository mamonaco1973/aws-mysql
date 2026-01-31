# ==================================================================================================
# Fetch the Canonical-published Ubuntu 24.04 AMI ID from AWS Systems Manager Parameter Store
# This path is maintained by Canonical; it always points at the current stable AMI for 24.04 (amd64, HVM, gp3)
# ==================================================================================================
data "aws_ssm_parameter" "ubuntu_24_04" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# ==================================================================================================
# Resolve the full AMI object using the ID returned by SSM
# - Restrict owner to Canonical to avoid spoofed AMIs
# - Filter by the exact image-id pulled above
# - most_recent is kept true as a guard when multiple matches exist in a region
# ==================================================================================================
data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.ubuntu_24_04.value]
  }
}

# ================================================================================
# RESOURCE: aws_instance.phpmyadmin_instance
# ================================================================================
# Purpose:
#   Launches an Ubuntu 24.04 EC2 instance that hosts phpMyAdmin for
#   administering an Aurora / RDS MySQL database.
#
# Architecture:
#   - Deployed in a private subnet with no public IP address
#   - Access is intended via AWS SSM Session Manager or a private proxy
#   - IAM instance profile grants Systems Manager permissions
# ================================================================================

resource "aws_instance" "phpmyadmin-rds-instance" {
  # ------------------------------------------------------------------------------
  # AMI AND INSTANCE TYPE
  # ------------------------------------------------------------------------------
  # Uses the latest Ubuntu 24.04 AMI resolved through a data source.
  # The t3.medium instance type provides sufficient resources for
  # phpMyAdmin and lightweight administrative workloads.
  # ------------------------------------------------------------------------------
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t3.medium"

  # ------------------------------------------------------------------------------
  # NETWORKING
  # ------------------------------------------------------------------------------
  # Places the instance in a private subnet without a public IP.
  # Inbound access is controlled by the associated security group.
  # ------------------------------------------------------------------------------
  subnet_id                   = aws_subnet.rds-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.http_sg.id]
  associate_public_ip_address = true

  # ------------------------------------------------------------------------------
  # IAM / SSM ACCESS
  # ------------------------------------------------------------------------------
  # Attaches an IAM instance profile that allows the EC2 instance to
  # register with AWS Systems Manager for secure, agent-based access.
  # ------------------------------------------------------------------------------
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  # ------------------------------------------------------------------------------
  # USER DATA (OPTIONAL)
  # ------------------------------------------------------------------------------
  # Renders a cloud-init script from a template to configure the
  # phpMyAdmin host at boot time. This is currently disabled.
  #
  # Example usage:
  #   - Inject database endpoint
  #   - Configure PHP, Apache/Nginx, and phpMyAdmin
  # ------------------------------------------------------------------------------
  user_data = templatefile("${path.module}/scripts/install-phpmyadmin.sh", {
    DB_ENDPOINT = split(":", aws_db_instance.mysql_rds.endpoint)[0]
    DB_USER     = "admin"
    DB_PASSWORD = random_password.mysql_password.result
    DB_PORT     = 3306

  })

  # ------------------------------------------------------------------------------
  # TAGS
  # ------------------------------------------------------------------------------
  # Identifies the instance for operational visibility and cost tracking.
  # ------------------------------------------------------------------------------
  tags = {
    Name = "phpmyadmin-rds"
  }
}

