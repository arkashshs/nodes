#!/bin/bash

set -e

BACKUP_DIR="backups"
BROWSER_DIR="browser"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="thorium_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "🔒 Gracefully shutting down Thorium inside container..."
docker exec thorium_browser pkill -SIGTERM -f thorium || true
sleep 2

echo "🧊 Pausing container..."
docker pause thorium_browser

echo "▶️ Unpausing container temporarily for cleanup..."
docker unpause thorium_browser

echo "🧹 Cleaning junk cache inside container..."
docker exec thorium_browser bash -c "
  rm -rf /config/.config/thorium/Default/Cache \
         /config/.config/thorium/Default/Code\ Cache \
         /config/.config/thorium/ShaderCache \
         /config/.config/thorium/GPUCache \
         /config/.config/thorium/Singleton*
"

echo "🧊 Pausing container again for clean backup..."
docker pause thorium_browser

echo "💾 Creating clean backup tarball..."
docker cp thorium_browser:/config "$BACKUP_DIR"/config_tmp_${TIMESTAMP}

tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C "$BACKUP_DIR" config_tmp_${TIMESTAMP}
rm -rf "$BACKUP_DIR"/config_tmp_${TIMESTAMP}

docker unpause thorium_browser

echo "✅ Backup complete: $BACKUP_DIR/$BACKUP_FILE"
