# App Runner service
resource "aws_apprunner_service" "phpmyadmin_rds" {
  service_name = "phpmyadmin-rds"

  source_configuration {

    auto_deployments_enabled = false

    image_repository {
      image_identifier      = "public.ecr.aws/docker/library/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC" 

      image_configuration {
        port = "80"
        runtime_environment_variables = {
          PMA_HOST     = split(":", aws_db_instance.mysql_rds.endpoint)[0]
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


# App Runner service
resource "aws_apprunner_service" "phpmyadmin_aurora" {
  service_name = "phpmyadmin-aurora"

  source_configuration {

    auto_deployments_enabled = false

    image_repository {
      image_identifier      = "public.ecr.aws/docker/library/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        port = "80"
        runtime_environment_variables = {
          PMA_HOST     = split(":", aws_rds_cluster.aurora_cluster.endpoint)[0]
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

# # Outputs
# output "apprunner_service_url" {
#   value = aws_apprunner_service.phpmyadmin.service_url
# }