output "vpc_id" {
  value = aws_vpc.mern_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.mern_public_subnet.id
}

output "security_group_id" {
  value = aws_security_group.mern_sg.id
}

output "ec2_instance_id" {
  value = aws_instance.mern_server.id
}

output "ec2_public_ip" {
  value = aws_instance.mern_server.public_ip
}

