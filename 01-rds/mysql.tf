# ==============================================================================
# STANDALONE MYSQL RDS INSTANCE
# ==============================================================================
# Provisions a standalone Amazon RDS MySQL instance intended for small
# test or development workloads.
#
# Notes:
# - Uses a burstable instance class for cost efficiency.
# - Multi-AZ is enabled for automatic failover.
# - This is NOT Aurora; storage and scaling characteristics differ.
# ==============================================================================

# ------------------------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------------------------
variable "mysql_track" {
  type        = string
  description = "MySQL track to pin (ex: 8.4 or 8.0)."
  default     = "8.4"
}

# Ask AWS for the newest engine version on that track, and get its param group family.
data "aws_rds_engine_version" "mysql" {
  engine             = "mysql"
  preferred_versions = [var.mysql_track]
}

resource "aws_db_instance" "mysql_rds" {
  # ----------------------------------------------------------------------------
  # CORE IDENTIFIERS
  # ----------------------------------------------------------------------------
  # Logical identifier for the RDS instance.
  identifier = "mysql-rds-instance"

  # ----------------------------------------------------------------------------
  # ENGINE / INSTANCE SHAPE
  # ----------------------------------------------------------------------------
  # MySQL engine family.
  engine         = "mysql"
  engine_version = data.aws_rds_engine_version.mysql.version

  # Small, burstable instance class suitable for dev/test.
  instance_class = "db.t4g.micro"

  # ----------------------------------------------------------------------------
  # STORAGE
  # ----------------------------------------------------------------------------
  # Allocated storage in GB (20 GB is the MySQL minimum).
  allocated_storage = 20

  # General Purpose SSD (gp3).
  storage_type = "gp3"

  # ----------------------------------------------------------------------------
  # DATABASE BOOTSTRAP
  # ----------------------------------------------------------------------------
  # Initial database created at instance launch.
  db_name = "mydb"

  # ----------------------------------------------------------------------------
  # MASTER CREDENTIALS
  # ----------------------------------------------------------------------------
  # Master username for database access.
  username = "admin"

  # Master password sourced from a random_password resource.
  password = random_password.mysql_password.result

  # ----------------------------------------------------------------------------
  # NETWORKING / ACCESS CONTROL
  # ----------------------------------------------------------------------------
  # Subnet group defining which VPC subnets RDS can use.
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  # Security groups controlling inbound and outbound access.
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Expose the instance endpoint publicly.
  publicly_accessible = true

  # ----------------------------------------------------------------------------
  # HIGH AVAILABILITY
  # ----------------------------------------------------------------------------
  # Enable Multi-AZ for automatic failover.
  multi_az = true

  # ----------------------------------------------------------------------------
  # BACKUPS / LIFECYCLE
  # ----------------------------------------------------------------------------
  # Skip final snapshot on destroy (not recommended for prod).
  skip_final_snapshot = true

  # Retain automated backups for N days.
  backup_retention_period = 5

  # Daily backup window (UTC).
  backup_window = "07:00-09:00"

  # ----------------------------------------------------------------------------
  # OBSERVABILITY
  # ----------------------------------------------------------------------------
  # Disable Performance Insights.
  performance_insights_enabled = false

  # ----------------------------------------------------------------------------
  # PARAMETER GROUP
  # ----------------------------------------------------------------------------
  # Custom MySQL parameter group.
  parameter_group_name = aws_db_parameter_group.mysql_custom_params.name

  # ----------------------------------------------------------------------------
  # TAGGING
  # ----------------------------------------------------------------------------
  # Resource tags.
  tags = {
    Name = "MySQL RDS Instance"
  }
}

# ==============================================================================
# MYSQL RDS READ REPLICA
# ==============================================================================
# Provisions a read-only replica of the primary MySQL RDS instance.
#
# Notes:
# - Replicas are used for read scaling and reporting workloads.
# - Engine and version are inherited from the source instance.
# ==============================================================================
resource "aws_db_instance" "mysql_rds_replica" {
  # ----------------------------------------------------------------------------
  # CORE IDENTIFIERS
  # ----------------------------------------------------------------------------
  # Logical identifier for the read replica.
  identifier = "mysql-rds-replica"

  # ----------------------------------------------------------------------------
  # REPLICATION SOURCE
  # ----------------------------------------------------------------------------
  # Source database ARN for replication.
  replicate_source_db = aws_db_instance.mysql_rds.arn

  # ----------------------------------------------------------------------------
  # ENGINE / INSTANCE SHAPE
  # ----------------------------------------------------------------------------
  # Match the primary engine and version.
  engine         = aws_db_instance.mysql_rds.engine
  engine_version = aws_db_instance.mysql_rds.engine_version

  # Instance class for the replica.
  instance_class = "db.t4g.micro"

  # ----------------------------------------------------------------------------
  # NETWORKING
  # ----------------------------------------------------------------------------
  # Subnet group for the replica.
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  # Security groups controlling access.
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Expose the replica endpoint publicly.
  publicly_accessible = true

  # ----------------------------------------------------------------------------
  # OBSERVABILITY / LIFECYCLE
  # ----------------------------------------------------------------------------
  # Disable Performance Insights.
  performance_insights_enabled = false

  # Skip final snapshot on destroy.
  skip_final_snapshot = true

  # ----------------------------------------------------------------------------
  # PARAMETER GROUP
  # ----------------------------------------------------------------------------
  # Custom MySQL parameter group.
  parameter_group_name = aws_db_parameter_group.mysql_custom_params.name

  # ----------------------------------------------------------------------------
  # TAGGING
  # ----------------------------------------------------------------------------
  # Resource tags.
  tags = {
    Name = "MySQL RDS Read Replica"
  }
}

# ==============================================================================
# RDS SUBNET GROUP
# ==============================================================================
# Defines which subnets RDS instances may use.
#
# Requirements:
# - Should include at least two subnets in different AZs.
# ==============================================================================
resource "aws_db_subnet_group" "rds_subnet_group" {
  # Name of the subnet group.
  name = "rds-subnet-group"

  # Subnets included in this group.
  subnet_ids = [
    aws_subnet.rds-subnet-1.id,
    aws_subnet.rds-subnet-2.id
  ]

  # Resource tags.
  tags = {
    Name = "RDS Subnet Group"
  }
}

# ==============================================================================
# MYSQL PARAMETER GROUP
# ==============================================================================
# Custom MySQL parameter group for database-level configuration.
# ==============================================================================
resource "aws_db_parameter_group" "mysql_custom_params" {
  # Name of the parameter group.
  name = "mysql-custom-params"

  # Parameter group family (must match MySQL major version).
  family = data.aws_rds_engine_version.mysql.parameter_group_family

  # Description of the parameter group.
  description = "Custom MySQL parameters"

  # ----------------------------------------------------------------------------
  # PARAMETERS
  # ----------------------------------------------------------------------------
  # Allow creation of stored functions without SUPER privilege.
  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
}
