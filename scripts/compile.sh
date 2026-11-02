#!/usr/bin/env bash
# Compile sketch/sketch.ino pour ESP32 via l'API REST du simulateur Velxio
# (ESP-IDF) et écrit le résultat dans build/firmware.bin.
set -euo pipefail

API_URL="${VELXIO_API_URL:-http://192.168.1.75:3080/api/compile/}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKETCH="$ROOT/sketch/sketch.ino"
OUT="$ROOT/build/firmware.bin"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. Construction du JSON de requête (python3, stdlib uniquement).
python3 - "$SKETCH" "$TMP/payload.json" <<'PY'
import json, sys
sketch_path, out_path = sys.argv[1], sys.argv[2]
with open(sketch_path, encoding="utf-8") as f:
    content = f.read()
payload = {
    "board_fqbn": "esp32:esp32:esp32",
    "libraries": ["GxEPD2", "Adafruit GFX Library", "Adafruit BusIO"],
    "files": [{"name": "sketch.ino", "content": content}],
}
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(payload, f)
PY

# 2. Appel de l'API (curl). ~1 min la première fois, plus rapide avec ccache.
echo "Compilation via $API_URL (≈ 1 min)…"
HTTP_CODE="$(curl -sS --max-time 600 -o "$TMP/response.json" -w '%{http_code}' \
  -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  --data "@$TMP/payload.json")"

# 3. Vérification du résultat : on sort en erreur si success est faux.
python3 - "$TMP/response.json" "$OUT" "$HTTP_CODE" <<'PY'
import base64, json, os, sys
resp_path, out_path, http_code = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(resp_path, encoding="utf-8") as f:
        body = json.load(f)
except Exception:
    with open(resp_path, encoding="utf-8", errors="replace") as f:
        raw = f.read()
    sys.stderr.write("Réponse invalide (HTTP %s) : %s\n" % (http_code, raw[:4000]))
    sys.exit(1)
if http_code != "200" or not body.get("success"):
    sys.stderr.write("Échec de la compilation (HTTP %s, success=%s).\n" % (http_code, body.get("success")))
    for key in ("stderr", "error"):
        if body.get(key):
            sys.stderr.write("--- %s ---\n%s\n" % (key, body[key]))
    sys.exit(1)
os.makedirs(os.path.dirname(out_path), exist_ok=True)
data = base64.b64decode(body["binary_content"])
with open(out_path, "wb") as f:
    f.write(data)
print("OK : %s (%d octets, %s)" % (out_path, len(data), body.get("binary_type", "?")))
PY
