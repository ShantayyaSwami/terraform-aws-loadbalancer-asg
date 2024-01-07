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

