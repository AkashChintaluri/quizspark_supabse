terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_security_group" "existing_sg" {
  name = "quizspark-sg"
}

resource "random_id" "sg_suffix" {
  byte_length = 4
}

resource "aws_security_group" "quizspark_sg" {
  name        = "quizspark-sg-${random_id.sg_suffix.hex}"
  description = "Security group for QuizSpark backend"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "quizspark_backend" {
  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu 20.04 LTS in ap-south-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  key_name               = "quizspark"
  associate_public_ip_address = true
  
  user_data = <<-EOF
  #!/bin/bash
  set -e

  # Update package lists
  apt-get update

  # Install required packages
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common

  # Add Docker's official GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

  # Add Docker repository
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  # Update package lists again
  apt-get update

  # Install Docker
  apt-get install -y docker-ce docker-ce-cli containerd.io

  # Start and enable Docker service
  systemctl start docker
  systemctl enable docker

  # Add ubuntu user to docker group
  usermod -aG docker ubuntu

  # Create directory for application data
  mkdir -p /home/ubuntu/quizspark-data
  chown ubuntu:ubuntu /home/ubuntu/quizspark-data
  EOF

  tags = {
    Name = "quizspark-backend"
  }

  # Ensure proper instance termination protection
  disable_api_termination = false # Set to true for production
}

output "instance_public_ip" {
  value = aws_instance.quizspark_backend.public_ip
}

output "instance_public_dns" {
  value = aws_instance.quizspark_backend.public_dns
}
