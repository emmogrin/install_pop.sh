#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)
echo ""
echo "${bold}████████████████████████████████████████████████████████████████"
echo "██                     SAINT KHEN DOMINATION                    ██"
echo "████████████████████████████████████████████████████████████████"
echo ""

set -e

# Check for sudo, fallback to plain if not found
if command -v sudo &>/dev/null; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "${bold}Updating system and installing dependencies...${normal}"
$SUDO apt update && $SUDO apt install -y libssl-dev ca-certificates jq wget

echo "${bold}Setting sysctl parameters...${normal}"
$SUDO bash -c 'cat > /etc/sysctl.d/99-popcache.conf <<EOF
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
EOF'
$SUDO sysctl -p /etc/sysctl.d/99-popcache.conf

echo "${bold}Setting file descriptor limits...${normal}"
sudo bash -c 'cat <<EOF > /etc/security/limits.d/popcache.conf
* soft nofile 65535
* hard nofile 65535
EOF'

echo "${bold}Creating directories...${normal}"
$SUDO mkdir -p /opt/popcache/logs

cd /opt/popcache || exit

ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" ]]; then
  BIN_URL="https://download.pipe.network/static/pop-v0.3.0-linux-arm64.tar.gz"
else
  BIN_URL="https://download.pipe.network/static/pop-v0.3.0-linux-x64.tar.gz"
fi

echo "${bold}Downloading POP binary for architecture: $ARCH${normal}"
wget -q --show-progress "$BIN_URL" -O pop.tar.gz

echo "${bold}Extracting binary...${normal}"
tar -xzf pop.tar.gz
$SUDO mv -f pop /opt/popcache/pop
$SUDO chmod 755 /opt/popcache/pop
rm -f pop.tar.gz

echo "${bold}Please enter the following details:${normal}"

read -rp "POP Name (e.g. wang): " POP_NAME
read -rp "POP Location (City, Country) (e.g. Nigeria): " POP_LOCATION
read -rp "Invite Code: " INVITE_CODE
read -rp "Node Name: " NODE_NAME
read -rp "Your Name: " YOUR_NAME
read -rp "Your Email: " YOUR_EMAIL
read -rp "Your Website (URL): " YOUR_WEBSITE
read -rp "Discord Username: " DISCORD_USERNAME
read -rp "Telegram Handle (with @): " TELEGRAM_HANDLE
read -rp "Solana Wallet Address: " SOLANA_WALLET

echo "${bold}Writing config.json...${normal}"

cat <<EOF > config.json
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
    "website": "$YOUR_WEBSITE",
    "discord": "$DISCORD_USERNAME",
    "telegram": "$TELEGRAM_HANDLE",
    "solana_pubkey": "$SOLANA_WALLET"
  }
}
EOF

echo "${bold}Setting up systemd service...${normal}"

if command -v systemctl &>/dev/null; then
  $SUDO bash -c 'cat > /etc/systemd/system/popcache.service <<EOF
[Unit]
Description=POP Cache Node
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/popcache
ExecStart=/opt/popcache/pop --config /opt/popcache/config.json
Restart=always
RestartSec=5
LimitNOFILE=65535
StandardOutput=append:/opt/popcache/logs/stdout.log
StandardError=append:/opt/popcache/logs/stderr.log
Environment=POP_CONFIG_PATH=/opt/popcache/config.json

[Install]
WantedBy=multi-user.target
EOF'

  $SUDO systemctl enable popcache
  $SUDO systemctl daemon-reload
  $SUDO systemctl restart popcache
else
  echo "${bold}Systemd not detected — service setup skipped.${normal}"
fi

echo "${bold}Checking node health endpoints...${normal}"

curl -s http://localhost/health || echo ">>> HTTP health check failed"
curl -sk https://localhost/health | jq . || echo ">>> HTTPS health check failed"
curl -sk https://localhost/state | jq . || echo ">>> State endpoint check failed"
curl -sk https://localhost/metrics | jq . || echo ">>> Metrics endpoint check failed"

echo ""
echo "${bold}████████████████████████████████████████████████████████████████"
echo "██                     SAINT KHEN DOMINATION                    ██"
echo "████████████████████████████████████████████████████████████████"
echo ""
