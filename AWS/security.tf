#Create a virtual network
resource "aws_vpc" "node-red-vpc-vpc" {
  cidr_block = "10.0.0.0/16"
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
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true
  depends_on              = [aws_vpc.node-red-vpc-vpc]
}


#Define routing table
resource "aws_route_table" "node-red-vpc-rtb-public1-us-west-1a" {
  vpc_id = aws_vpc.node-red-vpc-vpc.id

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

#Add default route in routing table to point to Internet Gateway
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.node-red-vpc-rtb-public1-us-west-1a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.node-red-vpc-igw.id
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



