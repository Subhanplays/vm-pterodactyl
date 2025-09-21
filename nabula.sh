#!/bin/bash

# ==========================================
# Orion Installer Script
# ==========================================

WORKDIR="/var/www/pterodactyl"
TMP_DIR="/tmp/orion-temp-repo"
REPO_URL="https://github.com/nobita586/ak-nobita-bot.git"
BLUEPRINT_FILE="nebula.blueprint"

echo "🔧 Preparing environment..."
mkdir -p "$WORKDIR"
rm -rf "$TMP_DIR"

# ------------------------------
# Clone temporary repository
# ------------------------------
echo "⬇️  Fetching latest source from GitHub..."
if ! git clone "$REPO_URL" "$TMP_DIR"; then
    echo "❌ Failed to clone repository from $REPO_URL"
    exit 1
fi

# ------------------------------
# Locate and move blueprint file
# ------------------------------
if [ -f "$TMP_DIR/src/$BLUEPRINT_FILE" ]; then
    mv "$TMP_DIR/src/$BLUEPRINT_FILE" "$WORKDIR/$BLUEPRINT_FILE"
    echo "✅ $BLUEPRINT_FILE installed into $WORKDIR"
else
    echo "❌ File $BLUEPRINT_FILE not found in repository!"
    rm -rf "$TMP_DIR"
    exit 1
fi

# ------------------------------
# Cleanup
# ------------------------------
rm -rf "$TMP_DIR"
echo "🧹 Cleaned up temporary files."

# ------------------------------
# Run blueprint automatically
# ------------------------------
cd "$WORKDIR" || { echo "❌ Failed to enter $WORKDIR"; exit 1; }

if command -v blueprint >/dev/null 2>&1; then
    echo "🚀 Executing blueprint installer..."
    blueprint -i "$BLUEPRINT_FILE"
    echo "🎉 Installation finished!"
else
    echo "⚠️  The 'blueprint' command is missing. Please install it first."
    exit 1
fi
