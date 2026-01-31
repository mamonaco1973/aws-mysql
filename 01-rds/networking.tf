# ==============================================================================
# VPC CONFIGURATION FOR RDS INFRASTRUCTURE
# ==============================================================================
# Builds a minimal VPC footprint to support RDS networking.
#
# High-level flow:
# - Create a VPC with DNS support enabled.
# - Attach an Internet Gateway (IGW) for outbound internet routing.
# - Create a public route table with a default route to the IGW.
# - Create two public subnets in separate AZs.
# - Associate both subnets to the public route table.
#
# Notes:
# - This configuration creates PUBLIC subnets (map_public_ip_on_launch = true).
# - Public subnets are not recommended for production RDS in most cases.
# ==============================================================================

# ==============================================================================
# VPC
# ==============================================================================
resource "aws_vpc" "rds-vpc" {
  # ----------------------------------------------------------------------------
  # ADDRESSING
  # ----------------------------------------------------------------------------
  # VPC CIDR block (/24 provides 256 total IPv4 addresses).
  cidr_block = "10.0.0.0/24"

  # ----------------------------------------------------------------------------
  # DNS
  # ----------------------------------------------------------------------------
  # Enable DNS resolution and DNS hostnames within the VPC.
  enable_dns_support   = true
  enable_dns_hostnames = true

  # ----------------------------------------------------------------------------
  # TAGGING
  # ----------------------------------------------------------------------------
  tags = {
    Name          = "rds-vpc"
    ResourceGroup = "rds-asg-rg"
  }
}

# ==============================================================================
# INTERNET GATEWAY
# ==============================================================================
# Provides a target for internet-routable traffic from public subnets.
# ==============================================================================
resource "aws_internet_gateway" "rds-igw" {
  # Attach the IGW to the VPC.
  vpc_id = aws_vpc.rds-vpc.id

  # Resource tags.
  tags = {
    Name = "rds-igw"
  }
}

# ==============================================================================
# PUBLIC ROUTE TABLE
# ==============================================================================
# Defines internet routing for subnets that should be considered "public".
# ==============================================================================
resource "aws_route_table" "public" {
  # Associate this route table with the VPC.
  vpc_id = aws_vpc.rds-vpc.id

  # Resource tags.
  tags = {
    Name = "public-route-table"
  }
}

# ------------------------------------------------------------------------------
# DEFAULT INTERNET ROUTE
# ------------------------------------------------------------------------------
# Routes all IPv4 egress traffic (0.0.0.0/0) to the Internet Gateway.
# ------------------------------------------------------------------------------
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rds-igw.id
}

# ==============================================================================
# PUBLIC SUBNETS
# ==============================================================================
# Two public subnets are created in separate AZs for HA-compatible layouts.
# ==============================================================================
resource "aws_subnet" "rds-subnet-1" {
  # ----------------------------------------------------------------------------
  # NETWORKING
  # ----------------------------------------------------------------------------
  # Place subnet in the VPC and assign its CIDR range.
  vpc_id     = aws_vpc.rds-vpc.id
  cidr_block = "10.0.0.0/26"

  # ----------------------------------------------------------------------------
  # PUBLIC SUBNET BEHAVIOR
  # ----------------------------------------------------------------------------
  # Automatically assign public IPs on instance launch.
  map_public_ip_on_launch = true

  # ----------------------------------------------------------------------------
  # AVAILABILITY ZONE
  # ----------------------------------------------------------------------------
  availability_zone = "us-east-2a"

  # ----------------------------------------------------------------------------
  # TAGGING
  # ----------------------------------------------------------------------------
  tags = {
    Name = "rds-subnet-1"
  }
}

resource "aws_subnet" "rds-subnet-2" {
  # ----------------------------------------------------------------------------
  # NETWORKING
  # ----------------------------------------------------------------------------
  vpc_id     = aws_vpc.rds-vpc.id
  cidr_block = "10.0.0.64/26"

  # ----------------------------------------------------------------------------
  # PUBLIC SUBNET BEHAVIOR
  # ----------------------------------------------------------------------------
  map_public_ip_on_launch = true

  # ----------------------------------------------------------------------------
  # AVAILABILITY ZONE
  # ----------------------------------------------------------------------------
  availability_zone = "us-east-2b"

  # ----------------------------------------------------------------------------
  # TAGGING
  # ----------------------------------------------------------------------------
  tags = {
    Name = "rds-subnet-2"
  }
}

# ==============================================================================
# ROUTE TABLE ASSOCIATIONS
# ==============================================================================
# Associates each public subnet with the public route table.
# ==============================================================================
resource "aws_route_table_association" "public_rta_1" {
  # Bind subnet 1 to the public route table.
  subnet_id      = aws_subnet.rds-subnet-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_rta_2" {
  # Bind subnet 2 to the public route table.
  subnet_id      = aws_subnet.rds-subnet-2.id
  route_table_id = aws_route_table.public.id
}
