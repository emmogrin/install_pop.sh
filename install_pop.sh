#!/bin/bash
set -e

echo ""
echo "████████████████████████████████████████████████████████████████"
echo "██                     SAINT KHEN DOMINATION                    ██"
echo "████████████████████████████████████████████████████████████████"
echo ""

echo "Updating system and installing dependencies..."
apt update && apt install libssl-dev ca-certificates jq wget -y

echo "Setting sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/99-popcache.conf
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 65535
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
EOF

sysctl -p /etc/sysctl.d/99-popcache.conf

echo "Setting file limits..."
cat <<EOF | sudo tee /etc/security/limits.d/popcache.conf
* soft nofile 65535
* hard nofile 65535
EOF

echo "Creating directories..."
sudo mkdir -p /opt/popcache/logs
cd /opt/popcache

echo "Downloading PoP node..."
wget -q https://download.pipe.network/static/pop-v0.3.0-linux-x64.tar.gz
sudo tar -xzf pop-v0.3.0-linux-*.tar.gz
chmod 755 /opt/popcache/pop

# ===== Prompts =====
echo ""
echo "Enter PoP node configuration details:"
read -p "POP Name: " POP_NAME
read -p "POP Location (City, Country): " POP_LOCATION
read -p "Invite Code: " INVITE_CODE
read -p "Node Name: " NODE_NAME
read -p "Your Name: " YOUR_NAME
read -p "Your Email: " YOUR_EMAIL
read -p "Your Website (or N/A): " WEBSITE
read -p "Your Discord: " DISCORD
read -p "Your Telegram: " TELEGRAM
read -p "Your Solana Wallet Address: " SOLANA

echo "Creating config.json..."
cat <<EOF | sudo tee /opt/popcache/config.json
{
  "pop_name": "$POP_NAME",
  "pop_location": "$POP_LOCATION",
  "invite_code": "$INVITE_CODE",
  "server": {
    "host": "0.0.0.0",
    "port": 443,
    "http_port": 80,
    "workers": 40
  },
  "cache_config": {
    "memory_cache_size_mb": 4096,
    "disk_cache_path": "./cache",
    "disk_cache_size_gb": 100,
    "default_ttl_seconds": 86400,
    "respect_origin_headers": true,
    "max_cacheable_size_mb": 1024
  },
  "api_endpoints": {
    "base_url": "https://dataplane.pipenetwork.com"
  },
  "identity_config": {
    "node_name": "$NODE_NAME",
    "name": "$YOUR_NAME",
    "email": "$YOUR_EMAIL",
    "website": "$WEBSITE",
    "discord": "$DISCORD",
    "telegram": "$TELEGRAM",
    "solana_pubkey": "$SOLANA"
  }
}
EOF

echo "Setting up systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/popcache.service
[Unit]
Description=POP Cache Node
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/popcache
ExecStart=/opt/popcache/pop
Restart=always
RestartSec=5
LimitNOFILE=65535
StandardOutput=append:/opt/popcache/logs/stdout.log
StandardError=append:/opt/popcache/logs/stderr.log
Environment=POP_CONFIG_PATH=/opt/popcache/config.json

[Install]
WantedBy=multi-user.target
EOF

echo "Starting PoP node..."
sudo systemctl enable popcache
sudo systemctl daemon-reload
sudo systemctl start popcache
sudo systemctl status popcache

echo ""
echo "Check endpoints:"
echo "  curl http://localhost/health"
echo "  curl -k https://localhost/health | jq"
echo "  curl -k https://localhost/state | jq"
echo "  curl -k https://localhost/metrics | jq"
echo ""

echo "████████████████████████████████████████████████████████████████"
echo "██                     SAINT KHEN DOMINATION                    ██"
echo "████████████████████████████████████████████████████████████████"
