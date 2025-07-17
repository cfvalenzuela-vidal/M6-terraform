terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.3"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2        = "http://localhost:4566"
    iam        = "http://localhost:4566"
    sts        = "http://localhost:4566"
    s3         = "http://localhost:4566"
    elb        = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
  }
}

locals {
  envs = ["dev", "test", "prod"]

  vpc_cidrs = {
    dev  = "10.1.0.0/16"
    test = "10.2.0.0/16"
    prod = "10.3.0.0/16"
  }

  subnet_cidrs = {
    public_a  = "10.1.1.0/24"
    public_b  = "10.1.2.0/24"
    private_a = "10.1.3.0/24"
    private_b = "10.1.4.0/24"
    data_a    = "10.1.5.0/24"
    data_b    = "10.1.6.0/24"
  }
}

# Crear VPCs
resource "aws_vpc" "vpc" {
  for_each = toset(local.envs)

  cidr_block           = local.vpc_cidrs[each.key]
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${each.key}-vpc"
  }
}

# Subnets Públicas (A y B)
resource "aws_subnet" "public_a" {
  for_each = toset(local.envs)

  vpc_id                  = aws_vpc.vpc[each.key].id
  cidr_block              = cidrsubnet(local.vpc_cidrs[each.key], 8, 1) # ej: 10.1.1.0/24
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${each.key}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  for_each = toset(local.envs)

  vpc_id                  = aws_vpc.vpc[each.key].id
  cidr_block              = cidrsubnet(local.vpc_cidrs[each.key], 8, 2) # ej: 10.1.2.0/24
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${each.key}-public-b"
  }
}

# Subnets Privadas (A y B)
resource "aws_subnet" "private_a" {
  for_each = toset(local.envs)

  vpc_id            = aws_vpc.vpc[each.key].id
  cidr_block        = cidrsubnet(local.vpc_cidrs[each.key], 8, 3) # ej: 10.1.3.0/24
  availability_zone = "us-east-1a"

  tags = {
    Name = "${each.key}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  for_each = toset(local.envs)

  vpc_id            = aws_vpc.vpc[each.key].id
  cidr_block        = cidrsubnet(local.vpc_cidrs[each.key], 8, 4) # ej: 10.1.4.0/24
  availability_zone = "us-east-1b"

  tags = {
    Name = "${each.key}-private-b"
  }
}

# Subnets Data (A y B)
resource "aws_subnet" "data_a" {
  for_each = toset(local.envs)

  vpc_id            = aws_vpc.vpc[each.key].id
  cidr_block        = cidrsubnet(local.vpc_cidrs[each.key], 8, 5) # ej: 10.1.5.0/24
  availability_zone = "us-east-1a"

  tags = {
    Name = "${each.key}-data-a"
  }
}

resource "aws_subnet" "data_b" {
  for_each = toset(local.envs)

  vpc_id            = aws_vpc.vpc[each.key].id
  cidr_block        = cidrsubnet(local.vpc_cidrs[each.key], 8, 6) # ej: 10.1.6.0/24
  availability_zone = "us-east-1b"

  tags = {
    Name = "${each.key}-data-b"
  }
}

# Internet Gateway para cada VPC
resource "aws_internet_gateway" "igw" {
  for_each = toset(local.envs)

  vpc_id = aws_vpc.vpc[each.key].id

  tags = {
    Name = "${each.key}-igw"
  }
}

# Route Table Pública con ruta 0.0.0.0/0 a IGW
resource "aws_route_table" "public_rt" {
  for_each = toset(local.envs)

  vpc_id = aws_vpc.vpc[each.key].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[each.key].id
  }

  tags = {
    Name = "${each.key}-public-rt"
  }
}

# Asociar subnets públicas a route table pública
resource "aws_route_table_association" "public_a_assoc" {
  for_each = toset(local.envs)

  subnet_id      = aws_subnet.public_a[each.key].id
  route_table_id = aws_route_table.public_rt[each.key].id
}

resource "aws_route_table_association" "public_b_assoc" {
  for_each = toset(local.envs)

  subnet_id      = aws_subnet.public_b[each.key].id
  route_table_id = aws_route_table.public_rt[each.key].id
}

# Elastic IPs para NAT Gateways (una por entorno)
resource "aws_eip" "nat_eip" {
  for_each = toset(local.envs)


  tags = {
    Name = "${each.key}-nat-eip"
  }
}

# NAT Gateway en subnet pública A
resource "aws_nat_gateway" "nat_gw" {
  for_each = toset(local.envs)

  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = aws_subnet.public_a[each.key].id

  tags = {
    Name = "${each.key}-nat-gateway"
  }
}

# Route Table Privada para subnets privadas, con ruta default a NAT Gateway
resource "aws_route_table" "private_rt" {
  for_each = toset(local.envs)

  vpc_id = aws_vpc.vpc[each.key].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[each.key].id
  }

  tags = {
    Name = "${each.key}-private-rt"
  }
}

# Asociar subnets privadas a route table privada
resource "aws_route_table_association" "private_a_assoc" {
  for_each = toset(local.envs)

  subnet_id      = aws_subnet.private_a[each.key].id
  route_table_id = aws_route_table.private_rt[each.key].id
}

resource "aws_route_table_association" "private_b_assoc" {
  for_each = toset(local.envs)

  subnet_id      = aws_subnet.private_b[each.key].id
  route_table_id = aws_route_table.private_rt[each.key].id
}

# Ejemplo instancia EC2 en Dev para probar (solo dev)
resource "aws_instance" "dev_ec2" {
  ami                         = "ami-573d4c74"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_a["dev"].id
  associate_public_ip_address = true

  tags = {
    Name = "DevEC2"
  }
}

# Key pair (asegúrate de tener archivo clave-ec2.pub en el directorio)
resource "aws_key_pair" "ssh_key" {
  key_name   = "dev-key"
  public_key = file("clave-ec2.pub")
}

