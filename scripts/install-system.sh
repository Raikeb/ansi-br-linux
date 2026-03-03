#!/usr/bin/env bash
set -euo pipefail

# ANSI-BR system-wide installer for Debian/Ubuntu (tested on Ubuntu 24.04)
# Installs:
#   - /usr/share/X11/xkb/symbols/ansi-br
#   - Adds a new layout entry "ansi-br" to /usr/share/X11/xkb/rules/evdev.xml
#   - Adds a layout line to /usr/share/X11/xkb/rules/evdev.lst
#
# Safe(ish): creates timestamped backups before changing anything.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "ERROR: run as root (use sudo)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

XKB_DIR="/usr/share/X11/xkb"
RULES_DIR="${XKB_DIR}/rules"
SYMBOLS_DIR="${XKB_DIR}/symbols"
EVDEV_XML="${RULES_DIR}/evdev.xml"
EVDEV_LST="${RULES_DIR}/evdev.lst"

if [[ ! -f "${EVDEV_XML}" || ! -f "${EVDEV_LST}" ]]; then
  echo "ERROR: Could not find ${EVDEV_XML} or ${EVDEV_LST}. Is xkeyboard-config installed?" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/usr/local/share/ansi-br-backup-${STAMP}"
mkdir -p "${BACKUP_DIR}"

echo "[1/4] Backing up current files to: ${BACKUP_DIR}"
cp -a "${EVDEV_XML}" "${BACKUP_DIR}/evdev.xml"
cp -a "${EVDEV_LST}" "${BACKUP_DIR}/evdev.lst"
if [[ -f "${SYMBOLS_DIR}/ansi-br" ]]; then
  cp -a "${SYMBOLS_DIR}/ansi-br" "${BACKUP_DIR}/symbols.ansi-br"
fi

echo "[2/4] Installing symbols file -> ${SYMBOLS_DIR}/ansi-br"
install -m 0644 "${REPO_ROOT}/xkb/symbols/ansi-br" "${SYMBOLS_DIR}/ansi-br"

LAYOUT_BLOCK=$'    <!-- BEGIN ANSI-BR -->\n\
    <layout>\n\
      <configItem>\n\
        <name>ansi-br</name>\n\
        <shortDescription>pt</shortDescription>\n\
        <description>Portuguese (Brazil, ANSI-BR)</description>\n\
        <languageList>\n\
          <iso639Id>por</iso639Id>\n\
        </languageList>\n\
        <countryList>\n\
          <iso3166Id>BR</iso3166Id>\n\
        </countryList>\n\
      </configItem>\n\
      <variantList/>\n\
    </layout>\n\
    <!-- END ANSI-BR -->\n'

echo "[3/4] Patching ${EVDEV_XML} (adding layout 'ansi-br' if missing)"
python3 - <<'PY'
import pathlib, re, sys
evdev = pathlib.Path("/usr/share/X11/xkb/rules/evdev.xml")
text = evdev.read_text(encoding="utf-8", errors="surrogateescape")

if "<name>ansi-br</name>" in text:
    print("  - Layout already present in evdev.xml (skipping).")
    sys.exit(0)

marker = "</layoutList>"
idx = text.find(marker)
if idx < 0:
    print("ERROR: Could not find </layoutList> in evdev.xml", file=sys.stderr)
    sys.exit(2)

block = """    <!-- BEGIN ANSI-BR -->
    <layout>
      <configItem>
        <name>ansi-br</name>
        <shortDescription>pt</shortDescription>
        <description>Portuguese (Brazil, ANSI-BR)</description>
        <languageList>
          <iso639Id>por</iso639Id>
        </languageList>
        <countryList>
          <iso3166Id>BR</iso3166Id>
        </countryList>
      </configItem>
      <variantList/>
    </layout>
    <!-- END ANSI-BR -->
"""
new_text = text[:idx] + block + text[idx:]
evdev.write_text(new_text, encoding="utf-8", errors="surrogateescape")
print("  - Added ANSI-BR layout block.")
PY

echo "[4/4] Patching ${EVDEV_LST} (adding line under '! layout')"
python3 - <<'PY'
import pathlib, sys

lst = pathlib.Path("/usr/share/X11/xkb/rules/evdev.lst")
text = lst.read_text(encoding="utf-8", errors="surrogateescape")

if "\n  ansi-br" in text or "\nansi-br" in text:
    print("  - 'ansi-br' already present in evdev.lst (skipping).")
    sys.exit(0)

lines = text.splitlines(True)

# Find '! layout' section start and insert before next section header that starts with '! '
insert_at = None
for i, line in enumerate(lines):
    if line.strip() == "! layout":
        # Insert after the header line
        insert_at = i + 1
        break

if insert_at is None:
    # fallback: append at end
    lines.append("\n")
    lines.append("! layout\n")
    insert_at = len(lines)

# Advance past any immediately following layout entries? We want to keep alphabetical order optional.
# Insert near top of layout list for visibility.
entry = "  ansi-br         Portuguese (Brazil, ANSI-BR)\n"
marker_begin = "  # BEGIN ANSI-BR\n"
marker_end = "  # END ANSI-BR\n"
lines.insert(insert_at, marker_end)
lines.insert(insert_at, entry)
lines.insert(insert_at, marker_begin)

lst.write_text("".join(lines), encoding="utf-8", errors="surrogateescape")
print("  - Added ANSI-BR line to layout list.")
PY

echo
echo "Done."
echo "Next steps:"
echo "  1) Log out and log in again (or reboot)."
echo "  2) Settings -> Keyboard -> Input Sources -> '+' -> search for: ANSI-BR"
echo "  3) Optionally install Compose overrides: ${REPO_ROOT}/scripts/install-compose.sh"
echo
echo "Backup saved at: ${BACKUP_DIR}"
