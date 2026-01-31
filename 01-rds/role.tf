# ================================================================================
# IAM ROLE: EC2 SYSTEMS MANAGER (SSM)
# ================================================================================
# Defines an IAM role and instance profile that allow EC2 instances to
# register with and be managed by AWS Systems Manager (SSM).
# ================================================================================

# --------------------------------------------------------------------------------
# RESOURCE: aws_iam_role.ec2_ssm_role
# --------------------------------------------------------------------------------
# Creates an IAM role that can be assumed by EC2 instances.
# The trust policy explicitly allows the EC2 service to assume this role
# via the AWS Security Token Service (STS).
# --------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2SSMRole-PHPMyAdmin"

  # Trust policy allowing EC2 instances to assume this IAM role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      # Restricts role assumption to the EC2 service only
      Principal = {
        Service = "ec2.amazonaws.com"
      }

      # Grants permission to request temporary credentials
      Action = "sts:AssumeRole"
    }]
  })
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_iam_role_policy_attachment.attach_ssm_policy_2
# --------------------------------------------------------------------------------
# Attaches the AmazonSSMManagedInstanceCore managed policy.
# This policy is required for EC2 instances to register with SSM and
# be managed using Session Manager, Run Command, and Patch Manager.
# --------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "attach_ssm_policy_2" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_iam_role_policy_attachment.attach_ssm_parameter_policy
# --------------------------------------------------------------------------------
# Attaches full Systems Manager permissions.
# This grants broad access to SSM features and should be restricted
# or replaced with a custom policy in production environments.
# --------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "attach_ssm_parameter_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# --------------------------------------------------------------------------------
# RESOURCE: aws_iam_instance_profile.ec2_ssm_profile
# --------------------------------------------------------------------------------
# Creates an IAM instance profile that binds the SSM IAM role to EC2
# instances, enabling the role to be attached at launch time.
# --------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "EC2SSMProfile-PHPMyAdmin"
  role = aws_iam_role.ec2_ssm_role.name
}