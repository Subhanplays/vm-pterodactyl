#!/bin/bash
# ==============================
# 🚀 NebulaPanel Auto Installer
# ==============================

# Function: Fresh Installation
nebula_install() {
    echo ">>> 🚀 Starting brand new setup for NebulaPanel..."

    # Step 1: Install Node.js 20.x
    sudo apt-get install -y curl gnupg ca-certificates
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | \
        sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get install -y nodejs

    # Step 2: Install Yarn, dependencies & fetch NebulaPanel release
    npm install -g yarn
    cd /var/www/panel || { echo "❌ Directory /var/www/panel not found"; exit 1; }
    yarn
    sudo apt install -y git zip unzip wget

    echo ">>> 📦 Pulling latest NebulaPanel package..."
    wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | \
        grep 'browser_download_url' | cut -d '"' -f 4)" -O nebula_release.zip

    echo ">>> 📂 Extracting package..."
    unzip -o nebula_release.zip

    # Step 3: Run installer script
    if [ ! -f "nebula.sh" ]; then
        echo "❌ nebula.sh not found in the extracted files."
        exit 1
    fi

    chmod +x nebula.sh
    bash nebula.sh
}

# Function: Reinstallation
nebula_reinstall() {
    echo ">>> 🔄 Running reinstallation for NebulaPanel..."
    nebula -rerun
}

# Function: Update
nebula_update() {
    echo ">>> ⬆️ Updating NebulaPanel..."
    nebula -update
    echo "✅ Update completed!"
}

# --- Interactive Menu ---
#!/bin/bash
# ==============================
# 🚀 NebulaPanel Auto Installer
# ==============================

# Function: Fresh Installation
nebula_install() {
    echo ">>> 🚀 Starting brand new setup for NebulaPanel..."

    # Step 1: Install Node.js 20.x
    sudo apt-get install -y curl gnupg ca-certificates
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | \
        sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update
    sudo apt-get install -y nodejs

    # Step 2: Install Yarn, dependencies & fetch NebulaPanel release
    npm install -g yarn
    cd /var/www/panel || { echo "❌ Directory /var/www/panel not found"; exit 1; }
    yarn
    sudo apt install -y git zip unzip wget

    echo ">>> 📦 Pulling latest NebulaPanel package..."
    wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | \
        grep 'browser_download_url' | cut -d '"' -f 4)" -O nebula_release.zip

    echo ">>> 📂 Extracting package..."
    unzip -o nebula_release.zip

    # Step 3: Run installer script
    if [ ! -f "nebula.sh" ]; then
        echo "❌ nebula.sh not found in the extracted files."
        exit 1
    fi

    chmod +x nebula.sh
    bash nebula.sh
}

# Function: Reinstallation
nebula_reinstall() {
    echo ">>> 🔄 Running reinstallation for NebulaPanel..."
    nebula -rerun
}

# Function: Update
nebula_update() {
    echo ">>> ⬆️ Updating NebulaPanel..."
    nebula -update
    echo "✅ Update completed!"
}

# --- Interactive Menu ---
while true; do
    clear
    echo -e "\e[1;34m╔══════════════════════════════════════╗\e[0m"
    echo -e "\e[1;34m║      🚀 Orion Control Dashboard      ║\e[0m"
    echo -e "\e[1;34m╚══════════════════════════════════════╝\e[0m"
    echo ""
    echo -e " [1] 🔧 Run Full Installation"
    echo -e " [2] ♻️  Re-run Setup (Repair Mode)"
    echo -e " [3] ⬆️  Upgrade to Latest Version"
    echo -e " [0] ❌ Exit Manager"
    echo ""
    read -p "👉 Enter your choice: " action

    case $action in
        1) nebula_install ;;
        2) nebula_reinstall ;;
        3) nebula_update ;;
        0) echo -e "\e[1;32m✔ Exiting Orion Manager... Bye!\e[0m"; exit 0 ;;
        *) echo -e "\e[1;31m⚠ Invalid selection! Please try again.\e[0m" ;;
    esac
    sleep 2
done

