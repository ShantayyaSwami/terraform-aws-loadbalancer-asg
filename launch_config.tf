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

