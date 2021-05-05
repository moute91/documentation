  provider "aws" {
    region      = "us-east-1"
    access_key  = "AKIAXP3NNGCCATNUABHK"
    secret_key  = "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"

  }

  resource "aws_instance" "my-tacs-server" {
    ami            = "ami-09e67e426f25ce0d7"
    instance_type  = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "temou"
    network_interface {
       device_index = 0
       network_interface_id = aws_network_interface.test.id
    } 

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo this is my very first server building by Tacs using terraform > /var/www/html/index.html'
                EOF
    tags = {
      Name = "temou-webserver"
    }
  }
  
  resource "aws_vpc" "tacs" {
     cidr_block = "10.0.0.0/16"
     tags = {
       Name = "product.vpc"
     }
  }
  
  resource "aws_subnet" "tacs-subnet" {
    vpc_id     = aws_vpc.tacs.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = { 
      Name = "produc.subnet"
    }   
  } 
  resource "aws_internet_gateway" "tacs-gw" {
    vpc_id = aws_vpc.tacs.id

    tags = {
      Name = "igwtacs"
    }
  }
  resource "aws_route_table" "tacs-routable" {
    vpc_id = aws_vpc.tacs.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.tacs-gw.id

    }
    route {
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.tacs-gw.id
    }
    tags = {
      Name = "tacs-routable"
    }
  } 
  
  resource "aws_route_table_association" "ass" {
    subnet_id      = aws_subnet.tacs-subnet.id
    route_table_id = aws_route_table.tacs-routable.id
  }

  resource "aws_security_group" "allow_web" {
    name        = "allow_web-traffic"
    description = "Allow web inbound traffic"
    vpc_id      = aws_vpc.tacs.id


    ingress {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]

    } 

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
     
    }

    tags = {
      Name = "allow_web"
    }
  }

  resource "aws_network_interface" "test" {
    subnet_id       = aws_subnet.tacs-subnet.id

    private_ips     = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_web.id]

    
  }
  resource "aws_eip" "one" {
    vpc                       = true
    network_interface         = aws_network_interface.test.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.tacs-gw]
  }
    
