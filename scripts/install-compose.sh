#!/usr/bin/env bash
set -euo pipefail

# Optional: Compose overrides to match the Windows behavior:
#   dead_acute + c/C -> ç/Ç
#
# This script creates/updates ~/.XCompose by including the system default and
# adding ANSI-BR rules at the end.

HOME_DIR="${HOME}"
XCOMPOSE="${HOME_DIR}/.XCompose"
BACKUP="${HOME_DIR}/.XCompose.bak.$(date +%Y%m%d-%H%M%S)"

if [[ -f "${XCOMPOSE}" ]]; then
  cp -a "${XCOMPOSE}" "${BACKUP}"
  echo "Backed up existing ~/.XCompose to: ${BACKUP}"
fi

cat > "${XCOMPOSE}" <<'EOF'
include "%L"

! ANSI-BR overrides (to match Windows KLC behavior)
<dead_acute> <c> : "ç" U00E7
<dead_acute> <C> : "Ç" U00C7
EOF

echo "Wrote ${XCOMPOSE}"
echo "Log out and log in again if the change doesn't apply immediately."
