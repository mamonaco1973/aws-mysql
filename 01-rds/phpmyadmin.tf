
# IAM role for App Runner
resource "aws_iam_role" "apprunner_access_role" {
  name = "apprunner-public-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

# Optional: IAM policy for additional permissions (e.g., Secrets Manager or VPC access)
resource "aws_iam_policy" "apprunner_policy" {
  name        = "apprunner-policy"
  description = "Policy for App Runner to access resources"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "*" # Replace with specific Secrets Manager ARN for production
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_policy_attachment" {
  role       = aws_iam_role.apprunner_access_role.name
  policy_arn = aws_iam_policy.apprunner_policy.arn
}

# App Runner service
resource "aws_apprunner_service" "phpmyadmin" {
  service_name = "phpmyadmin"

  source_configuration {
    image_repository {
      image_identifier      = "public.ecr.aws/docker/library/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC" # Works for Docker Hub

      image_configuration {
        port = "80"
        runtime_environment_variables = {
          PMA_HOST     = split(":", aws_db_instance.mysql_rds.endpoint)[0]
          PMA_USER     = "admin"
          PMA_PASSWORD = random_password.mysql_password.result
        }
      }
    }

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access_role.arn
    }
  }

  instance_configuration {
    cpu    = "1024" # 1 vCPU
    memory = "2048" # 2GB RAM
  }

  health_check_configuration {
    protocol            = "TCP"
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
}

# Outputs
output "apprunner_service_url" {
  value = aws_apprunner_service.phpmyadmin.service_url
}