variable "subnet_cidr" {
  description = "cidr block for the subnet"
  type = string
}

variable "subnet_tag" {
  description = "tag block for the subnet"
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-west-1"
}