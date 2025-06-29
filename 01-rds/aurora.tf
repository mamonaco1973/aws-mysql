##############################################
# Aurora MySQL RDS Cluster Configuration
##############################################
resource "aws_rds_cluster" "aurora_cluster" {
  # Unique identifier for the Aurora cluster
  cluster_identifier = "aurora-mysql-cluster"

  # Specify Aurora MySQL engine
  engine = "aurora-mysql"

  # Aurora MySQL engine version supporting Serverless v2
  engine_version = "8.0.mysql_aurora.3.05.2"

  # Use provisioned engine mode (Serverless v2 requires this)
  engine_mode = "provisioned"

  # Name of the initial database created inside the cluster
  database_name = "mydb"

  # Master credentials (admin user)
  master_username = "admin"
  master_password = random_password.aurora_password.result

  # Subnet group defining which VPC subnets Aurora can use
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # VPC security groups to control inbound/outbound access
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Do not create a final snapshot when the cluster is destroyed
  skip_final_snapshot = true

  # Number of days automated backups are retained
  backup_retention_period = 5

  # Daily window during which backups occur
  preferred_backup_window = "07:00-09:00"

  # Serverless v2 scaling configuration: capacity range in ACUs
  serverlessv2_scaling_configuration {
    # Minimum Aurora capacity units (ACUs)
    min_capacity = 0.5

    # Maximum Aurora capacity units (ACUs)
    max_capacity = 4.0
  }
}

#############################################################
# PRIMARY INSTANCE — The Writer Node for the Aurora Cluster
#############################################################
resource "aws_rds_cluster_instance" "aurora_instance_primary" {
  # Unique identifier for this cluster instance
  identifier = "aurora-mysql-instance-1"

  # Reference to the Aurora cluster it belongs to
  cluster_identifier = aws_rds_cluster.aurora_cluster.id

  # Serverless instance class for Aurora Serverless v2
  instance_class = "db.serverless"

  # Must match the cluster's engine and version
  engine         = aws_rds_cluster.aurora_cluster.engine
  engine_version = aws_rds_cluster.aurora_cluster.engine_version

  # Subnet group for networking
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Allow public access (exposes endpoint to the internet)
  publicly_accessible = true

  # Enable Performance Insights monitoring
  performance_insights_enabled = true
}

#############################################################
# REPLICA INSTANCE — Read-Only Node for High Availability
#############################################################
resource "aws_rds_cluster_instance" "aurora_instance_replica" {
  # Unique identifier for the replica instance
  identifier = "aurora-mysql-instance-2"

  # Reference to the same Aurora cluster
  cluster_identifier = aws_rds_cluster.aurora_cluster.id

  # Serverless instance class
  instance_class = "db.serverless"

  # Same engine and version as primary
  engine         = aws_rds_cluster.aurora_cluster.engine
  engine_version = aws_rds_cluster.aurora_cluster.engine_version

  # Subnet group for networking
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  # Make replica publicly accessible
  publicly_accessible = true

  # Enable Performance Insights
  performance_insights_enabled = true
}

#############################################################
# Aurora DB Subnet Group
# Defines which subnets Aurora cluster instances can use
# Must span at least 2 AZs for high availability
#############################################################
resource "aws_db_subnet_group" "aurora_subnet_group" {
  # Name of the subnet group
  name = "aurora-subnet-group"

  # List of subnet IDs included in this group
  subnet_ids = [
    aws_subnet.rds-subnet-1.id,
    aws_subnet.rds-subnet-2.id
  ]

  # Tag for identification and organization
  tags = {
    Name = "Aurora Subnet Group"
  }
}
