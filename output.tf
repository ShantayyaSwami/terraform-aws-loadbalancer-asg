output "instance_ips" {
  value = data.aws_instances.ec2.public_ips
}