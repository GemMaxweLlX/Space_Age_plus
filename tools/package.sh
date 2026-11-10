#!/usr/bin/env bash
# Собирает каждый модуль в dist/<name>_<version>.zip (формат, который принимает Factorio).
# Использование: tools/package.sh [имя-модуля ...]   (без аргументов — все модули)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
mods=("$@")
[ ${#mods[@]} -eq 0 ] && mods=(space-age-plus-*/)
for dir in "${mods[@]}"; do
  dir="${dir%/}"
  name=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['name'])" "$dir/info.json")
  version=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['version'])" "$dir/info.json")
  tmp=$(mktemp -d)
  cp -r "$dir" "$tmp/${name}_${version}"
  (cd "$tmp" && zip -qr "${name}_${version}.zip" "${name}_${version}")
  mv "$tmp/${name}_${version}.zip" dist/
  rm -rf "$tmp"
  echo "dist/${name}_${version}.zip"
done
