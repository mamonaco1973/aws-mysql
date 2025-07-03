# Role that App Runner uses to pull images from public registry
resource "aws_iam_role" "apprunner_access_role" {
  name = "apprunner-public-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.apprunner_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# App Runner service
resource "aws_apprunner_service" "phpmyadmin" {
  service_name = "phpmyadmin"

  source_configuration {
    image_repository {
      image_identifier      = "phpmyadmin/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC"  # Docker Hub images can be pulled this way

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
}