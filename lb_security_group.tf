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
