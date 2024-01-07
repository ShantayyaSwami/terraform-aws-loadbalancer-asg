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
