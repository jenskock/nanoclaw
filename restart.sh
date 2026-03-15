#!/usr/bin/env bash
set -e

echo "Restarting NanoClaw..."
systemctl --user restart nanoclaw
systemctl --user status nanoclaw --no-pager
