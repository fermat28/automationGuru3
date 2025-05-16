# Outputs
output "vpc_id" {
  value = aws_vpc.streaming_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.streaming_vpc.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "gw_id" {
  value = aws_internet_gateway.gw.id
}

output "private_key_pem_path" {
  value = local_file.private_key_pem.filename
}

output "aws_key_pair_name" {
  value = aws_key_pair.podx_key_pair.key_name
}

output "frontend_public_ip" {
  value = aws_instance.front_ec2_instance.public_ip
}

output "backend_private_ip" {
  value = aws_instance.back_ec2_instance.private_ip

}
