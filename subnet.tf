resource "aws_subnet" "public_subnet_01" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = var.public_subnet_01
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_01"
  }
}

resource "aws_subnet" "public_subnet_02" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = var.public_subnet_02
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet_01"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
