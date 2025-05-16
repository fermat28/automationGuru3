# Configure AWS provider 
provider "aws" {
  region = var.region
}

#Ami image research
data "aws_ami" "ubuntu-ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu*focal*20.04*-amd64-server-*2023*"]
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
resource "aws_route_table_association" "public_subnet" {
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

# Create the security group for frontend
resource "aws_security_group" "front_sg" {
  name = var.front_security_group_name
  description = "Security group for frontend"
  vpc_id = aws_vpc.streaming_vpc.id
  tags = {
    Name = var.front_security_group_name
  }
}

# Frontend - Seulement HTTPS entrant ouvert au public
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_nginx_ssl" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Frontend - Seulement HTTPS sortant ouvert au public
resource "aws_vpc_security_group_egress_rule" "frontend_allow_nginx_ssl" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Frontend -  HTTP entrant pour installation packages
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_apt_ssl" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Frontend - HTTP sortant pour installation packages
resource "aws_vpc_security_group_egress_rule" "frontend_allow_apt_out_ssl" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


# Frontend -  HTTP entrant pour installation packages sur backend
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_apt_for_backend" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = var.subnets_cidr_block[1]
  from_port         = 3128
  ip_protocol       = "tcp"
  to_port           = 3128
}

# Frontend -  HTTP entrant pour installation packages sur backend
resource "aws_vpc_security_group_egress_rule" "frontend_allow_apt_for_backend" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = var.subnets_cidr_block[0]
  from_port         = 3128
  ip_protocol       = "tcp"
  to_port           = 3128
}


# Frontend - SSH entrant Ouvert pour administration
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_ssh_ipv4" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Frontend - SSH Sortant pour administration
resource "aws_vpc_security_group_egress_rule" "frontend_allow_ssh_ipv4" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Frontend - Traffic entrant RTMP
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_rtmp_from_backend" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = var.subnets_cidr_block[1]
  from_port         = 1935
  to_port           = 1935
  ip_protocol       = "tcp"
  description       = "Allow RTMP ingress from backend subnet"
}


/* # Frontend - Traffic sortant RTMP
resource "aws_vpc_security_group_egress_rule" "frontend_allow_backend_rtmp" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = var.vpc_cidr_block[1]   # Accès vers l'IP privée du backend
  from_port         = 1935
  ip_protocol       = "tcp"
  to_port           = 1935
  description       = "Allow RTMP (video streaming) traffic to backend"
}  */

/* resource "aws_vpc_security_group_egress_rule" "frontend_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
} */



# Create the security group for backend
resource "aws_security_group" "backend_sg" {
  name = var.back_security_group_name
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
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Allow SSH To Frontend Only
resource "aws_vpc_security_group_egress_rule" "backend_allow_ssh_ipv4" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = var.subnets_cidr_block[0]
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

 # Autoriser le backend à accéder au frontend via le port 1935
resource "aws_vpc_security_group_egress_rule" "backend_to_frontend_rtmp" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = var.subnets_cidr_block[0]  # Accès depuis l'IP privée de l'instance frontend
  from_port         = 1935
  ip_protocol       = "tcp"
  to_port           = 1935
  description       = "Allow RTMP (video streaming) traffic from frontend"
}




/* resource "aws_vpc_security_group_egress_rule" "backend_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Frontend - Seulement HTTPS entrant ouvert au public
resource "aws_vpc_security_group_ingress_rule" "frontend_allow_nginx_ssl" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Frontend - Seulement HTTPS sortant ouvert au public
resource "aws_vpc_security_group_egress_rule" "frontend_allow_nginx_ssl" {
  security_group_id = aws_security_group.front_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
} */

# Backend -  HTTP entrant pour installation packages
/* resource "aws_vpc_security_group_ingress_rule" "backend_allow_apt_ssl" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
} */

# Backend - HTTP sortant pour installation packages
resource "aws_vpc_security_group_egress_rule" "backend_allow_apt_out_ssl" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "backend_allow_apt_out_https" {
  security_group_id = aws_security_group.backend_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}



#key_pair creation
resource "tls_private_key" "podx_key" {
  algorithm = var.algorithm
  rsa_bits  = var.rsa_bits
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.podx_key.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0600"
}



# Copy the key in the ~/.ssh/ folder
resource "null_resource" "copy_ssh_key" {
  provisioner "local-exec" {
    command = "cp ${path.module}/${path.module}/${var.key_name}.pem ~/.ssh/${path.module}/${var.key_name}.pem && chmod 600 ~/.ssh/${path.module}/${var.key_name}.pem"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
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

  /* route {
    cidr_block = var.vpc_cidr_block  # ex: "172.16.0.0/16"
    gateway_id = "local"
  } */
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

# Create the frontend EC2 instance
resource "aws_instance" "front_ec2_instance" {
  ami                         = data.aws_ami.ubuntu-ami.id
  instance_type               = var.instance_type
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
  ami                         = data.aws_ami.ubuntu-ami.id
  instance_type               = var.instance_type
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
  zone_id = data.aws_route53_zone.fermat_route.id # Replace with your actual hosted zone ID
  name    = "fermat-stream.${data.aws_route53_zone.fermat_route.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.front_ec2_instance.public_ip] # instance IP
}

