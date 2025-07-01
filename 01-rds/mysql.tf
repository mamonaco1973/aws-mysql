##############################################
# Standalone MySQL RDS Instance Configuration
##############################################
resource "aws_db_instance" "mysql_rds" {
  # Unique identifier for the RDS instance
  identifier = "mysql-rds-instance"

  # Specify the RDS engine - MySQL
  engine = "mysql"

  # Specific MySQL 8 version
  engine_version = "8.0.34"

  # Instance size (smallest burstable for test/dev workloads)
  instance_class = "db.t4g.micro"

  # Storage size in GB (minimum 20GB for MySQL)
  allocated_storage = 20

  # Use gp3 - modern general-purpose SSD storage
  storage_type = "gp3"

  # Initial database created upon instance creation
  db_name = "mydb"

  # Master username for connecting to the DB
  username = "admin"

  # Password generated securely (reference to random_password resource)
  password = random_password.mysql_password.result

  # Subnet group defining which subnets in the VPC RDS will use
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  # Security groups applied to the RDS instance for inbound/outbound rules
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Enable Multi-AZ deployment for automatic failover
  multi_az = true

  # Expose this instance to the public internet
  publicly_accessible = true

  # Do not create a final snapshot when deleting this instance
  skip_final_snapshot = true

  # Number of days automated backups are retained
  backup_retention_period = 5

  # Daily backup window during which backups occur
  backup_window = "07:00-09:00"

  # Disable Performance Insights (database performance monitoring)
  performance_insights_enabled = false

  # Tags applied to the RDS instance (helps with identification)
  tags = {
    Name = "MySQL RDS Instance"
  }
  # Custom parameter group for MySQL settings
  parameter_group_name = aws_db_parameter_group.mysql_custom_params.name
}

##################################################################
# RDS MySQL Read Replica Configuration
##################################################################
resource "aws_db_instance" "mysql_rds_replica" {
  # Unique identifier for the read replica
  identifier = "mysql-rds-replica"

  # Specify the source database to replicate from (the primary instance ARN)
  replicate_source_db = aws_db_instance.mysql_rds.arn

  # Engine must match the primary (inherited from source)
  engine = aws_db_instance.mysql_rds.engine

  # Engine version must match the primary
  engine_version = aws_db_instance.mysql_rds.engine_version

  # Instance size for the replica (same size here as primary)
  instance_class = "db.t4g.micro"

  # Subnet group for networking configuration
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  # Security group(s) to control access to the replica
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Make replica publicly accessible
  publicly_accessible = true

  # Disable Performance Insights
  performance_insights_enabled = false

  # Do not create a final snapshot on deletion
  skip_final_snapshot = true

  # Tag for identification
  tags = {
    Name = "MySQL RDS Read Replica"
  }
  # Custom parameter group for MySQL settings
  parameter_group_name = aws_db_parameter_group.mysql_custom_params.name
}

##########################################################
# RDS Subnet Group
# Defines which subnets the RDS instances will use
# Typically you need at least 2 subnets in different AZs
##########################################################
resource "aws_db_subnet_group" "rds_subnet_group" {
  # Name of the subnet group
  name = "rds-subnet-group"

  # List of subnet IDs included in this group
  subnet_ids = [
    aws_subnet.rds-subnet-1.id,
    aws_subnet.rds-subnet-2.id
  ]

  # Tag for identification
  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_parameter_group" "mysql_custom_params" {
  name        = "mysql-custom-params"
  family      = "mysql8.0"  # Must match your MySQL major version
  description = "Custom parameter group with log_bin_trust_function_creators enabled"

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
}
