# ==============================================================================
# APP RUNNER: PHPMYADMIN FRONTEND SERVICES
# ==============================================================================
# Provisions AWS App Runner services to run phpMyAdmin against:
# - A standalone MySQL RDS instance
# - An Aurora MySQL cluster
#
# Notes:
# - This deploys the official phpMyAdmin container from ECR Public.
# - App Runner is internet-facing by default; control access accordingly.
# - `PMA_HOST` is set to the database endpoint hostname (port stripped).
# - These services do not configure database credentials; phpMyAdmin will
#   prompt for username/password at login.
# ==============================================================================

# ==============================================================================
# APP RUNNER SERVICE: PHPMYADMIN -> MYSQL RDS
# ==============================================================================
resource "aws_apprunner_service" "phpmyadmin_rds" {
  # ----------------------------------------------------------------------------
  # SERVICE IDENTITY
  # ----------------------------------------------------------------------------
  # Friendly name for the App Runner service.
  service_name = "phpmyadmin-rds"

  # ----------------------------------------------------------------------------
  # SOURCE CONFIGURATION (CONTAINER IMAGE)
  # ----------------------------------------------------------------------------
  source_configuration {
    # Disable automatic deployments when the image tag changes.
    auto_deployments_enabled = false

    image_repository {
      # Official phpMyAdmin image hosted in ECR Public.
      image_identifier      = "public.ecr.aws/docker/library/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        # Container listens on HTTP port 80.
        port = "80"

        # Runtime environment variables passed into the container.
        runtime_environment_variables = {
          # phpMyAdmin target DB hostname (strip ":port" from endpoint).
          PMA_HOST = split(":", aws_db_instance.mysql_rds.endpoint)[0]
        }
      }
    }
  }

  # ----------------------------------------------------------------------------
  # INSTANCE RESOURCES
  # ----------------------------------------------------------------------------
  # CPU and memory allocated per running instance.
  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  # ----------------------------------------------------------------------------
  # HEALTH CHECKS
  # ----------------------------------------------------------------------------
  # TCP checks validate that the container port is reachable.
  health_check_configuration {
    protocol            = "TCP"
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
}

# ==============================================================================
# APP RUNNER SERVICE: PHPMYADMIN -> AURORA CLUSTER
# ==============================================================================
resource "aws_apprunner_service" "phpmyadmin_aurora" {
  # ----------------------------------------------------------------------------
  # SERVICE IDENTITY
  # ----------------------------------------------------------------------------
  # Friendly name for the App Runner service.
  service_name = "phpmyadmin-aurora"

  # ----------------------------------------------------------------------------
  # SOURCE CONFIGURATION (CONTAINER IMAGE)
  # ----------------------------------------------------------------------------
  source_configuration {
    # Disable automatic deployments when the image tag changes.
    auto_deployments_enabled = false

    image_repository {
      # Official phpMyAdmin image hosted in ECR Public.
      image_identifier      = "public.ecr.aws/docker/library/phpmyadmin:latest"
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        # Container listens on HTTP port 80.
        port = "80"

        # Runtime environment variables passed into the container.
        runtime_environment_variables = {
          # phpMyAdmin target DB hostname (strip ":port" if present).
          PMA_HOST = split(":", aws_rds_cluster.aurora_cluster.endpoint)[0]
        }
      }
    }
  }

  # ----------------------------------------------------------------------------
  # INSTANCE RESOURCES
  # ----------------------------------------------------------------------------
  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  # ----------------------------------------------------------------------------
  # HEALTH CHECKS
  # ----------------------------------------------------------------------------
  health_check_configuration {
    protocol            = "TCP"
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
}
