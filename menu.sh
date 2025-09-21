#!/bin/bash
# ==========================================
# Subhan Hosting Control Center
# Version: 1.0
# Author : Subhan Zahid
# ==========================================

# ─────────────────────────────
# Colors & Styling
# ─────────────────────────────
C_RED="\e[31m"
C_GRN="\e[32m"
C_YLW="\e[33m"
C_BLU="\e[34m"
C_CYN="\e[36m"
C_RST="\e[0m"
C_BLD="\e[1m"

# ─────────────────────────────
# Dependency Check
# ─────────────────────────────
require_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "${C_RED}${C_BLD}[ERROR] curl is missing.${C_RST}"
        echo -e "${C_YLW}Attempting to install curl...${C_RST}"

        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y curl
        else
            echo -e "${C_RED}Could not auto-install curl. Please install manually.${C_RST}"
            exit 1
        fi
        echo -e "${C_GRN}[OK] curl installed.${C_RST}"
    fi
}

# ─────────────────────────────
# Fetch + Execute Remote Script
# ─────────────────────────────
fetch_and_run() {
    require_curl
    url=$1
    name=$2

    echo -e "${C_YLW}→ Downloading: ${C_CYN}${name}${C_RST}"

    tmpfile=$(mktemp)
    if curl -fsSL "$url" -o "$tmpfile"; then
        echo -e "${C_GRN}[OK] Download complete.${C_RST}"
        chmod +x "$tmpfile"
        bash "$tmpfile"
        status=$?
        rm -f "$tmpfile"

        if [ $status -eq 0 ]; then
            echo -e "${C_GRN}[SUCCESS] ${name} finished.${C_RST}"
        else
            echo -e "${C_RED}[FAILED] ${name} exited with code $status.${C_RST}"
        fi
    else
        echo -e "${C_RED}[ERROR] Could not fetch ${name}.${C_RST}"
    fi
    echo
    read -p "Press ENTER to return to menu..."
}

# ─────────────────────────────
# System Information
# ─────────────────────────────
show_system() {
    echo -e "${C_BLD}${C_CYN}--- SERVER DETAILS ---${C_RST}"
    echo "Hostname : $(hostname)"
    echo "User     : $(whoami)"
    echo "Location : $(pwd)"
    echo "Kernel   : $(uname -r)"
    echo "OS       : $(uname -o)"
    echo "Uptime   : $(uptime -p)"
    echo "Memory   : $(free -h | awk '/Mem:/ {print $3\"/\"$2}')"
    echo "Storage  : $(df -h / | awk 'NR==2 {print $3\"/\"$2 \" (\"$5\")\"}')"
    echo -e "${C_CYN}----------------------${C_RST}"
    echo
    read -p "Press ENTER to return to menu..."
}

# ─────────────────────────────
# Menu
# ─────────────────────────────
menu() {
    clear
    echo -e "${C_BLD}${C_BLU}=====================================${C_RST}"
    echo -e "${C_BLD}${C_YLW}   SUBHAN HOSTING CONTROL CENTER${C_RST}"
    echo -e "${C_BLD}${C_BLU}=====================================${C_RST}"
    echo -e "${C_BLD} 1)${C_RST} Panel"
    echo -e "${C_BLD} 2)${C_RST} Install Wings"
    echo -e "${C_BLD} 3)${C_RST} Blueprints Manager"
    echo -e "${C_BLD} 4)${C_RST} Theme Changer"
    echo -e "${C_BLD} 5)${C_RST} Exit"
    echo -ne "\n${C_BLD}Choose an option [1-9]: ${C_RST}"
}

# ─────────────────────────────
# Main Loop
# ─────────────────────────────
while true; do
    menu
    read -r choice
    case $choice in
        1) fetch_and_run "https://raw.githubusercontent.com/YourGitHub/SubhanHosting/main/panel.sh" "Panel" ;;
        2) fetch_and_run "https://raw.githubusercontent.com/YourGitHub/SubhanHosting/main/wings.sh" "Wings" ;;
        3) fetch_and_run "https://raw.githubusercontent.com/YourGitHub/SubhanHosting/main/blueprints.sh" "Blueprints" ;;
        4) fetch_and_run "https://raw.githubusercontent.com/YourGitHub/SubhanHosting/main/theme.sh" "Theme" ;;
        5) echo -e "${C_GRN}Goodbye!${C_RST}"; exit 0 ;;
        *) echo -e "${C_RED}Invalid choice! Try again.${C_RST}"; sleep 1 ;;
    esac
done
