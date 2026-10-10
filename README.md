<!-- ============================================================ -->
<!--  SPACEWATCH MARIANNE — README PRO                            -->
<!-- ============================================================ -->

<div align="center">

<!-- Bandeau tricolore -->
![Bleu](https://img.shields.io/badge/-000091?style=for-the-badge)
![Blanc](https://img.shields.io/badge/-FFFFFF?style=for-the-badge)
![Rouge](https://img.shields.io/badge/-E1000F?style=for-the-badge)

# 🇫🇷 SPACEWATCH · CELLULE DE VEILLE SPATIALE

**Dashboard temps réel de météo spatiale — Marianne · Bleu Blanc Rouge**

[![License: MIT](https://img.shields.io/badge/License-MIT-000091?style=flat-square)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.11+-000091?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![Bash](https://img.shields.io/badge/Bash-5.0+-E1000F?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![NOAA SWPC](https://img.shields.io/badge/Data-NOAA%20SWPC-000091?style=flat-square)](https://www.swpc.noaa.gov/)
[![Plotly](https://img.shields.io/badge/Plotly-2.35-E1000F?style=flat-square&logo=plotly&logoColor=white)](https://plotly.com/)
[![Leaflet](https://img.shields.io/badge/Leaflet-1.9-000091?style=flat-square&logo=leaflet&logoColor=white)](https://leafletjs.com/)

[![Status](https://img.shields.io/badge/Status-Production-16a34a?style=flat-square)]()
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-000091?style=flat-square)]()
[![Made in France](https://img.shields.io/badge/Made%20in-France%20🇫🇷-E1000F?style=flat-square)]()

**Liberté · Égalité · Fraternité**

</div>

---

## 📖 Sommaire

- [Présentation](#-présentation)
- [Fonctionnalités](#-fonctionnalités)
- [Aperçu](#-aperçu)
- [Installation](#-installation)
- [Utilisation](#-utilisation)
- [Architecture](#-architecture)
- [Sources de données](#-sources-de-données)
- [Configuration](#-configuration)
- [Export CSV](#-export-csv)
- [Dépannage](#-dépannage)
- [Roadmap](#-roadmap)
- [Licence](#-licence)
- [Auteur](#-auteur)

---

## 🎯 Présentation

**Spacewatch Marianne** est un dashboard temps réel de surveillance de la météo spatiale, habillé aux couleurs de la République Française (Bleu `#000091`, Blanc `#FFFFFF`, Rouge `#E1000F`).

Il agrège les données **NOAA SWPC** (Space Weather Prediction Center), les traite en Python, et les restitue dans une interface web élégante avec graphiques interactifs, prévisions et alertes.

> **Un seul script.** `spacewatch_marianne.sh` installe, configure, génère et lance tout.

---

## ✨ Fonctionnalités

### 🌡️ Métriques temps réel

| Indicateur | Description | Unité |
|---|---|---|
| **Kp** | Indice géomagnétique planétaire | 0–9 |
| **X-ray** | Flux solaire X | W/m² (classe A/B/C/M/X) |
| **Dst** | Perturbation du champ magnétique | nT |
| **Vent solaire** | Vitesse du vent | km/s |
| **Densité** | Densité particulaire | p/cc |
| **Bz / Bt** | Composantes du champ interplanétaire | nT |

### 📊 Visualisation

- **6 cartes KPI** style officiel
- **6 graphiques Plotly** interactifs (zoom, hover, légende)
- **Carte mondiale Leaflet** centrée France avec cercles de couverture
- **Prévision Kp 3 jours** avec barres G1/G2/G3
- **Rafraîchissement auto** toutes les 5 s

### ⚙️ Technique

- **Watch mode** : détection automatique de nouveaux fichiers JSON
- **Cache partagé** unifié (`.watch_state.json`)
- **Export CSV** des séries temporelles
- **Rapport texte** de diff premier → dernier
- **Correction timezone** : `datetime.now(timezone.utc)`
- **Isolation venv** pour éviter les conflits NumPy

---

## 🖼️ Aperçu

```
┌──────────────────────────────────────────────────────────────┐
│  ██████████  BLANC  ██████████  (TRICOLORE)                  │
├──────────────────────────────────────────────────────────────┤
│  [RF] RÉPUBLIQUE FRANÇAISE          Liberté · Égalité · ...  │
│       Ministère des Armées                                    │
│       Cellule de veille spatiale                              │
├──────────────────────────────────────────────────────────────┤
│  🛰️ SPACEWATCH · CELLULE DE VEILLE SPATIALE                  │
├──────────────────────────────────────────────────────────────┤
│  [📊 KPI] [📈 GRAPHS] [🗺️ MAP] [🔮 FORECAST] [⟳] [🔄 AUTO]  │
├──────────────────────────────────────────────────────────────┤
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐     │
│  │ Kp   │ │X-ray │ │ Dst  │ │ Vent │ │Dens. │ │ Bz   │     │
│  │ 3.33 │ │3.4e-6│ │ 25   │ │372   │ │ 7.2  │ │-1.37 │     │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘     │
├──────────────────────────────────────────────────────────────┤
│  📈 Graphiques Plotly (Kp, X-ray, Dst, Vent, Bz, Forecast)  │
├──────────────────────────────────────────────────────────────┤
│  🗺️ Carte monde · Cercles 2000 km / 5000 km                 │
├──────────────────────────────────────────────────────────────┤
│  🔮 Prévision Kp 3 jours                                    │
│  11/10 00:00  5.67  [G2]  ████████████████████████████      │
│  11/10 03:00  4.67  [G1]  ███████████████████████           │
├──────────────────────────────────────────────────────────────┤
│  ██████████  BLANC  ██████████  (TRICOLORE)                  │
│  © 2026 · SPACEWATCH · Tous droits réservés                 │
└──────────────────────────────────────────────────────────────┘
```

---

## 🚀 Installation

### Prérequis

- **Linux** ou **macOS**
- **Python 3.11+**
- **Bash 5.0+**
- **Navigateur moderne** (Chrome, Firefox, Safari, Edge)

### Installation rapide

```bash
# 1. Cloner le dépôt
git clone https://github.com/<user>/spacewatch-marianne.git
cd spacewatch-marianne

# 2. Placer les fichiers JSON dans export/
mkdir -p export
cp /chemin/vers/spacewatch_*.json export/

# 3. Lancer
chmod +x spacewatch_marianne.sh
./spacewatch_marianne.sh
```

Le script :
1. Crée un venv `.venv/`
2. Installe `numpy` + `matplotlib`
3. Génère `graph.py`, `watch.py`, `dashboard/`
4. Lance le serveur HTTP sur `http://localhost:8080`
5. Ouvre le navigateur
6. Démarre le watch mode

---

## 🎮 Utilisation

### Lancement standard

```bash
./spacewatch_marianne.sh
```

### Personnalisation

```bash
# Port personnalisé
PORT=9090 ./spacewatch_marianne.sh

# Intervalle de surveillance (secondes)
INTERVAL=5 ./spacewatch_marianne.sh

# Python personnalisé
PYTHON=python3.12 ./spacewatch_marianne.sh

# Combinaison
PORT=9090 INTERVAL=5 ./spacewatch_marianne.sh
```

### Variables d'environnement

| Variable | Défaut | Description |
|---|---|---|
| `PORT` | `8080` | Port du serveur HTTP |
| `INTERVAL` | `10` | Intervalle de polling (s) |
| `PYTHON` | `python3` | Interpréteur Python |

### Arrêt

`Ctrl+C` → arrêt propre des processus serveur + watch.

---

## 🏗️ Architecture

```
spacewatch-marianne/
├── spacewatch_marianne.sh     # 🚀 Script unique tout-en-un
├── README.md                  # 📖 Ce fichier
├── LICENSE                    # ⚖️ MIT
├── export/                    # 📥 Fichiers JSON NOAA SWPC
│   ├── spacewatch_20261009T201215Z.json
│   ├── spacewatch_20261010T165943Z.json
│   └── ...
├── dashboard/                 # 🌐 Généré par le script
│   ├── index.html             #    Structure HTML
│   ├── style.css              #    Thème Marianne
│   ├── app.js                 #    Logique JS
│   └── data.json              #    Données temps réel
├── plots/                     # 📊 PNG générés
│   ├── kp.png
│   ├── xray.png
│   └── ...
├── graph.py                   # 🐍 Généré
├── watch.py                   # 👁️ Généré
├── .watch_state.json          # 💾 Cache partagé
├── spacewatch_series.csv      # 📄 Export CSV
└── spacewatch_report.txt      # 📋 Rapport de diff
```

### Pipeline

```
export/*.json
    │
    ▼
graph.py ──► data.json ──► dashboard HTML
    │           │
    │           └──► fetch toutes les 5s
    │
    ├──► plots/*.png
    ├──► spacewatch_series.csv
    └──► spacewatch_report.txt
    ▲
    │
watch.py ──► détecte nouveaux fichiers toutes les 10s
```

---

## 🌐 Sources de données

| Source | Description | URL |
|---|---|---|
| **NOAA SWPC** | Space Weather Prediction Center | [swpc.noaa.gov](https://www.swpc.noaa.gov/) |
| **OMNI** | Indices historiques (Dst, F10.7) | [omniweb.gsfc.nasa.gov](https://omniweb.gsfc.nasa.gov/) |
| **GOES** | Satellites géostationnaires | [goes.noaa.gov](https://www.goes.noaa.gov/) |

### Format JSON

```json
{
  "generated_at": "2026-10-10T17:21:21.983358+00:00",
  "source": "noaa-swpc",
  "realtime": {
    "kp": { "value": 3.33, "time": "2026-10-10T12:00:00" },
    "wind": { "speed": 374.0, "density": 6.96, "temp": 153742.0 },
    "mag": { "bx": -5.86, "by": -0.14, "bz": -1.32, "bt": 6.02 },
    "xray": { "flux": 3.498843625493464e-06 }
  },
  "forecast": {
    "kp_3day": [...],
    "max_kp_forecast": 5.67
  },
  "omni_indices": {
    "dst": { "value": 38.0 },
    "f107": { "value": 109.0 }
  }
}
```

---

## ⚙️ Configuration

### Seuils d'alerte géomagnétique

| Échelle | Kp | Description |
|---|---|---|
| **G1** | 5 | Mineure |
| **G2** | 6 | Modérée |
| **G3** | 7 | Forte |
| **G4** | 8 | Sévère |
| **G5** | 9 | Extrême |

### Classes d'éruption solaire

| Classe | Flux (W/m²) | Description |
|---|---|---|
| **A** | < 1e-7 | Faible |
| **B** | 1e-7 – 1e-6 | Faible |
| **C** | 1e-6 – 1e-5 | Modérée |
| **M** | 1e-5 – 1e-4 | Forte |
| **X** | > 1e-4 | Très forte |

---

## 📥 Export CSV

Le CSV `spacewatch_series.csv` contient les colonnes :

```csv
time,kp,xray,dst,wind_speed,wind_density,wind_temp,bx,by,bz,bt,f107
2026-10-09T20:12:15.647395+00:00,1.0,9.215247018801165e-07,-16.0,365.8,5.7,71849.0,0.93,3.68,-3.17,5.0,112.0
...
```

### Analyse rapide

```bash
# Afficher les 10 dernières lignes
tail -10 spacewatch_series.csv

# Filtrer les Kp > 3
awk -F, 'NR==1 || $2>3' spacewatch_series.csv

# Graphique gnuplot
gnuplot -e "set datafile separator ','; plot 'spacewatch_series.csv' using 2 with lines"
```

---

## 🔧 Dépannage

### Erreur NumPy 1.x / 2.x

```
ImportError: numpy.core.multiarray failed to import
```

**Solution** : le venv isole les dépendances.

```bash
rm -rf .venv
./spacewatch_marianne.sh
```

### Warning `datetime.utcnow()`

```
DeprecationWarning: datetime.datetime.utcnow() is deprecated
```

**Solution** : déjà corrigé dans le script (utilise `datetime.now(timezone.utc)`).

### Dashboard pas à jour

```bash
# Vérifier que data.json est récent
ls -lh dashboard/data.json

# Vérifier le serveur HTTP
curl http://localhost:8080/data.json | head

# Forcer un refresh
python3 graph.py
```

### Port déjà utilisé

```bash
PORT=9090 ./spacewatch_marianne.sh
```

### Watch ne détecte rien

```bash
# Vérifier le cache
cat .watch_state.json

# Réinitialiser
rm .watch_state.json
```

---

## 🗺️ Roadmap

- [x] Dashboard Marianne
- [x] Watch mode
- [x] Export CSV
- [x] Graphiques Plotly
- [x] Carte Leaflet
- [ ] Satellites SGP4 temps réel
- [ ] Notifications desktop (G1/G2)
- [ ] Page dédiée alertes NOAA
- [ ] Mode plein écran salle de contrôle
- [ ] Docker Compose
- [ ] API REST
- [ ] Websocket temps réel

---

## 📄 Licence

```
MIT License

Copyright (c) 2026 Spacewatch Marianne

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 👤 Auteur

<div align="center">

**SPACEWATCH Marianne**

[![GitHub](https://img.shields.io/badge/GitHub-@<user>-000091?style=for-the-badge&logo=github&logoColor=white)](https://github.com/gunout)

**Liberté · Égalité · Fraternité** 🇫🇷

</div>

---

<div align="center">

![Bleu](https://img.shields.io/badge/-000091?style=for-the-badge)
![Blanc](https://img.shields.io/badge/-FFFFFF?style=for-the-badge)
![Rouge](https://img.shields.io/badge/-E1000F?style=for-the-badge)

*République Française — Ministère des Armées*
*Cellule de veille spatiale*

</div>
