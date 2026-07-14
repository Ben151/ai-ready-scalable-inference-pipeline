# Create the main VPC for the AI infrastructure
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "AI-Infra-VPC" }
}

# Internet Gateway to provide internet access to the public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Public Subnet in AZ1 - hosting Bastion host and Load Balancers
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true # Necessary for Bastion accessibility
}

# Private Subnet in AZ1 - hosting backend servers/ASG
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

# Elastic IP for the NAT Gateway to ensure a stable outbound IP address
resource "aws_eip" "nat" { domain = "vpc" }

# NAT Gateway to allow private instances to access the internet for updates
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id # Must be in a public subnet
}

# Route Table for public traffic directing traffic to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Route Table for private traffic directing outbound traffic to the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Associate Public Subnet 1 with the Public Route Table
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# Associate Private Subnet 1 with the Private Route Table
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}