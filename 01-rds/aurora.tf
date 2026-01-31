# ==============================================================================
# AURORA MYSQL RDS CLUSTER
# ==============================================================================
# Provisions an Aurora MySQL cluster configured for Aurora Serverless v2.
#
# Notes:
# - Aurora Serverless v2 requires `engine_mode = "provisioned"`.
# - Capacity scaling is controlled via ACU min/max values.
# - Instances (writer/reader) attach to this cluster via cluster_identifier.
# ==============================================================================
resource "aws_rds_cluster" "aurora_cluster" {
  # ----------------------------------------------------------------------------
  # CORE IDENTIFIERS
  # ----------------------------------------------------------------------------
  # Logical identifier for the Aurora cluster.
  cluster_identifier = "aurora-mysql-cluster"

  # ----------------------------------------------------------------------------
  # ENGINE / MODE
  # ----------------------------------------------------------------------------
  # Aurora MySQL engine family.
  engine = "aurora-mysql"

  # Serverless v2 requires "provisioned" engine mode.
  engine_mode = "provisioned"

  # ----------------------------------------------------------------------------
  # DATABASE BOOTSTRAP
  # ----------------------------------------------------------------------------
  # Initial database to create in the cluster.
  database_name = "mydb"

  # ----------------------------------------------------------------------------
  # MASTER CREDENTIALS
  # ----------------------------------------------------------------------------
  # Master user for the cluster.
  master_username = "admin"

  # Master password sourced from a generated random_password resource.
  master_password = random_password.aurora_password.result

  # ----------------------------------------------------------------------------
  # NETWORKING / ACCESS CONTROL
  # ----------------------------------------------------------------------------
  # DB subnet group controls which VPC subnets Aurora can use.
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Security groups controlling inbound/outbound access to the cluster.
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # ----------------------------------------------------------------------------
  # BACKUPS / LIFECYCLE
  # ----------------------------------------------------------------------------
  # Skip final snapshot on destroy (convenient, but not recommended for prod).
  skip_final_snapshot = true

  # Retain automated backups for N days.
  backup_retention_period = 5

  # Daily backup window (UTC) for automated backups.
  preferred_backup_window = "07:00-09:00"

  # ----------------------------------------------------------------------------
  # SERVERLESS V2 SCALING (ACU RANGE)
  # ----------------------------------------------------------------------------
  # Aurora capacity units (ACUs) define the allowed compute range.
  serverlessv2_scaling_configuration {
    # Minimum capacity in ACUs.
    min_capacity = 0.5

    # Maximum capacity in ACUs.
    max_capacity = 4.0
  }
}

# ==============================================================================
# PRIMARY INSTANCE (WRITER)
# ==============================================================================
# Creates the writer node for the Aurora cluster.
#
# Notes:
# - `instance_class = "db.serverless"` is used for Aurora Serverless v2.
# - `engine` and `engine_version` are inherited from the cluster for consistency.
# ==============================================================================
resource "aws_rds_cluster_instance" "aurora_instance_primary" {
  # ----------------------------------------------------------------------------
  # CORE IDENTIFIERS
  # ----------------------------------------------------------------------------
  # Instance identifier within the account/region.
  identifier = "aurora-mysql-instance-1"

  # Attach this instance to the cluster.
  cluster_identifier = aws_rds_cluster.aurora_cluster.id

  # ----------------------------------------------------------------------------
  # INSTANCE SHAPE / ENGINE
  # ----------------------------------------------------------------------------
  # Aurora Serverless v2 instance class.
  instance_class = "db.serverless"

  # Match the cluster engine configuration.
  engine         = aws_rds_cluster.aurora_cluster.engine
  engine_version = aws_rds_cluster.aurora_cluster.engine_version

  # ----------------------------------------------------------------------------
  # NETWORKING
  # ----------------------------------------------------------------------------
  # Subnet group for this instance.
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Public access exposes the instance endpoint to the internet.
  publicly_accessible = true

  # ----------------------------------------------------------------------------
  # OBSERVABILITY
  # ----------------------------------------------------------------------------
  # Enable Performance Insights for deeper database monitoring.
  performance_insights_enabled = true
}

# ==============================================================================
# REPLICA INSTANCE (READER)
# ==============================================================================
# Creates a read-only replica for availability and horizontal read scaling.
#
# Notes:
# - Additional replicas can be added using the same pattern.
# - Replicas share the same storage layer and replicate automatically.
# ==============================================================================
resource "aws_rds_cluster_instance" "aurora_instance_replica" {
  # ----------------------------------------------------------------------------
  # CORE IDENTIFIERS
  # ----------------------------------------------------------------------------
  # Instance identifier for the reader node.
  identifier = "aurora-mysql-instance-2"

  # Attach this instance to the same cluster.
  cluster_identifier = aws_rds_cluster.aurora_cluster.id

  # ----------------------------------------------------------------------------
  # INSTANCE SHAPE / ENGINE
  # ----------------------------------------------------------------------------
  # Aurora Serverless v2 instance class.
  instance_class = "db.serverless"

  # Match the cluster engine configuration.
  engine         = aws_rds_cluster.aurora_cluster.engine
  engine_version = aws_rds_cluster.aurora_cluster.engine_version

  # ----------------------------------------------------------------------------
  # NETWORKING
  # ----------------------------------------------------------------------------
  # Subnet group for this instance.
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Public access exposes the instance endpoint to the internet.
  publicly_accessible = true

  # ----------------------------------------------------------------------------
  # OBSERVABILITY
  # ----------------------------------------------------------------------------
  # Enable Performance Insights for deeper database monitoring.
  performance_insights_enabled = true
}

# ==============================================================================
# AURORA DB SUBNET GROUP
# ==============================================================================
# Defines which subnets Aurora cluster instances can use.
#
# Requirements:
# - Should span at least two AZs for high availability.
# ==============================================================================
resource "aws_db_subnet_group" "aurora_subnet_group" {
  # Name of the subnet group.
  name = "aurora-subnet-group"

  # Subnets included in this group (should be in different AZs).
  subnet_ids = [
    aws_subnet.rds-subnet-1.id,
    aws_subnet.rds-subnet-2.id
  ]

  # Resource tags.
  tags = {
    Name = "Aurora Subnet Group"
  }
}
