##############################################
# RDS Cluster Definition (Aurora MySQL)
##############################################
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "aurora-mysql-cluster"

  # Use the Aurora MySQL engine
  engine = "aurora-mysql"

  # Aurora MySQL engine version that supports Serverless v2
  engine_version = "8.0.mysql_aurora.3.05.2"

  # Serverless v2 requires engine_mode = "provisioned"
  engine_mode = "provisioned"

  # Default DB name created in the cluster
  database_name = "mydb"

  # Master credentials
  master_username = "admin"
  master_password = random_password.aurora_password.result

  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true

  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  # Serverless v2 scaling configuration
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4.0
  }
}

#####################################################
# PRIMARY INSTANCE — Writer for the Aurora Cluster
#####################################################
resource "aws_rds_cluster_instance" "aurora_instance_primary" {
  identifier = "aurora-mysql-instance-1"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id

  # Serverless v2 class
  instance_class = "db.serverless"

  # Reuse same engine & version
  engine         = aws_rds_cluster.aurora_cluster.engine
  engine_version = aws_rds_cluster.aurora_cluster.engine_version

  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  publicly_accessible = true
  performance_insights_enabled = true
}

#####################################################
# REPLICA INSTANCE — Reader for High Availability
#####################################################
resource "aws_rds_cluster_instance" "aurora_instance_replica" {
  identifier = "aurora-mysql-instance-2"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id

  instance_class = "db.serverless"
  engine         = aws_rds_cluster.aurora_cluster.engine
  engine_version = aws_rds_cluster.aurora_cluster.engine_version

  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name

  publicly_accessible = true
  performance_insights_enabled = true
}

#############################################################
# DB Subnet Group — Same as before
#############################################################
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name = "aurora-subnet-group"

  subnet_ids = [
    aws_subnet.rds-subnet-1.id,
    aws_subnet.rds-subnet-2.id
  ]

  tags = {
    Name = "Aurora Subnet Group"
  }
}
