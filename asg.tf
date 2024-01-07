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