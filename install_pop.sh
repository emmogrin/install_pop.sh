#!/bin/bash
echo -e "\e[1mSAINT KHEN\e[0m"

# Install dependencies
apt update && apt install libssl-dev ca-certificates jq wget -y

# Set system configurations (PC only; skip if running on proot-distro without root)
if [ "$(id -u)" -eq 0 ]; then
  bash -c 'cat > /etc/sysctl.d/99-popcache.conf << EOL
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
EOL'
  sysctl -p /etc/sysctl.d/99-popcache.conf

  bash -c 'cat > /etc/security/limits.d/popcache.conf << EOL
*    hard nofile 65535
*    soft nofile 65535
EOL'
fi

# Create directories
mkdir -p /opt/popcache/logs
cd /opt/popcache || exit

# Download and extract binary
wget https://download.pipe.network/static/pop-v0.3.0-linux-x64.tar.gz
tar -xzf pop-v0.3.0-linux-*.tar.gz
chmod 755 /opt/popcache/pop

# Prompt user for config values
read -p "POP Name: " pop_name
read -p "POP Location (City, Country): " pop_location
read -p "Invite Code: " invite_code
read -p "Node Name: " node_name
read -p "Your Name: " name
read -p "Your Email: " email
read -p "Your Website: " website
read -p "Discord Username: " discord
read -p "Telegram: " telegram
read -p "Solana Wallet Address: " solana

# Write config.json
cat > /opt/popcache/config.json << EOL
{
  "pop_name": "$pop_name",
  "pop_location": "$pop_location",
  "invite_code": "$invite_code",
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
    "node_name": "$node_name",
    "name": "$name",
    "email": "$email",
    "website": "$website",
    "discord": "$discord",
    "telegram": "$telegram",
    "solana_pubkey": "$solana"
  }
}
EOL

# Setup systemd service (skip if not root)
if [ "$(id -u)" -eq 0 ]; then
  bash -c 'cat > /etc/systemd/system/popcache.service << EOL
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
EOL'

  systemctl enable popcache
  systemctl daemon-reload
  systemctl start popcache
  systemctl status popcache
else
  echo ">> Not root. Skipping systemd setup. Start manually using: ./pop"
fi

# Test endpoints
echo ">> Health check:"
curl http://localhost/health
curl -k https://localhost/health | jq
echo ">> State check:"
curl -k https://localhost/state | jq
echo ">> Metrics check:"
curl -k https://localhost/metrics | jq

echo -e "\e[1mSAINT KHEN\e[0m"
