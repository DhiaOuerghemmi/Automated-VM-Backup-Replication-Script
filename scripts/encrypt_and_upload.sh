#!/usr/bin/env bash

source "$(dirname "$0")/../config/backup.conf"

LATEST="$TMP_DIR/backup-$(date +%Y-%m-%d).tar.gz"
ENC="$LATEST.gpg"

# Encrypt
gpg --batch --yes \
    --passphrase-file "$GPG_PASSPHRASE_FILE" \
    --output "$ENC" \
    --symmetric "$LATEST"

# Upload
aws s3 cp "$ENC" "s3://$S3_BUCKET/" \
    --region "$S3_REGION" \
    --only-show-errors

# Cleanup temp
rm -f "$LATEST" "$ENC"
