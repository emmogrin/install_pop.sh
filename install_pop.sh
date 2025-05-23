#!/bin/bash

echo ""
echo "███████╗ █████╗ ██╗███╗   ██╗████████╗    ██╗  ██╗██╗  ██╗███████╗███╗   ██╗"
echo "██╔════╝██╔══██╗██║████╗  ██║╚══██╔══╝    ██║ ██╔╝╚██╗██╔╝██╔════╝████╗  ██║"
echo "███████╗███████║██║██╔██╗ ██║   ██║       █████╔╝  ╚███╔╝ █████╗  ██╔██╗ ██║"
echo "╚════██║██╔══██║██║██║╚██╗██║   ██║       ██╔═██╗  ██╔██╗ ██╔══╝  ██║╚██╗██║"
echo "███████║██║  ██║██║██║ ╚████║   ██║       ██║  ██╗██╔╝ ██╗███████╗██║ ╚████║"
echo "╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝       ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝"
echo "                          SAINT KHEN || @admirkhen"
echo ""

# Update & install
apt update && apt install -y libssl-dev ca-certificates jq wget tar

# Sysctl tuning
sudo bash -c 'cat > /etc/sysctl.d/99-popcache.conf << EOL
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
sudo sysctl -p /etc/sysctl.d/99-popcache.conf

# Ulimit config
sudo bash -c 'cat > /etc/security/limits.d/popcache.conf << EOL
*    hard nofile 65535
*    soft nofile 65535
EOL'

# Setup dir
sudo mkdir -p /opt/popcache/logs
cd /opt/popcache

# Architecture check
ARCH=$(uname -m)
echo ">>> ARCH DETECTED: $ARCH"

if [[ "$ARCH" == "x86_64" ]]; then
    echo ">>> Downloading x86_64 POP binary"
    wget https://download.pipe.network/static/pop-v0.3.0-linux-x64.tar.gz -O pop.tar.gz
elif [[ "$ARCH" == "aarch64" ]]; then
    echo ">>> Downloading ARM64 POP binary"
    wget https://download.pipe.network/static/pop-v0.3.0-linux-arm64.tar.gz -O pop.tar.gz
else
    echo ">>> ARCHITECTURE NOT SUPPORTED BY SAINT KHEN"
    exit 1
fi

sudo rm -f /opt/popcache/pop*
tar -xzf pop.tar.gz
sudo mv pop /opt/popcache/pop
sudo chmod 755 /opt/popcache/pop

# Branding
echo ""
echo "███████████████████████████████████████████████████████"
echo "██      SAINT KHEN POP NODE INSTALLER LIVE!!!       ██"
echo "██             powered by: @admirkhen                ██"
echo "███████████████████████████████████████████████████████"
echo ""

# Inputs
read -p "POP Name: " popname
read -p "POP Location (City, Country): " poplocation
read -p "Invite Code: " invitecode
read -p "Node Name: " nodename
read -p "Your Name: " realname
read -p "Your Email: " email
read -p "Your Website: " website
read -p "Discord Username: " discord
read -p "Telegram: " telegram
read -p "Solana Wallet Address: " solana

# Config
cat <<EOF | sudo tee /opt/popcache/config.json
{
  "pop_name": "$popname",
  "pop_location": "$poplocation",
  "invite_code": "$invitecode",
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
    "node_name": "$nodename",
    "name": "$realname",
    "email": "$email",
    "website": "$website",
    "discord": "$discord",
    "telegram": "$telegram",
    "solana_pubkey": "$solana"
  }
}
EOF

# Systemd (fails gracefully if not supported)
sudo bash -c 'cat > /etc/systemd/system/popcache.service << EOL
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

sudo systemctl enable popcache || echo ">>> Systemd enable skipped"
sudo systemctl daemon-reexec || echo ">>> Systemd reload skipped"
sudo systemctl restart popcache || echo ">>> Systemd start skipped"

# Health Check
echo ""
echo ">>> Checking Node Health"
curl -s http://localhost/health || echo ">>> HTTP Failed"
curl -ks https://localhost/health | jq || echo ">>> HTTPS Failed"
curl -ks https://localhost/state | jq || echo ">>> State Failed"
curl -ks https://localhost/metrics | jq || echo ">>> Metrics Failed"

echo ""
echo "██████████████████████████████████████████████████"
echo "██     INSTALLATION COMPLETE — SAINT KHEN RULES ██"
echo "██           FOLLOW THE MOVEMENT: @admirkhen    ██"
echo "██████████████████████████████████████████████████"
