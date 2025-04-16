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

data "aws_iam_role" "codedeploy_role" {
  count = 1
  name  = "quizspark-codedeploy-role"
}

# Create IAM roles if they don't exist
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

resource "aws_iam_role" "codedeploy_role" {
  count = length(data.aws_iam_role.codedeploy_role) == 0 ? 1 : 0
  name  = "quizspark-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "ec2_codedeploy" {
  count      = length(data.aws_iam_role.ec2_role) == 0 ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  count      = length(data.aws_iam_role.codedeploy_role) == 0 ? 1 : 0
  role       = aws_iam_role.codedeploy_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
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

# Check if CodeDeploy application exists
data "aws_codedeploy_app" "quizspark" {
  count = 1
  name  = "quizspark-backend"
}

# Create CodeDeploy application if it doesn't exist
resource "aws_codedeploy_app" "quizspark" {
  count = length(data.aws_codedeploy_app.quizspark) == 0 ? 1 : 0
  name  = "quizspark-backend"
}

# Create deployment group
resource "aws_codedeploy_deployment_group" "quizspark" {
  app_name              = length(data.aws_codedeploy_app.quizspark) > 0 ? data.aws_codedeploy_app.quizspark[0].name : aws_codedeploy_app.quizspark[0].name
  deployment_group_name = "quizspark-production"
  service_role_arn      = length(data.aws_iam_role.codedeploy_role) > 0 ? data.aws_iam_role.codedeploy_role[0].arn : aws_iam_role.codedeploy_role[0].arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "quizspark-backend"
    }
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
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

  # Install CodeDeploy agent
  apt-get install -y ruby
  cd /home/ubuntu
  wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
  chmod +x ./install
  ./install auto
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

output "instance_id" {
  value = aws_instance.quizspark_backend.id
}

output "codedeploy_app_name" {
  value = length(data.aws_codedeploy_app.quizspark) > 0 ? data.aws_codedeploy_app.quizspark[0].name : aws_codedeploy_app.quizspark[0].name
}

output "codedeploy_group_name" {
  value = aws_codedeploy_deployment_group.quizspark.deployment_group_name
}
