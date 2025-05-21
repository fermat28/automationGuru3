# Configure AWS provider 
provider "aws" {
  region = var.region
}

#Get latest ubuntu ami
data "aws_ami" "ubuntu-ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

#Get Route Details
data "aws_route53_zone" "fermat_route" {
  name         = var.domain_name
  private_zone = false
}

#create streaming platform vpc
resource "aws_vpc" "streaming_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

# Create a public subnet 
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.streaming_vpc.id
  cidr_block              = var.subnets_cidr_block[0]
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_name
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.streaming_vpc.id
  tags = {
    Name = var.gw_name
  }
}

# Create Route Table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.streaming_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.route_table_name
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Create a private subnet 
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.streaming_vpc.id
  cidr_block = var.subnets_cidr_block[1]
  tags = {
    Name = var.private_subnet_name
  }
}

# Create the security group for frontend instances
resource "aws_security_group" "front_sg" {
  name        = var.front_security_group_name
  description = "Security group for frontend instances"
  vpc_id      = aws_vpc.streaming_vpc.id
  tags = {
    Name = var.front_security_group_name
  }
}

# Frontend -  Open HTTPS inbound to public
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_inbound_https" {
  description       = "Allow HTTPS from anywhere"
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.https_port
  ip_protocol       = "tcp"
  to_port           = var.https_port
}

# Frontend -  Open HTTPS outbound to public
resource "aws_vpc_security_group_egress_rule" "frontend_allow_outbound_https" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.https_port
  ip_protocol       = "tcp"
  to_port           = var.https_port
}

# Frontend -  Open HTTP inbound for certificate generation by certbot
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_certificate_install" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.http_port
  ip_protocol       = "tcp"
  to_port           = var.http_port
}

# Frontend - Open HTTP outbound for package installation 
resource "aws_vpc_security_group_egress_rule" "frontend_allow_apt_out_install" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.http_port
  ip_protocol       = "tcp"
  to_port           = var.http_port
}

# Frontend - open ssh inbound for administration
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_ssh_ipv4" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.ssh_port
  ip_protocol       = "tcp"
  to_port           = var.ssh_port
}

# Frontend - SSH Sortant pour administration
resource "aws_vpc_security_group_egress_rule" "frontend_allow_ssh_ipv4" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.ssh_port
  ip_protocol       = "tcp"
  to_port           = var.ssh_port
}

# Frontend - Traffic entrant RTMP
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_rtmp_from_backend" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = var.subnets_cidr_block[1]
  from_port         = var.rtmp_port
  to_port           = var.rtmp_port
  ip_protocol       = "tcp"
  description       = "Allow RTMP ingress from backend subnet"
}

# Create the security group for backend
resource "aws_security_group" "backend_sg" {
  name   = var.back_security_group_name
  vpc_id = aws_vpc.streaming_vpc.id
  tags = {
    Name = var.back_security_group_name
  }
}


# Allow SSH From Frontend Only
resource "aws_vpc_security_group_ingress_rule" "backend_allow_ssh_ipv4" {
  # description      = "Allow SSH from anywhere"
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = var.subnets_cidr_block[0]
  from_port         = var.ssh_port
  ip_protocol       = "tcp"
  to_port           = var.ssh_port
}

# Allow SSH To Frontend Only
resource "aws_vpc_security_group_egress_rule" "backend_allow_ssh_ipv4" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = var.subnets_cidr_block[0]
  from_port         = var.ssh_port
  ip_protocol       = "tcp"
  to_port           = var.ssh_port
}

# Autoriser le backend à accéder au frontend via le port 1935
resource "aws_vpc_security_group_egress_rule" "backend_to_frontend_rtmp" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = var.subnets_cidr_block[0]
  from_port         = var.rtmp_port
  ip_protocol       = "tcp"
  to_port           = var.rtmp_port
  description       = "Allow RTMP (video streaming) traffic from frontend"
}

# Backend - HTTP sortant pour installation packages
resource "aws_vpc_security_group_egress_rule" "backend_allow_apt_out_ssl" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.http_port
  ip_protocol       = "tcp"
  to_port           = var.http_port
}


resource "aws_vpc_security_group_egress_rule" "backend_allow_apt_out_https" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.https_port
  ip_protocol       = "tcp"
  to_port           = var.https_port
}



#key_pair creation
resource "tls_private_key" "podx_key" {
  algorithm = var.algorithm
  rsa_bits  = var.rsa_bits
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.podx_key.private_key_pem
  filename        = pathexpand("~/.ssh/${var.key_name}.pem")
  file_permission = "0600"
}

resource "aws_key_pair" "podx_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.podx_key.public_key_openssh
}

resource "aws_eip" "nat" {
  domain = "vpc"


}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.streaming_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

# Create the frontend EC2 instance
resource "aws_instance" "front_ec2_instance" {
  ami           = data.aws_ami.ubuntu-ami.id
  instance_type = var.instance_type
  #count                       = 1
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.front_sg.id]
  key_name                    = aws_key_pair.podx_key_pair.key_name
  associate_public_ip_address = true
  source_dest_check           = false
  iam_instance_profile        = "r53-devops"

  tags = {
    Name = "${var.frontend_instance_name}"
  }
}

# Create the backend EC2 instance
resource "aws_instance" "back_ec2_instance" {
  ami           = data.aws_ami.ubuntu-ami.id
  instance_type = var.instance_type
  #count                       = 1
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  key_name                    = aws_key_pair.podx_key_pair.key_name
  associate_public_ip_address = false
  source_dest_check           = false

  tags = {
    Name = "${var.backend_instance_name}"
  }
}

# Domain attribution
resource "aws_route53_record" "guru3route" {
  zone_id = data.aws_route53_zone.fermat_route.id
  name    = "${var.subdomain}.${data.aws_route53_zone.fermat_route.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.front_ec2_instance.public_ip]
}

