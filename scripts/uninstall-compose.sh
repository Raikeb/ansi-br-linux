#!/usr/bin/env bash
set -euo pipefail

# Removes ANSI-BR compose overrides from ~/.XCompose.
# If your ~/.XCompose contains other customizations, edit it manually instead.

XCOMPOSE="${HOME}/.XCompose"
if [[ ! -f "${XCOMPOSE}" ]]; then
  echo "~/.XCompose not found. Nothing to do."
  exit 0
fi

if grep -q "ANSI-BR overrides" "${XCOMPOSE}"; then
  BACKUP="${HOME}/.XCompose.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a "${XCOMPOSE}" "${BACKUP}"
  echo "Backed up to: ${BACKUP}"
  # Keep only the include line, drop the ANSI-BR block
  awk '
    NR==1 {print; next}
    /! ANSI-BR overrides/ {exit}
    {print}
  ' "${BACKUP}" > "${XCOMPOSE}" || true
  echo "Removed ANSI-BR block from ~/.XCompose"
else
  echo "ANSI-BR block not found in ~/.XCompose. Nothing to do."
fi
