provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
# 1. Creating VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "Terraform VPC"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "terraform_ig" {
  vpc_id = aws_vpc.terraform_vpc.id
}

# 3. Terraform Custom Route Table
resource "aws_route_table" "terraform_vpc_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.terraform_ig.id
  }

  tags = {
    Name = "Terraform VPC Route Table"
  }
}

# 4. Create a Subnet
resource "aws_subnet" "terrafrom_vpc_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Terraform VPC Subnet"
  }
}

# 5. Associate Subnet with a Route Table
resource "aws_route_table_association" "name" {
  subnet_id      = aws_subnet.terrafrom_vpc_subnet.id
  route_table_id = aws_route_table.terraform_vpc_route_table.id
}

# 6. Create security group to allow 80,22,443
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  tags = {
    Name = "allow_tls"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_443" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6_443" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.terraform_vpc.ipv6_cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_80" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6_80" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.terraform_vpc.ipv6_cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_22" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6_22" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.terraform_vpc.ipv6_cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
# resource "aws_network_interface" "name" {
#   subnet_id       = aws_subnet.terrafrom_vpc_subnet.id
#   security_groups = [aws_security_group.allow_tls.id]
#   private_ips     = ["10.0.1.10"]
# }

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  instance = aws_instance.name.id
  domain   = "vpc"
}
# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "name" {
  ami                    = "ami-0bbdd8c17ed981ef9"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  key_name               = "terraform-ec2-key-pair"
  subnet_id              = aws_subnet.terrafrom_vpc_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]

  tags = {
    Name = "Terraform EC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update package index
              sudo apt update -y

              # Install nginx
              sudo apt install -y nginx

              # Enable and start nginx
              sudo systemctl enable --now nginx

              # Replace default index page
              sudo bash -c 'echo "your very first web server" > /var/www/html/index.nginx-debian.html'

              EOF
}
