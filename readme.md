# Terafrom-AWS-LoadBalancer-ASG

## Prerequisite:
```
Basic understanding of AWS & Terraform
A server with Terraform pre-installed
An access key & secret key created the AWS
The SSH key
```

### Step 1:- Create Provider block
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.30.0"
    }
  }
}
provider "aws" {
  region = var.region
}
```

### Step 2:- Create AWS VPC
```
resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc-cidr
  tags = {
    Name = "asg-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id
}
```

### Step 4:- Create AWS Subnets
```
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

```

### Step 5:- Create AWS Route Table and Route Table association
```
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route to internet"
  }
}

resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.public_subnet_01.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.public_subnet_02.id
  route_table_id = aws_route_table.route.id
}

```

### Step 6:- Create AWS Security Group for Load Balancer
```
resource "aws_security_group" "lb_sg" {
  vpc_id      = aws_vpc.my-vpc.id
  name        = "lb_sg"
  description = "allow traffic from internet to asg"

  egress {
    description      = "allow traffic frm asg to internet"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  dynamic "ingress" {
    for_each = var.inbound_ip
    content {
      description      = "allow traffic from ports ${ingress.value} to asg"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

```

### Step 7:- Create AWS Load Balancer
```
resource "aws_lb" "asg-lb" {
  name                             = "asg-lb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.lb_sg.id]
  subnets                          = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]
  enable_cross_zone_load_balancing = true
  enable_http2                     = true

}

resource "aws_lb_target_group" "lb-target" {
    name = "lb-target"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.my-vpc.id
    health_check {
      path = "/"
      matcher = 200
       }
    }

resource "aws_lb_listener" "alb-target-listener" {
  load_balancer_arn = aws_lb.asg-lb.arn
  port  = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb-target.arn
  }
}

```

### Step 8:- Create AWS Launch configuration
```
resource "aws_launch_configuration" "ec2-launch-config" {
  name_prefix   = "web-"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = "terraform-key"
  lifecycle {
    create_before_destroy = true
  }
  security_groups             = [aws_security_group.asg_sg.id]
  associate_public_ip_address = true
  user_data                   = file("./data.sh")
}


```

### Step 9:- Create AWS Security group for EC2 instances in ASG
```
resource "aws_security_group" "asg_sg" {
  vpc_id      = aws_vpc.my-vpc.id
  name        = "ec2-eg"
  description = "allow traffic from lb to asg"

  egress {
    description      = "allow traffic from ec2 to internet"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  dynamic "ingress" {
    for_each = var.inbound_ip
    content {
      description = "allow traffic from port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      #   security_groups = [aws_security_group.lb_sg.id]
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]

    }
  }
}

```

### Step 10:- Create AWS Auto Scaling Group
```
resource "aws_autoscaling_group" "ec2-asg" {
  name             = "ec2-asg"
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier       = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]
  launch_configuration      = aws_launch_configuration.ec2-launch-config.name
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  target_group_arns = [aws_lb_target_group.lb-target.arn] 
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web-ec2"
    propagate_at_launch = true
  }
}

data "aws_instances" "ec2"{
    filter {
      name = "tag:Name"
      values = ["web-ec2"]
    }
}

```
### Step 11:- Create AWS Auto Scaling Policy
```
resource "aws_autoscaling_policy" "asg-policy" {
  autoscaling_group_name = aws_autoscaling_group.ec2-asg.name
  name                   = "asg-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
}

```

### Step 12:- Create terraform variable file
```
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

```

### Step 13:- Create a user data file
```
sudo yum update -y 
sudo yum install docker -y 
sudo systemctl enable docker --now 
sudo usermod -aG docker ec2-user 
newgrp docker 
sudo chmod 666 /var/run/docker.sock 
docker pull shantayya/connected-app:v1
docker run -d -p 80:5000 shantayya/connected-app:v1

```

We need to run the below steps to create the infrastructure.

1. terraform init is to initialize the working directory and downloading plugins of the AWS provider
2. terraform plan is to create the execution plan for our code
3. terraform apply is to create the actual infrastructure. It will ask you to provide the Access Key and Secret Key in order to create the infrastructure. So, instead of hardcoding the Access Key and Secret Key, it is better to apply at the run time.

After terraform apply completes you can verify the resources on the AWS console. Terraform will create the below resources.

```
VPC
Internet Gateway
Subnets
Load Balancer
Auto Scaling Group
Auto Scaling Policy
Launch Configurationn
Security Groups
Route Table

```