#!/bin/bash

set -eo

# Uncomment for debugging
# set -x

#########################################
# SETUP VARIABLES AND DEFAULTS #
#########################################
if [[ -z "$DEPLOY_PATH" || "$DEPLOY_PATH" == "/" || ! "$DEPLOY_PATH" =~ ^[a-zA-Z0-9/_\.\-]+$ || "$DEPLOY_PATH" != */* ]]; then
  echo "x︎ DEPLOY_PATH is invalid or unsafe: '$DEPLOY_PATH'"
  exit 1
fi

#########################################
# PREPARE REMOTE PATH #
#########################################

echo "➤ Preparing remote path..."
if ssh server "mkdir -p '$DEPLOY_PATH'"; then
  echo "✓ Remote path ensured."
else
  echo "x︎ Failed to create remote path. Exiting..."
  exit 1
fi

#########################################
# DEPLOY FILES VIA RSYNC #
#########################################

echo "➤ Deploying files via rsync..."

# Always ensure .distignore exists
[[ -f "$GITHUB_WORKSPACE/.distignore" ]] || {
  echo "ℹ︎ .distignore not found, creating an empty one"
  touch "$GITHUB_WORKSPACE/.distignore"
}

# Run rsync command
rsync -avz --delete --no-o --no-g \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='.gitignore' \
  --exclude='.gitattributes' \
  --exclude='.gitmodules' \
  --exclude='.editorconfig' \
  --exclude='.distignore' \
  --exclude='/vendor/' \
  --exclude='node_modules/' \
  --exclude='/uploads/' \
  --exclude='/upgrade/' \
  --exclude='/backups/' \
  --exclude='/advanced-cache.php' \
  --exclude='/object-cache.php' \
  --exclude='/db.php' \
  --exclude='/cache/' \
  --exclude='*.log' \
  --exclude='*.bak' \
  --exclude='*.zip' \
  --exclude='*.tar.gz' \
  --exclude='*.sql' \
  --exclude='*.sqlite' \
  --exclude='*.db' \
  --exclude-from="$GITHUB_WORKSPACE/.distignore" \
  "$GITHUB_WORKSPACE/" "server:$DEPLOY_PATH"

echo "✓ Files deployed successfully!"

#########################################
# FLUSH CACHES IF WP-CLI IS AVAILABLE #
#########################################

echo "➤ Checking for WP-CLI and flushing caches..."

ssh server "cd '$DEPLOY_PATH' && if command -v wp >/dev/null 2>&1; then
  echo 'ℹ︎ WP-CLI found. Flushing caches...'
  wp cache flush --allow-root || true
  wp transient delete --all --allow-root || true
  wp rewrite flush --hard --allow-root || true
  echo '✓ Cache flush completed.'
else
  echo 'ℹ︎ WP-CLI not found. Skipping cache flush.'
fi"

#########################################
# FINAL SUMMARY #
#########################################

echo "✓ Deployment process finished."
