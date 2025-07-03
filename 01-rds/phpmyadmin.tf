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