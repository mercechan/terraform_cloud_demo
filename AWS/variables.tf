variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

# AWS AZ
variable "aws_az" {
  type        = string
  description = "AWS AZ"
  default     = "eu-west-1a"
}

# VPC Variables
variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.1.64.0/18"
}

# Subnet Variables
variable "public_subnet_cidr" {
  type        = string
  description = "CIDR for the public subnet"
  default     = "10.1.64.0/24"
}