#!/usr/bin/env bash
# Автотесты в настоящем Factorio (headless-сервер 2.1 с Space Age).
# Использование: FACTORIO=/путь/к/factorio tools/run-tests.sh
#   FACTORIO — папка распакованного headless-сервера (в ней bin/x64/factorio и data/).
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO:?Укажите FACTORIO=/путь/к/папке/factorio}"
tools/package.sh >/dev/null
mkdir -p "$FACTORIO/mods"
rm -f "$FACTORIO/mods/mod-settings.dat" "$FACTORIO"/mods/space-age-plus-*.zip "$FACTORIO"/mods/sap-test_*.zip "$FACTORIO/sap-test.zip"
cp dist/*.zip "$FACTORIO/mods/"
tmp=$(mktemp -d); cp -r tests/sap-test "$tmp/sap-test_0.1.0"
(cd "$tmp" && zip -qr "$FACTORIO/mods/sap-test_0.1.0.zip" sap-test_0.1.0); rm -rf "$tmp"
"$FACTORIO/bin/x64/factorio" --create "$FACTORIO/sap-test.zip" >/dev/null
"$FACTORIO/bin/x64/factorio" --benchmark "$FACTORIO/sap-test.zip" --benchmark-ticks 30000 --benchmark-runs 1 >/dev/null || true
grep -h "SAP-TEST\|Error" "$FACTORIO/factorio-current.log"
grep -q "SAP-TEST DONE failures=0" "$FACTORIO/factorio-current.log"
