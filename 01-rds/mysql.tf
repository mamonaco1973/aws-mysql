##########################################
# Standalone MySQL RDS Instance          #
##########################################

resource "aws_db_instance" "mysql_rds" {
  identifier = "mysql-rds-instance"

  # Use standard MySQL engine
  engine = "mysql"

  # MySQL 8 version
  engine_version = "8.0.34"

  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type = "gp3"

  db_name = "mydb"

  username = "admin"
  password = random_password.mysql_password.result

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az = true
  publicly_accessible = true
  skip_final_snapshot = true

  backup_retention_period = 5
  backup_window = "07:00-09:00"

  performance_insights_enabled = false

  tags = {
    Name = "MySQL RDS Instance"
  }
}

#####################################################################
# RDS MySQL Read Replica                                            #
#####################################################################
resource "aws_db_instance" "mysql_rds_replica" {
  identifier = "mysql-rds-replica"

  replicate_source_db = aws_db_instance.mysql_rds.arn

  engine = aws_db_instance.mysql_rds.engine
  engine_version = aws_db_instance.mysql_rds.engine_version

  instance_class = "db.t4g.micro"

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true
  performance_insights_enabled = false
  skip_final_snapshot = true

  tags = {
    Name = "MySQL RDS Read Replica"
  }
}

##################################################
# RDS Subnet Group — Same as before
##################################################
resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "rds-subnet-group"

  subnet_ids = [
    aws_subnet.rds-subnet-1.id,
    aws_subnet.rds-subnet-2.id
  ]

  tags = {
    Name = "RDS Subnet Group"
  }
}
