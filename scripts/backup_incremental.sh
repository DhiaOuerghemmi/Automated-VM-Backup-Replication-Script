#!/usr/bin/env bash

source "$(dirname "$0")/../config/backup.conf"

mkdir -p "$BACKUP_DIR" "$TMP_DIR"

tar --create \
    --verbose \
    --listed-incremental="$SNAR_FILE" \
    --gzip \
    --file="$TMP_DIR/backup-$(date +%Y-%m-%d).tar.gz" \
    /path/to/vm/data

# Rotate full backups older than retention
find "$BACKUP_DIR" -type f -mtime +"$BACKUP_RETENTION_DAYS" -delete
