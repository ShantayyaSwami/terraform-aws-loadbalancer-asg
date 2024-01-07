variable "region" {
  default = "ap-south-1"
}

variable "vpc-cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_01" {
  default = "10.0.1.0/24"
}

variable "public_subnet_02" {
  default = "10.0.2.0/24"
}

variable "inbound_ip" {
  type    = list(number)
  default = [22, 5000, 80]
}

variable "ami" {
  default = "ami-0a0f1259dd1c90938"
}

variable "instance_type" {
  default = "t2.micro"
}