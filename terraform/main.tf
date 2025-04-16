terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "quizspark_sg" {
  name        = "quizspark-sg"
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
  vpc_security_group_ids = [aws_security_group.quizspark_sg.id]
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
  value = aws_instance.quizspark_backend.public_ip
}

output "instance_public_dns" {
  value = aws_instance.quizspark_backend.public_dns
} 