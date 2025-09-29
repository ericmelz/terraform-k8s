# Data source for latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Elastic IP
resource "aws_eip" "k8s_instance" {
  domain   = "vpc"
  instance = aws_instance.k8s_rancher.id

  tags = {
    Name = "k8s-rancher-eip"
  }
}

# EC2 Instance
resource "aws_instance" "k8s_rancher" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.k8s_rancher.key_name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.k8s_instance.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true

    tags = {
      Name = "k8s-rancher-root"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Log all output
              exec > >(tee /var/log/user-data.log)
              exec 2>&1

              echo "Starting instance setup..."

              # Update system
              apt-get update
              apt-get upgrade -y

              # Install basic tools
              apt-get install -y curl wget git vim htop net-tools

              # Install Docker
              curl -fsSL https://get.docker.com -o get-docker.sh
              sh get-docker.sh
              usermod -aG docker ubuntu

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # Install helm
              curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

              echo "Base setup complete"
              echo "To complete setup, run: sudo /home/ubuntu/setup-all.sh"
              EOF

  tags = {
    Name = "k8s-rancher-instance"
  }
}