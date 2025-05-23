#!/bin/bash

# Function to run commands with sudo fallback
run_cmd() {
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

echo ">>> Installing POP Node for SAINT KHEN (@admirkhen)"
sleep 1

# Create working directory
mkdir -p /opt/popcache
cd /opt/popcache || exit

# Clean old files
run_cmd rm -f /opt/popcache/pop*

# Download ARM64 binary
wget https://download.pipe.network/static/pop-v0.3.0-linux-arm64.tar.gz -O pop-arm64.tar.gz

# Extract and setup
tar -xzf pop-arm64.tar.gz
run_cmd mv pop /opt/popcache/pop
run_cmd chmod 755 /opt/popcache/pop

# Create logs directory
mkdir -p /opt/popcache/logs

# Create config.json
cat <<EOF > /opt/popcache/config.json
{
  "pop_name": "wang",
  "pop_location": "nigeria",
  "invite_code": "mJNkKR8hPjb2",
  "node_name": "pipenode",
  "your_name": "wang",
  "your_email": "jijinwang7@gmail.com",
  "your_website": "googo",
  "discord_username": "jijinwang",
  "telegram": "@Khenkeys",
  "solana_wallet_address": "ATGXrAZiNLWVeaUqFgxUE15FUAcXvgWrRSmNy6G5Ztrm"
}
EOF

# Optional: systemd service (skipped if systemd not active)
if pidof systemd >/dev/null; then
  cat <<EOF | run_cmd tee /etc/systemd/system/popcache.service
[Unit]
Description=Pipe POP Node
After=network.target

[Service]
ExecStart=/opt/popcache/pop --config /opt/popcache/config.json
WorkingDirectory=/opt/popcache
StandardOutput=append:/opt/popcache/logs/output.log
StandardError=append:/opt/popcache/logs/error.log
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  run_cmd systemctl enable popcache
  run_cmd systemctl daemon-reload
  run_cmd systemctl start popcache
else
  echo ">>> Systemd not detected — service steps skipped"
fi

# Health checks
echo ">>> Checking Node Health"
curl -I http://localhost || echo ">>> HTTP Failed"
curl -I https://localhost || echo ">>> HTTPS Failed"

echo ""
echo "██████████████████████████████████████████████████"
echo "██     INSTALLATION COMPLETE — SAINT KHEN RULES ██"
echo "██           FOLLOW THE MOVEMENT: @admirkhen    ██"
echo "██████████████████████████████████████████████████"
