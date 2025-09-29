#!/bin/bash
set -e

echo "=== Installing Nginx and Certbot ==="

# Update package list
sudo apt-get update

# Install Nginx and Certbot
echo "Installing packages..."
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "✓ Nginx installed successfully"
nginx -v

echo "=== Nginx installation complete ==="
echo ""
echo "Next steps:"
echo "1. Run configure-nginx.sh to set up SSL and proxy configuration"