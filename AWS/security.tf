#Create a virtual network
resource "aws_vpc" "node-red-vpc-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "node-red-vpc-vpc"
  }
}


#Create your application segment
resource "aws_subnet" "node-red-vpc-subnet-public1-us-west-1a" {
  tags = {
    Name = "node-red-vpc-subnet-public1-us-west-1a"
  }
  vpc_id                  = aws_vpc.node-red-vpc-vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.aws_az
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true
  depends_on              = [aws_vpc.node-red-vpc-vpc]
}


#Define routing table
resource "aws_route_table" "node-red-vpc-rtb-public1-us-west-1a" {
  vpc_id = aws_vpc.node-red-vpc-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.node-red-vpc-igw.id
  }
  tags = {
    Name = "node-red-vpc-rtb-public1-us-west-1a"
  }
}


#Associate subnet with routing table
resource "aws_route_table_association" "App_Route_Association" {
  subnet_id      = aws_subnet.node-red-vpc-subnet-public1-us-west-1a.id
  route_table_id = aws_route_table.node-red-vpc-rtb-public1-us-west-1a.id
}


#Create internet gateway for servers to be connected to internet
resource "aws_internet_gateway" "node-red-vpc-igw" {
  tags = {
    Name = "node-red-vpc-igw"
  }
  vpc_id     = aws_vpc.node-red-vpc-vpc.id
  depends_on = [aws_vpc.node-red-vpc-vpc]
}







#Create a security group
resource "aws_security_group" "nodered-sg" {
  name        = "nodered-security-group"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.node-red-vpc-vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1880
    to_port     = 1880
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Elastic IP for the EC2 instance
resource "aws_eip" "vm-eip" {
  vpc  = true
  tags = {
    Name = "vm-eip"
  }
}

# Associate Elastic IP to the EC2 Instance
resource "aws_eip_association" "vm-eip-association" {
  instance_id   = aws_instance.Web[0].id
  allocation_id = aws_eip.vm-eip.id
}

