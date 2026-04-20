#!/usr/bin/env bash
set -e

echo "Restarting NanoClaw..."
systemctl restart nanoclaw
systemctl status nanoclaw --no-pager
