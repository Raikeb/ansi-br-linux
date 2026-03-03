#!/usr/bin/env bash
set -euo pipefail

# ANSI-BR system-wide uninstaller
# Removes:
#   - /usr/share/X11/xkb/symbols/ansi-br
#   - The ANSI-BR block from /usr/share/X11/xkb/rules/evdev.xml
#   - The ANSI-BR lines from /usr/share/X11/xkb/rules/evdev.lst

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "ERROR: run as root (use sudo)." >&2
  exit 1
fi

XKB_DIR="/usr/share/X11/xkb"
RULES_DIR="${XKB_DIR}/rules"
SYMBOLS_DIR="${XKB_DIR}/symbols"
EVDEV_XML="${RULES_DIR}/evdev.xml"
EVDEV_LST="${RULES_DIR}/evdev.lst"

echo "[1/3] Removing symbols file (if present) -> ${SYMBOLS_DIR}/ansi-br"
rm -f "${SYMBOLS_DIR}/ansi-br"

echo "[2/3] Removing ANSI-BR block from ${EVDEV_XML} (if present)"
python3 - <<'PY'
import pathlib, re
evdev = pathlib.Path("/usr/share/X11/xkb/rules/evdev.xml")
text = evdev.read_text(encoding="utf-8", errors="surrogateescape")

new = re.sub(r"\s*<!-- BEGIN ANSI-BR -->.*?<!-- END ANSI-BR -->\s*\n?", "", text, flags=re.S)
if new != text:
    evdev.write_text(new, encoding="utf-8", errors="surrogateescape")
    print("  - Removed block from evdev.xml.")
else:
    print("  - No block found in evdev.xml (skipping).")
PY

echo "[3/3] Removing ANSI-BR lines from ${EVDEV_LST} (if present)"
python3 - <<'PY'
import pathlib, re
lst = pathlib.Path("/usr/share/X11/xkb/rules/evdev.lst")
text = lst.read_text(encoding="utf-8", errors="surrogateescape")

# Remove the marker section (if present)
new = re.sub(r"\n?\s*# BEGIN ANSI-BR\s*\n.*?\s*# END ANSI-BR\s*\n?", "\n", text, flags=re.S)
# Also remove any stray ansi-br line
new = re.sub(r"^\s*ansi-br\s+.*\n", "", new, flags=re.M)

if new != text:
    lst.write_text(new, encoding="utf-8", errors="surrogateescape")
    print("  - Removed ANSI-BR from evdev.lst.")
else:
    print("  - No ANSI-BR entry found in evdev.lst (skipping).")
PY

echo
echo "Done. Log out and log in again (or reboot) to fully reload keyboard layouts."
