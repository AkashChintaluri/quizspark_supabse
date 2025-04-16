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

# Get existing security group
data "aws_security_group" "quizspark_sg" {
  name = "quizspark-sg"
}

# Get existing IAM role
data "aws_iam_role" "ec2_role" {
  name = "quizspark-ec2-role"
}

# Get existing instance profile
data "aws_iam_instance_profile" "ec2_profile" {
  name = "quizspark-ec2-profile"
}

# Create EC2 instance
resource "aws_instance" "quizspark_backend" {
  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu 20.04 LTS in ap-south-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_security_group.quizspark_sg.id]
  key_name               = "quizspark"
  associate_public_ip_address = true
  iam_instance_profile   = data.aws_iam_instance_profile.ec2_profile.name
  
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

  # Install AWS CLI
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  apt-get install -y unzip
  unzip awscliv2.zip
  ./aws/install
  EOF

  tags = {
    Name = "quizspark-backend"
  }
}

# Create S3 bucket for deployments
resource "aws_s3_bucket" "deployments" {
  bucket = "quizspark-deployments"
  acl    = "private"

  tags = {
    Name = "quizspark-deployments"
  }
}

# Output the instance details
output "instance_public_ip" {
  value = aws_instance.quizspark_backend.public_ip
}

output "instance_public_dns" {
  value = aws_instance.quizspark_backend.public_dns
}

output "instance_id" {
  value = aws_instance.quizspark_backend.id
} 