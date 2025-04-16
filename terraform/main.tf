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
  ami                    = "ami-0d13e3e72defec9cf" # Verified Ubuntu 20.04 in ap-south-1
  instance_type          = "t2.micro"
  associate_public_ip_address = true
  subnet_id              = "subnet-XXXXXXXX" # Replace with your actual subnet ID
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  key_name               = "quizspark"
  
  # Improved user_data with error handling
  user_data = <<-EOF
  #!/bin/bash
  set -e # Exit immediately on error
  export DEBIAN_FRONTEND=noninteractive
  
  # Update system with retries
  for i in {1..5}; do
    apt-get update && break || sleep 30
  done
  
  # Install Docker using official method
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  
  # Configure backups
  mkdir -p /home/ubuntu/backups
  echo "0 0 * * * root (tar -zcf /home/ubuntu/backups/quizspark_backup_\$(date +\\%F).tar.gz /home/ubuntu/quizspark-data 2>> /var/log/backup_errors.log)" | tee /etc/cron.d/quizspark-backup
  
  systemctl restart cron
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
