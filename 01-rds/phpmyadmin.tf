# -------------------------------------------------------
# App Runner Service for phpMyAdmin connected to MySQL RDS
# -------------------------------------------------------
resource "aws_apprunner_service" "phpmyadmin_rds" {
  # Define the friendly name of the App Runner service
  service_name = "phpmyadmin-rds"

  # Define how the service pulls and deploys the image
  source_configuration {

    # Disable auto-deployments when the image updates (you control deploys)
    auto_deployments_enabled = false

    image_repository {
      # Reference the official phpMyAdmin image from public ECR
      image_identifier      = "public.ecr.aws/docker/library/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        # The container exposes HTTP on port 80
        port = "80"

        # Provide environment variables to phpMyAdmin
        runtime_environment_variables = {
          # Extract just the hostname portion of the RDS endpoint (before colon)
          PMA_HOST = split(":", aws_db_instance.mysql_rds.endpoint)[0]
        }
      }
    }
  }

  # Specify the compute resources for the App Runner service
  instance_configuration {
    cpu    = "1024" # Allocate 1 vCPU
    memory = "2048" # Allocate 2GB of RAM
  }

  # Configure the health check settings to monitor container health
  health_check_configuration {
    protocol            = "TCP" # Use TCP health check (basic connectivity)
    path                = "/"   # Path not strictly used for TCP
    interval            = 10    # Check every 10 seconds
    timeout             = 5     # Wait 5 seconds before marking unhealthy
    healthy_threshold   = 1     # 1 successful check to become healthy
    unhealthy_threshold = 5     # 5 failures to mark unhealthy
  }
}

# -------------------------------------------------------
# App Runner Service for phpMyAdmin connected to Aurora
# -------------------------------------------------------
resource "aws_apprunner_service" "phpmyadmin_aurora" {
  # Name of the service specifically for Aurora
  service_name = "phpmyadmin-aurora"

  source_configuration {

    # Auto-deployment is off; you must manually redeploy
    auto_deployments_enabled = false

    image_repository {
      # Use the same official phpMyAdmin container image
      image_identifier      = "public.ecr.aws/docker/library/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        # The container listens on port 80
        port = "80"

        runtime_environment_variables = {
          # Extract the Aurora cluster hostname (strip port if present)
          PMA_HOST = split(":", aws_rds_cluster.aurora_cluster.endpoint)[0]
        }
      }
    }
  }

  instance_configuration {
    cpu    = "1024" # 1 vCPU
    memory = "2048" # 2GB RAM
  }

  health_check_configuration {
    protocol            = "TCP" # Basic TCP connectivity check
    path                = "/"   # Path placeholder (unused for TCP)
    interval            = 10    # Perform check every 10 seconds
    timeout             = 5     # 5-second wait before timeout
    healthy_threshold   = 1     # Mark healthy after 1 pass
    unhealthy_threshold = 5     # Mark unhealthy after 5 failures
  }
}
