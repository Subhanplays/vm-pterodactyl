#!/bin/bash
set -e

echo -e "\e[1;36m[🚀] Initializing Subhan Wings Node Installer...\e[0m"

# ------------------------------------
# 1. Install Docker (stable channel)
# ------------------------------------
echo -e "\e[1;33m[⚙] Installing Docker engine...\e[0m"
curl -fsSL https://get.docker.com | CHANNEL=stable bash
systemctl enable --now docker

# ------------------------------------
# 2. Update GRUB for swap support
# ------------------------------------
GRUB_CFG="/etc/default/grub"
if [[ -f "$GRUB_CFG" ]]; then
    echo -e "\e[1;33m[⚙] Enabling swapaccount in GRUB...\e[0m"
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' "$GRUB_CFG"
    update-grub
fi

# ------------------------------------
# 3. Download Wings binary
# ------------------------------------
echo -e "\e[1;33m[⬇] Fetching latest Wings release...\e[0m"
mkdir -p /etc/subhan_wings
CPU_ARCH=$(uname -m)
if [[ "$CPU_ARCH" == "x86_64" ]]; then
    CPU_ARCH="amd64"
else
    CPU_ARCH="arm64"
fi

curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${CPU_ARCH}"
chmod +x /usr/local/bin/wings

# ------------------------------------
# 4. Systemd service for Wings
# ------------------------------------
echo -e "\e[1;33m[⚙] Registering Wings service...\e[0m"
tee /etc/systemd/system/wings.service > /dev/null <<'EOF'
[Unit]
Description=Subhan Hosting Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/subhan_wings
LimitNOFILE=65535
ExecStart=/usr/local/bin/wings
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wings

# ------------------------------------
# 5. Generate SSL certificates
# ------------------------------------
echo -e "\e[1;33m[🔑] Creating SSL certificate...\e[0m"
mkdir -p /etc/certs/subhan_wings
cd /etc/certs/subhan_wings || exit
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=XX/ST=None/L=None/O=SubhanHosting/CN=WingsNode" \
-keyout node_privkey.pem -out node_fullchain.pem

# ------------------------------------
# 6. Add helper shortcut command
# ------------------------------------
echo -e "\e[1;33m[🛠] Adding 'wingsctl' helper command...\e[0m"
tee /usr/local/bin/wingsctl > /dev/null <<'EOF'
#!/bin/bash
echo -e "\e[1;36m[ Wings Control Utility ]\e[0m"
echo "  → Start Wings     : sudo systemctl start wings"
echo "  → Stop Wings      : sudo systemctl stop wings"
echo "  → Restart Wings   : sudo systemctl restart wings"
echo "  → View Logs       : journalctl -u wings -f"
echo "  → Config Location : /etc/subhan_wings/config.yml"
EOF
chmod +x /usr/local/bin/wingsctl

# ------------------------------------
# 7. Optional auto-config wizard
# ------------------------------------
echo -e "\n\e[1;32m✔ Base installation finished!\e[0m"
read -p "Run quick configuration wizard now? (y/n): " AUTOSETUP

if [[ "$AUTOSETUP" =~ ^[Yy]$ ]]; then
    echo -e "\e[1;34m[🔧] Running Wings config wizard...\e[0m"
    read -p " → Enter Node UUID         : " NODE_UUID
    read -p " → Enter Token Identifier  : " TOKEN_ID
    read -p " → Enter Token Secret      : " TOKEN_SECRET
    read -p " → Enter Panel API URL     : " PANEL_URL

    tee /etc/subhan_wings/config.yml > /dev/null <<CFG
debug: false
uuid: ${NODE_UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN_SECRET}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/subhan_wings/node_fullchain.pem
    key: /etc/certs/subhan_wings/node_privkey.pem
  upload_limit: 200
system:
  data: /var/lib/subhan_wings/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '${PANEL_URL}'
CFG

    echo -e "\e[1;32m✔ Config saved → /etc/subhan_wings/config.yml\e[0m"
    echo -e "\e[1;33m[⚡] Launching Wings...\e[0m"
    systemctl start wings
    echo -e "\e[1;32m🚀 Wings node is now running!\e[0m"
else
    echo -e "\e[1;33m[ℹ] Wizard skipped. Use 'wingsctl' to manage manually.\e[0m"
fi
