#!/usr/bin/env bash

source "$(dirname "$0")/../config/backup.conf"

find "$LOG_DIR" -type f -mtime +"$LOG_RETENTION_DAYS" -name '*.log' -delete

