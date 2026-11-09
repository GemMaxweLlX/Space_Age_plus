#!/usr/bin/env bash
# Автотесты в настоящем Factorio (headless-сервер 2.1 с Space Age).
# Использование: FACTORIO=/путь/к/factorio [MODE=...] tools/run-tests.sh
#   FACTORIO — папка распакованного headless-сервера (в ней bin/x64/factorio и data/).
#   MODE:
#     fresh     (по умолчанию) — новая карта с модами;
#     saveload  — игра сохраняется на тике 2000, затем сохранение загружается и все
#                 оставшиеся проверки идут уже после загрузки;
#     migration — карта создаётся без модов Space Age+, затем моды добавляются
#                 (проверка on_configuration_changed — как у игрока с существующим сохранением);
#     player    — игра с настоящим игроком без экрана (--test-save): окна, кислород, лифт.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FACTORIO:?Укажите FACTORIO=/путь/к/папке/factorio}"
MODE="${MODE:-fresh}"
BIN="$FACTORIO/bin/x64/factorio"
LOG="$FACTORIO/factorio-current.log"
SAVE="$FACTORIO/sap-test.zip"

tools/package.sh >/dev/null
mkdir -p "$FACTORIO/mods" "$FACTORIO/mods-off"
rm -f "$FACTORIO/mods/mod-settings.dat" "$FACTORIO"/mods/space-age-plus-*.zip "$FACTORIO"/mods/sap-test_*.zip "$SAVE"
rm -f "$FACTORIO"/mods-off/*.zip "$FACTORIO"/saves/_autosave-sap-saveload.zip
tmp=$(mktemp -d); cp -r tests/sap-test "$tmp/sap-test_0.1.0"
(cd "$tmp" && zip -qr sap-test_0.1.0.zip sap-test_0.1.0)

install_mods() {
  cp dist/*.zip "$FACTORIO/mods/"
  cp "$tmp/sap-test_0.1.0.zip" "$FACTORIO/mods/"
}

case "$MODE" in
  fresh)
    install_mods
    "$BIN" --create "$SAVE" >/dev/null
    ;;
  migration)
    # Карта без модов Space Age+ играет на сервере ~20 секунд, сохраняется при остановке,
    # затем моды добавляются — как у игрока, который ставит мод в идущую игру.
    "$BIN" --create "$SAVE" >/dev/null
    settings=$(mktemp)
    python3 -I - "$FACTORIO/data/server-settings.example.json" "$settings" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d.update({"name": "sap-test", "visibility": {"public": False, "lan": False},
          "require_user_verification": False, "auto_pause": False, "autosave_interval": 0})
json.dump(d, open(sys.argv[2], "w"))
PY
    timeout 20 "$BIN" --start-server "$SAVE" --server-settings "$settings" --port 34197 >/dev/null 2>&1 || true
    rm -f "$settings"
    grep -q "Saving progress: 100" "$LOG" || { echo "SAP-TEST FAIL migration: server did not save"; exit 1; }
    install_mods
    ;;
  saveload)
    # Настоящий сервер без паузы играет ~45 секунд (≈2700 тиков) и при остановке сохраняет
    # карту в тот же файл; затем тесты продолжаются уже из этого сохранения.
    install_mods
    "$BIN" --create "$SAVE" >/dev/null
    settings=$(mktemp)
    python3 -I - "$FACTORIO/data/server-settings.example.json" "$settings" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d.update({"name": "sap-test", "visibility": {"public": False, "lan": False},
          "require_user_verification": False, "auto_pause": False, "autosave_interval": 0})
json.dump(d, open(sys.argv[2], "w"))
PY
    timeout 45 "$BIN" --start-server "$SAVE" --server-settings "$settings" --port 34197 >/dev/null 2>&1 || true
    rm -f "$settings"
    grep -q "Saving progress: 100" "$LOG" || { echo "SAP-TEST FAIL saveload: server did not save"; exit 1; }
    grep -h "SAP-TEST FAIL\|Error" "$LOG" | sed 's/^/before save: /' || true
    ;;
  player)
    # Игра с настоящим игроком (без экрана): окна, кислород, лифт.
    install_mods
    "$BIN" --create "$SAVE" >/dev/null
    rm -rf "$tmp"
    "$BIN" --test-save "$SAVE" --test-ticks 3000 --test-arg player >/dev/null 2>&1 || true
    grep -h "SAP-TEST\|Error" "$LOG"
    grep -q "SAP-TEST DONE failures=0" "$LOG"
    exit $?
    ;;
  *) echo "Unknown MODE=$MODE"; exit 2 ;;
esac
rm -rf "$tmp"

"$BIN" --benchmark "$SAVE" --benchmark-ticks 30000 --benchmark-runs 1 >/dev/null || true
grep -h "SAP-TEST\|Error" "$LOG"
grep -q "SAP-TEST DONE failures=0" "$LOG"
