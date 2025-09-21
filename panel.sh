#!/bin/bash
# ======================================================
# Subhan Hosting - Pterodactyl Panel Auto Installer
# Author : Subhan Zahid
# Version: 1.0
# ======================================================

clear
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;33m   🚀 Subhan Hosting | Pterodactyl Installer \e[0m"
echo -e "\e[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
read -p "🔗 Enter your domain (e.g. panel.mydomain.com): " DOMAIN

# ─────────────────────────────
# Install Dependencies
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Updating system & installing dependencies...\e[0m"
apt update -y
apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release software-properties-common

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

if [[ "$OS" == "ubuntu" ]]; then
    echo -e "\e[1;32m✔ Ubuntu detected. Adding PHP repository...\e[0m"
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    echo -e "\e[1;32m✔ Debian detected. Adding SURY PHP repo...\e[0m"
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# Redis Repo
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis.gpg
echo "deb [signed-by=/usr/share/keyrings/redis.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt update -y

# ─────────────────────────────
# Install PHP, Nginx, MariaDB, Redis
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Installing PHP, Nginx, MariaDB, Redis...\e[0m"
apt install -y php8.3 php8.3-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server cron

# ─────────────────────────────
# Install Composer
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Installing Composer...\e[0m"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# ─────────────────────────────
# Download Panel
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Downloading latest Pterodactyl release...\e[0m"
mkdir -p /var/www/panel
cd /var/www/panel
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# ─────────────────────────────
# Database Setup
# ─────────────────────────────
DB_NAME="panel"
DB_USER="ptero"
DB_PASS="StrongPass$(date +%s)"

echo -e "\n\e[1;34m[INFO] Configuring MariaDB...\e[0m"
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE ${DB_NAME};"
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';"
mariadb -e "FLUSH PRIVILEGES;"

# ─────────────────────────────
# Environment Config
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Setting up environment file...\e[0m"
curl -Lo .env https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env

# ─────────────────────────────
# PHP Dependencies
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Installing PHP dependencies with Composer...\e[0m"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# ─────────────────────────────
# Laravel Setup
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Generating app key & migrating DB...\e[0m"
php artisan key:generate --force
php artisan migrate --seed --force

# ─────────────────────────────
# Permissions + Cron
# ─────────────────────────────
chown -R www-data:www-data /var/www/panel/*
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/panel/artisan schedule:run >> /dev/null 2>&1") | crontab -

# ─────────────────────────────
# SSL + Nginx
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Configuring Nginx & SSL...\e[0m"
mkdir -p /etc/certs/panel
cd /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=None/L=None/O=SubhanHosting/CN=${DOMAIN}" \
-keyout privkey.pem -out fullchain.pem

tee /etc/nginx/sites-available/panel.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/panel/public;
    index index.php;

    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;

    client_max_body_size 100m;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/panel.conf /etc/nginx/sites-enabled/panel.conf
nginx -t && systemctl restart nginx

# ─────────────────────────────
# Queue Worker
# ─────────────────────────────
echo -e "\n\e[1;34m[INFO] Setting up queue worker service...\e[0m"
tee /etc/systemd/system/panel-worker.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
ExecStart=/usr/bin/php /var/www/panel/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now panel-worker.service

# ─────────────────────────────
# Finish
# ─────────────────────────────
clear
echo -e "\n\e[1;32m✔ Setup Finished Successfully!\e[0m"
echo -e "\e[1;34m══════════════════════════════════════════════\e[0m"
echo -e "\e[1;36m 🌍 Access Panel : \e[1;37mhttps://${DOMAIN}\e[0m"
echo -e "\e[1;36m 📁 Installed At : \e[1;37m/var/www/panel\e[0m"
echo -e "\e[1;36m 👑 Create Admin : \e[1;37mphp artisan p:user:make\e[0m"
echo -e "\e[1;36m 🗝  Database User : \e[1;37m${DB_USER}\e[0m"
echo -e "\e[1;36m 🔐 Database Pass : \e[1;37m${DB_PASS}\e[0m"
echo -e "\e[1;34m══════════════════════════════════════════════\e[0m"
echo -e "\e[1;35m 🚀 Welcome to Subhan Hosting Panel! \e[0m"
