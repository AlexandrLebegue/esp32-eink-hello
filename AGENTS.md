# AGENTS.md — esp32-eink-hello

Projet de démonstration : un ESP32 relié à un écran e-paper (e-ink) qui affiche « Hello World »,
conçu et vérifié dans le simulateur **Velxio** auto-hébergé (LXC 110, http://192.168.1.75:3080).

## Outils disponibles

### 1. Serveur MCP `velxio` (déjà configuré dans opencode.json)
Outils : `create_circuit`, `update_circuit`, `export_wokwi_json`, `import_wokwi_json`,
`generate_code_files`, `compile_project`, `run_project`.
- Utilise `create_circuit` puis `export_wokwi_json` pour produire `diagram.json`.
- **N'utilise PAS `compile_project` pour l'ESP32** : il passe par arduino-cli et le cœur esp32 n'est
  volontairement pas installé (trop lourd). Il ne marche que pour l'AVR / le RP2040.

### 2. Compilation ESP32 : API REST de Velxio (ESP-IDF intégré)
```
POST http://192.168.1.75:3080/api/compile/
Content-Type: application/json
{"board_fqbn": "esp32:esp32:esp32",
 "libraries": ["GxEPD2", "Adafruit GFX Library", "Adafruit BusIO"],
 "files": [{"name": "sketch.ino", "content": "..."}]}
```
Réponse : `success` (bool), `binary_type` ("bin"), `binary_content` (base64), `stderr`, `error`.
Les 3 bibliothèques sont toutes nécessaires (GxEPD2 dépend de Adafruit GFX, qui dépend de BusIO).
Une compilation prend ~1 min (cache ccache ensuite). Ne lance pas de compilations en parallèle.

## Composants Velxio à utiliser
- Carte : `wokwi-esp32-devkit-v1` (id conseillé `esp`), FQBN `esp32:esp32:esp32`.
- Écran : type `velxio-epaper`, attribut `panelKind` = `epaper-1in54-bw` (1,54", 200×200, N/B, contrôleur
  SSD1681 → classe GxEPD2 `GxEPD2_154_D67`). Broches : GND, VCC, SCK, SDI, CS, DC, RST, BUSY.
- Câblage SPI matériel de l'ESP32 (VSPI) : SCK → GPIO18, SDI (MOSI) → GPIO23, CS → GPIO5,
  DC → GPIO17, RST → GPIO16, BUSY → GPIO4, VCC → 3V3, GND → GND.
- Constructeur GxEPD2 : `(CS, DC, RST, BUSY)` = `(5, 17, 16, 4)`.

## Livrables (à la racine du dépôt)
- `sketch/sketch.ino` : affiche « Hello World » centré, police Adafruit GFX lisible, puis `hibernate()`.
  Écrit aussi « Hello World » sur le port série (115200) pour le contrôle.
- `diagram.json` : circuit au format Wokwi, issu de `export_wokwi_json` (importable dans Velxio).
- `scripts/compile.sh` : compile via l'API REST ci-dessus (curl + python3 stdlib), sort en erreur si
  `success` est faux, écrit `build/firmware.bin`. `build/` est dans `.gitignore`.
- `README.md` en français : but, schéma de câblage (tableau), comment compiler, comment ouvrir le projet
  dans Velxio (import de `diagram.json` + coller le sketch) et ce qu'on doit voir.

## Règles
- Commits en français, petits et clairs. Pousse sur `origin main` à la fin (`git push`).
- Avant de déclarer fini : `scripts/compile.sh` doit réussir et `diagram.json` doit être un JSON valide
  contenant l'ESP32, l'écran et les 8 connexions.
- N'installe rien sur la machine (pas de pip, pas de npm, pas d'arduino-cli).
- Dépôt PUBLIC : aucun secret, aucune IP autre que celle du simulateur local documentée ici.
