#Terraform main config file
provider "aws" {
  region                  = var.aws_region
  profile                 = var.aws_creds_profile
  shared_credentials_file = var.aws_creds_file
}

resource "aws_vpc" "vpc" {
  cidr_block = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.aws_tag_name
  }
}

resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.aws_tag_name
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gw.id
  }

  tags = {
    Name = var.aws_tag_name
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = aws_vpc.vpc.cidr_block

  map_public_ip_on_launch = true
  tags = {
    Name = var.aws_tag_name
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

#Create new aws security group for application instance. 
resource "aws_security_group" "app_sg" {
  name            = var.aws_tag_name
  description     = "For web and ssh access"
  vpc_id          = aws_vpc.vpc.id

  ingress {  #HTTP Port
          from_port       = 80
          to_port         = 80
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]

  }
  ingress {  #SSH Port
          from_port       = 22
          to_port         = 22
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {  #shell in a box port
          from_port       = 4200
          to_port         = 4200
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {  #orders app port
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {  
          from_port       = 8081
          to_port         = 8081
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
          from_port       = 8082
          to_port         = 8082
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
          from_port       = 8083
          to_port         = 8083
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]
  }
  ingress {
          from_port       = 8090
          to_port         = 8090
          protocol        = "tcp"
          cidr_blocks     = ["0.0.0.0/0"]
  }
  egress  {  #Outbound all allow
          from_port       = 0
          to_port         = 0
          protocol        = -1
          cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
          Name = var.aws_tag_name
  }
}

#Application instance. 
resource "aws_instance" "app_vm" {
  ami                    = var.server_ami 
  instance_type          = var.server_instance_type
  key_name               = var.aws_keypair_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.subnet.id

  tags = {
      Name = var.aws_tag_name
  }

  /*
  provisioner "remote-exec" {
      inline = ["echo running remove exec. I am:  $('hostname')"]

      connection {
          type        = "ssh"
          private_key = "file(var.aws_pem_file)"
          user        = "ubuntu"
          timeout     = "1m"
      }
  }
  */
}
