# Generate SSH key pair locally
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "k8s_rancher" {
  key_name   = "k8s-rancher-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name = "k8s-rancher-key"
  }
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/../ssh-keys/k8s-rancher-key.pem"
  file_permission = "0600"
}