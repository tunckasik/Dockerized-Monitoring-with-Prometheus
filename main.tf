terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.59.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region                 = var.region
}

resource "aws_instance" "ec2" {
  ami                    = var.ami_type
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = var.ec2_tag
  }

  provisioner "file" {
    source      = var.source_file_path
    destination = "/"
  }

  connection {
    type        = "ssh"
    user        = var.user_type
    private_key = file("${var.ssh_private_key_path}${var.ssh_key_name}.pem")
    host        = self.public_ip
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

locals {
  ingress_ports = [22, 8080]
}

resource "aws_security_group" "sg" {
  name = "${var.prefix}-sg"

  dynamic "ingress" {
    for_each = local.ingress_ports
    iterator = port
    content {
      from_port   = port.value
      protocol    = "tcp"
      to_port     = port.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.10.0/24"

  tags = {
    Name = "${var.prefix}-subnet"
  }
}
