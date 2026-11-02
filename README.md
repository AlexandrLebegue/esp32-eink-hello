# ESP32 + écran e-paper 1,54" — « Hello World »

Projet de démonstration : une carte **ESP32** pilote un **écran e-paper (e-ink) de 1,54"**
(200×200, noir et blanc, contrôleur SSD1681) et y affiche **« Hello World »** centré, puis met
l'écran en hibernation. Le même message est écrit sur le port série (115200) pour le contrôle.

Le projet est conçu et vérifié dans le simulateur **Velxio** auto-hébergé
(LXC 110, `http://192.168.1.75:3080`).

## Contenu du dépôt

| Fichier | Rôle |
|---|---|
| `sketch/sketch.ino` | Sketch : initialise l'écran (GxEPD2), affiche « Hello World » centré, hiberne, écrit sur la série |
| `diagram.json` | Circuit au format Wokwi (ESP32 + écran + câblage), importable dans Velxio |
| `scripts/compile.sh` | Compile le sketch via l'API REST de Velxio (ESP-IDF) et écrit `build/firmware.bin` |
| `build/` | Firmware compilé (généré, ignoré par git) |

## Schéma de câblage

SPI matériel de l'ESP32 (VSPI) ; l'écran est alimenté sur 3,3 V.

| Broche écran | Broche ESP32 | Rôle |
|---|---|---|
| SCK  | GPIO18 | Horloge SPI (SCLK) |
| SDI  | GPIO23 | Données SPI (MOSI) |
| CS   | GPIO5  | Chip select |
| DC   | GPIO17 | Donnée / Commande |
| RST  | GPIO16 | Reset |
| BUSY | GPIO4  | Occupation de l'écran |
| VCC  | 3V3    | Alimentation 3,3 V |
| GND  | GND    | Masse |

Côté logiciel, le constructeur GxEPD2 reçoit `(CS, DC, RST, BUSY) = (5, 17, 16, 4)` ;
SCK et MOSI sont les broches par défaut du bus SPI matériel de l'ESP32 (18 et 23).

## Bibliothèques

- **GxEPD2** (classe `GxEPD2_154_D67` pour l'écran 1,54" GDEH0154D67 / SSD1681)
- **Adafruit GFX Library** (rendu graphique, police `FreeMonoBold9pt7b`)
- **Adafruit BusIO** (dépendance de Adafruit GFX)

## Compiler

Le sketch est compilé par le simulateur Velxio via son API REST (ESP-IDF intégré) :

```sh
scripts/compile.sh
```

- Envoie `sketch/sketch.ino` à `http://192.168.1.75:3080/api/compile/` avec les trois
  bibliothèques ci-dessus (FQBN `esp32:esp32:esp32`).
- Vérifie le drapeau `success` de la réponse : le script sort en erreur (avec les log de
  compilation) si elle est fausse.
- Sur succès, décode le firmware et l'écrit dans `build/firmware.bin`.
- La première compilation dure environ 1 minute ; les suivantes sont plus rapides (ccache).

## Ouvrir le projet dans Velxio

1. Ouvrir Velxio (`http://192.168.1.75:3080`) et importer le circuit avec
   **`diagram.json`** (import du format Wokwi).
2. Coller le contenu de **`sketch/sketch.ino`** dans l'éditeur du projet.
3. Lancer la simulation.

### Ce qu'on doit voir

- L'écran e-paper 1,54" affiche **« Hello World »** centré (police FreeMono Bold ~9 pt),
  puis le contrôleur passe en hibernation (image conservée, consommation minimale).
- La console série affiche `Hello World` (115200 bauds).

## Remarques

- Le firmware `build/firmware.bin` est un binaire ESP32 (format binaire de l'outchain
  ESP-IDF) ; il peut aussi être flashé directement sur un ESP32 réel câblé comme ci-dessus.
- Sur un écran réel, la première mise à jour complète prend quelques secondes ;
  l'hibernation se fait après l'affichage (`panel.hibernate()`).
