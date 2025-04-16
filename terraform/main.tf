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

# Check if IAM roles exist
data "aws_iam_role" "ec2_role" {
  count = 1
  name  = "quizspark-ec2-role"
}

# Create IAM role if it doesn't exist
resource "aws_iam_role" "ec2_role" {
  count = length(data.aws_iam_role.ec2_role) == 0 ? 1 : 0
  name  = "quizspark-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_policy" {
  count      = length(data.aws_iam_role.ec2_role) == 0 ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Check if instance profile exists
data "aws_iam_instance_profile" "ec2_profile" {
  count = 1
  name  = "quizspark-ec2-profile"
}

# Create instance profile if it doesn't exist
resource "aws_iam_instance_profile" "ec2_profile" {
  count = length(data.aws_iam_instance_profile.ec2_profile) == 0 ? 1 : 0
  name  = "quizspark-ec2-profile"
  role  = length(data.aws_iam_role.ec2_role) > 0 ? data.aws_iam_role.ec2_role[0].name : aws_iam_role.ec2_role[0].name
}

resource "aws_instance" "quizspark_backend" {
  ami                    = "ami-0f5ee92e2d63afc18" # Ubuntu 20.04 LTS in ap-south-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  key_name               = "quizspark"
  associate_public_ip_address = true
  iam_instance_profile   = length(data.aws_iam_instance_profile.ec2_profile) > 0 ? data.aws_iam_instance_profile.ec2_profile[0].name : aws_iam_instance_profile.ec2_profile[0].name
  
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
}

output "instance_public_ip" {
  value = aws_instance.quizspark_backend.public_ip
}

output "instance_public_dns" {
  value = aws_instance.quizspark_backend.public_dns
}

output "instance_id" {
  value = aws_instance.quizspark_backend.id
}
