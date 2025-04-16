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

data "aws_instance" "existing_instance" {
  filter {
    name   = "tag:Name"
    values = ["quizspark-backend"]
  }
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
  count = data.aws_instance.existing_instance.id == null ? 1 : 0

  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu 20.04 LTS in ap-south-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  key_name               = "quizspark"
  user_data              = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              EOF

  tags = {
    Name = "quizspark-backend"
  }
}

output "instance_public_ip" {
  value = data.aws_instance.existing_instance.id != null ? data.aws_instance.existing_instance.public_ip : aws_instance.quizspark_backend[0].public_ip
}

output "instance_public_dns" {
  value = data.aws_instance.existing_instance.id != null ? data.aws_instance.existing_instance.public_dns : aws_instance.quizspark_backend[0].public_dns
} 