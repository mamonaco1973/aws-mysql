# ==============================================================================
# SECRETS: GENERATE AND STORE RDS CREDENTIALS
# ==============================================================================
# Generates random passwords and stores database connection information in
# AWS Secrets Manager for:
# - Aurora cluster credentials
# - Standalone MySQL RDS instance credentials
#
# Secret payload shape (JSON):
# {
#   "user":     "admin",
#   "password": "<generated>",
#   "endpoint": "<hostname>"
# }
#
# Notes:
# - Passwords are alphanumeric only for broad client compatibility.
# - Endpoints are stored as hostnames (port stripped) for convenience.
# - `recovery_window_in_days = 0` forces immediate deletion on destroy.
# ==============================================================================

# ==============================================================================
# AURORA: PASSWORD GENERATION
# ==============================================================================
resource "random_password" "aurora_password" {
  # ----------------------------------------------------------------------------
  # PASSWORD POLICY
  # ----------------------------------------------------------------------------
  # Generate a 24-character alphanumeric password.
  length  = 24
  special = false
}

# ==============================================================================
# AURORA: SECRETS MANAGER SECRET
# ==============================================================================
resource "aws_secretsmanager_secret" "aurora_credentials" {
  # ----------------------------------------------------------------------------
  # SECRET IDENTITY
  # ----------------------------------------------------------------------------
  # Logical name for the secret in AWS Secrets Manager.
  name = "aurora-credentials"

  # ----------------------------------------------------------------------------
  # DELETION BEHAVIOR
  # ----------------------------------------------------------------------------
  # Force immediate deletion instead of a recovery window.
  recovery_window_in_days = 0
}

# ------------------------------------------------------------------------------
# AURORA: SECRET VERSION (PAYLOAD)
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "aurora_credentials_version" {
  # Parent secret to which this version belongs.
  secret_id = aws_secretsmanager_secret.aurora_credentials.id

  # Store connection details and generated password as a JSON document.
  secret_string = jsonencode({
    user     = "admin"
    password = random_password.aurora_password.result
    endpoint = split(":", aws_rds_cluster.aurora_cluster.endpoint)[0]
  })
}

# ==============================================================================
# MYSQL RDS: PASSWORD GENERATION
# ==============================================================================
resource "random_password" "mysql_password" {
  # ----------------------------------------------------------------------------
  # PASSWORD POLICY
  # ----------------------------------------------------------------------------
  # Generate a 24-character alphanumeric password.
  length  = 24
  special = false
}

# ==============================================================================
# MYSQL RDS: SECRETS MANAGER SECRET
# ==============================================================================
resource "aws_secretsmanager_secret" "mysql_credentials" {
  # ----------------------------------------------------------------------------
  # SECRET IDENTITY
  # ----------------------------------------------------------------------------
  # Logical name for the secret in AWS Secrets Manager.
  name = "mysql-credentials"

  # ----------------------------------------------------------------------------
  # DELETION BEHAVIOR
  # ----------------------------------------------------------------------------
  # Force immediate deletion instead of a recovery window.
  recovery_window_in_days = 0
}

# ------------------------------------------------------------------------------
# MYSQL RDS: SECRET VERSION (PAYLOAD)
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "mysql_credentials_version" {
  # Parent secret to which this version belongs.
  secret_id = aws_secretsmanager_secret.mysql_credentials.id

  # Store connection details and generated password as a JSON document.
  secret_string = jsonencode({
    user     = "admin"
    password = random_password.mysql_password.result
    endpoint = split(":", aws_db_instance.mysql_rds.endpoint)[0]
  })
}
