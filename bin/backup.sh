#!/usr/bin/env bash
# bin/backup.sh

set -euo pipefail
IFS=$'\n\t'

# Load config
source "$(dirname "$0")/../config/backup.conf"

# Lockfile to prevent overlap
LOCKFILE="/var/lock/vm-backup.lock"
exec 200>"$LOCKFILE"
flock -n 200 || { echo "Another backup is running; exiting."; exit 1; }

# Timestamp
TS=$(date '+%Y-%m-%d_%H%M%S')

# Run incremental backup
"$(dirname "$0")/../scripts/backup_incremental.sh" 2>&1 | tee -a "$LOG_DIR/backup_$TS.log"

# Encrypt & upload
"$(dirname "$0")/../scripts/encrypt_and_upload.sh" 2>&1 | tee -a "$LOG_DIR/upload_$TS.log"

# Rotate old logs
"$(dirname "$0")/../scripts/rotate_logs.sh"

exit 0
