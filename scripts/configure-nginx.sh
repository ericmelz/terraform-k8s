#!/bin/bash
set -e

RANCHER_HOSTNAME="${RANCHER_HOSTNAME:-rancher.emelz.org}"
DEV_HOSTNAME="${DEV_HOSTNAME:-dev.emelz.org}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-eric@emelz.org}"

echo "=== Configuring Nginx with SSL and Proxying ==="
echo "Rancher hostname: $RANCHER_HOSTNAME"
echo "Dev hostname: $DEV_HOSTNAME"
echo "Let's Encrypt email: $LETSENCRYPT_EMAIL"

# Get Let's Encrypt certificates
echo "Obtaining SSL certificates..."
sudo certbot --nginx --non-interactive --agree-tos \
  --email "$LETSENCRYPT_EMAIL" \
  -d "$RANCHER_HOSTNAME" \
  -d "$DEV_HOSTNAME"

# Wait for Rancher service to get ClusterIP
echo "Getting Rancher service ClusterIP..."
RANCHER_IP=$(sudo k3s kubectl -n cattle-system get svc rancher -o jsonpath='{.spec.clusterIP}')
echo "Rancher ClusterIP: $RANCHER_IP"

# Create Nginx configuration
echo "Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/k8s-proxy > /dev/null <<EOF
upstream rancher_backend {
    server $RANCHER_IP:80;
}

upstream traefik {
    server 127.0.0.1:30080;
}

server {
    listen 80;
    server_name $RANCHER_HOSTNAME $DEV_HOSTNAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $RANCHER_HOSTNAME;

    ssl_certificate /etc/letsencrypt/live/$RANCHER_HOSTNAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$RANCHER_HOSTNAME/privkey.pem;

    location / {
        proxy_pass http://rancher_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}

server {
    listen 443 ssl http2;
    server_name $DEV_HOSTNAME;

    ssl_certificate /etc/letsencrypt/live/$RANCHER_HOSTNAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$RANCHER_HOSTNAME/privkey.pem;

    location / {
        proxy_pass http://traefik;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}
EOF

# Enable the site
echo "Enabling site configuration..."
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/k8s-proxy /etc/nginx/sites-enabled/

# Test and reload Nginx
echo "Testing Nginx configuration..."
sudo nginx -t

echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "✓ Nginx configured successfully"
echo ""
echo "Access points:"
echo "  Rancher UI: https://$RANCHER_HOSTNAME"
echo "  Dev apps:   https://$DEV_HOSTNAME"

echo "=== Nginx configuration complete ==="