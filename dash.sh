#!/usr/bin/env bash
# =====================================================================
#  spacewatch_marianne.sh
#  Dashboard Marianne fusionné : météo spatiale + veille tactique
# =====================================================================
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_DIR="$BASE_DIR/export"
DASHBOARD_DIR="$BASE_DIR/dashboard"
VENV_DIR="$BASE_DIR/.venv"
PORT="${PORT:-8080}"
INTERVAL="${INTERVAL:-10}"
PYTHON="${PYTHON:-python3}"

BLEU='\033[38;5;19m'; ROUGE='\033[38;5;160m'; BLANC='\033[97m'; GRAS='\033[1m'; RESET='\033[0m'
log()  { echo -e "${BLEU}${GRAS}[spacewatch]${RESET} $*"; }
ok()   { echo -e "${BLANC}${GRAS}[✓]${RESET} $*"; }
warn() { echo -e "${ROUGE}${GRAS}[!]${RESET} $*"; }

banner() {
  echo -e "${BLEU}${GRAS}"
  cat <<'EOF'
  ███████╗██████╗  █████╗  ██████╗███████╗██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗
  ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║
  ███████╗██████╔╝███████║██║     █████╗  ██║ █╗ ██║███████║   ██║   ██║     ███████║
  ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝  ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║
  ███████║██║     ██║  ██║╚██████╗███████╗╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║
  ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝
EOF
  echo -e "${RESET}${BLANC}     Dashboard Marianne 🇫🇷 — Météo spatiale & veille tactique${RESET}\n"
}

cleanup() {
  [[ -n "${WATCH_PID:-}" ]] && kill "$WATCH_PID" 2>/dev/null || true
  [[ -n "${HTTP_PID:-}"  ]] && kill "$HTTP_PID"  2>/dev/null || true
  ok "Arrêt propre."
}
trap cleanup EXIT INT TERM

banner

# ---------------------------------------------------------------------
# 1. VÉRIFICATIONS
# ---------------------------------------------------------------------
log "Vérification de l'environnement..."
[[ -d "$EXPORT_DIR" ]] || { warn "export/ introuvable"; exit 1; }
COUNT=$(find "$EXPORT_DIR" -maxdepth 1 -name 'spacewatch_*.json' | wc -l)
[[ "$COUNT" -gt 0 ]] || { warn "Aucun spacewatch_*.json"; exit 1; }
ok "$COUNT fichier(s) JSON"

# ---------------------------------------------------------------------
# 2. VENV
# ---------------------------------------------------------------------
if [[ ! -d "$VENV_DIR" ]]; then
  log "Création venv..."
  "$PYTHON" -m venv "$VENV_DIR"
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# ---------------------------------------------------------------------
# 3. DÉPENDANCES
# ---------------------------------------------------------------------
log "Vérification dépendances..."
python -c "import numpy" 2>/dev/null || { pip install --quiet --upgrade pip; pip install --quiet numpy; }
python -c "import matplotlib" 2>/dev/null || pip install --quiet matplotlib
ok "numpy $(python -c 'import numpy;print(numpy.__version__)')"
ok "matplotlib $(python -c 'import matplotlib;print(matplotlib.__version__)')"

# ---------------------------------------------------------------------
# 4. DOSSIER DASHBOARD
# ---------------------------------------------------------------------
mkdir -p "$DASHBOARD_DIR"

# =====================================================================
# 5. INDEX.HTML — DESIGN MARIANNE FUSIONNÉ
# =====================================================================
log "Génération index.html..."
cat > "$DASHBOARD_DIR/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>🇫🇷 SPACEWATCH · Cellule de Veille Spatiale | République Française</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdn.plot.ly/plotly-2.35.2.min.js"></script>
<link rel="stylesheet" href="style.css">
</head>
<body>

<div class="tricolore">
  <span class="t-bleu"></span>
  <span class="t-blanc"></span>
  <span class="t-rouge"></span>
</div>

<div class="bandeau-etat">
  <div class="bandeau-etat-content">
    <div class="bloc-marianne">
      <div class="marianne-sceau">RF</div>
      <div class="bloc-marque-txt">
        <span class="republique">République Française</span>
        <span class="ministere">Ministère des Armées<br>Direction Générale de l'Armement</span>
        <span class="direction">Cellule de veille spatiale · Météo spatiale</span>
      </div>
    </div>
    <div class="bloc-devise">
      <em>Liberté</em>
      <em>Égalité</em>
      <em>Fraternité</em>
      <div class="ref-legale">Système SPACEWATCH · v1.0 · NOAA SWPC</div>
    </div>
  </div>
</div>

<div class="main-container">

  <div class="header">
    <h1>🛰️ SPACEWATCH · CELLULE DE VEILLE SPATIALE</h1>
    <p>Surveillance météo spatiale · Vent solaire · Champ magnétique · Temps réel</p>
  </div>

  <div class="controls">
    <label>Affichage :</label>
    <button id="btn-kpi" class="active">📊 KPI</button>
    <button id="btn-charts" class="active">📈 GRAPHIQUES</button>
    <button id="btn-map" class="active">🗺️ CARTE</button>
    <button id="btn-forecast" class="active">🔮 PRÉVISION</button>
    <button id="btn-refresh">⟳ RAFRAÎCHIR</button>
    <button id="btn-auto" class="btn-vert">🔄 AUTO 5s</button>
  </div>

  <div class="stats-bar">
    <div class="stat">
      <div class="stat-label">Dernière MAJ</div>
      <div class="stat-value utc" id="stat-maj">—</div>
    </div>
    <div class="stat">
      <div class="stat-label">Fichiers</div>
      <div class="stat-value" id="stat-files">—</div>
    </div>
    <div class="stat">
      <div class="stat-label">Alertes</div>
      <div class="stat-value mil" id="stat-alerts">—</div>
    </div>
    <div class="stat">
      <div class="stat-label">Régions actives</div>
      <div class="stat-value" id="stat-regions">—</div>
    </div>
    <div class="stat">
      <div class="stat-label">Temps UTC</div>
      <div class="stat-value utc" id="stat-utc">—</div>
    </div>
  </div>

  <section class="kpi-grid" id="section-kpi">
    <div class="kpi bleu">
      <div class="kpi-label">Kp</div>
      <div class="kpi-value" id="kpi-kp">—</div>
      <div class="kpi-sub" id="kpi-kp-time">—</div>
    </div>
    <div class="kpi blanc">
      <div class="kpi-label">X-ray</div>
      <div class="kpi-value" id="kpi-xray">—</div>
      <div class="kpi-sub" id="kpi-xray-class">—</div>
    </div>
    <div class="kpi rouge">
      <div class="kpi-label">Dst</div>
      <div class="kpi-value" id="kpi-dst">—</div>
      <div class="kpi-sub">nT</div>
    </div>
    <div class="kpi bleu">
      <div class="kpi-label">Vent</div>
      <div class="kpi-value" id="kpi-wind">—</div>
      <div class="kpi-sub">km/s</div>
    </div>
    <div class="kpi blanc">
      <div class="kpi-label">Densité</div>
      <div class="kpi-value" id="kpi-density">—</div>
      <div class="kpi-sub">p/cc</div>
    </div>
    <div class="kpi rouge">
      <div class="kpi-label">Bz</div>
      <div class="kpi-value" id="kpi-bz">—</div>
      <div class="kpi-sub">nT</div>
    </div>
  </section>

  <section class="chart-section" id="section-charts">
    <div class="chart-card" id="chart-kp"></div>
    <div class="chart-card" id="chart-xray"></div>
    <div class="chart-card" id="chart-dst"></div>
    <div class="chart-card" id="chart-wind"></div>
    <div class="chart-card" id="chart-bz"></div>
    <div class="chart-card" id="chart-forecast"></div>
  </section>

  <section class="map-container" id="section-map">
    <div id="map"></div>
    <div class="map-overlay">
      <div class="titre">🇫🇷 SITUATION SPATIALE</div>
      <div class="row"><span class="label">Kp</span><span class="value" id="ov-kp">—</span></div>
      <div class="row"><span class="label">X-ray</span><span class="value" id="ov-xray">—</span></div>
      <div class="row"><span class="label">Dst</span><span class="value" id="ov-dst">—</span></div>
      <div class="row"><span class="label">Vent</span><span class="value" id="ov-wind">—</span></div>
      <div class="row"><span class="label">Bz</span><span class="value" id="ov-bz">—</span></div>
    </div>
  </section>

  <section class="forecast-section" id="section-forecast">
    <h2>Prévision Kp 3 jours</h2>
    <div id="forecast-bars" class="forecast-bars"></div>
  </section>

</div>

<footer class="footer-officiel">
  <div class="devise-footer">Liberté · Égalité · Fraternité</div>
  <div>République Française — Ministère des Armées</div>
  <div class="mention-legale">
    Cellule de veille spatiale · Surveillance météo spatiale NOAA SWPC<br>
    Sources : NOAA SWPC · OMNI · Plotly · Leaflet · OpenStreetMap<br>
    Traitement : Python · watch mode · Export CSV
  </div>
  <div class="copyright-footer">
    © <span id="copyrightYear">2026</span> · <span class="sig">SPACEWATCH</span> · Tous droits réservés
  </div>
</footer>

<script src="app.js"></script>
</body>
</html>
HTML
ok "index.html"

# =====================================================================
# 6. STYLE.CSS — MARIANNE
# =====================================================================
log "Génération style.css..."
cat > "$DASHBOARD_DIR/style.css" <<'CSS'
:root {
  --bleu-france: #000091;
  --bleu-clair: #1212ff;
  --bleu-pale: #e3e3fd;
  --blanc: #ffffff;
  --rouge-marianne: #E1000F;
  --rouge-pale: #ffe9e9;
  --gris-fond: #f6f6f6;
  --gris-carte: #eeeeee;
  --gris-bordure: #e5e5e5;
  --gris-texte: #3a3a3a;
  --gris-leger: #929292;
  --noir: #1e1e1e;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: 'Marianne', 'Segoe UI', system-ui, sans-serif;
  background: var(--gris-fond);
  color: var(--noir);
  padding: 0 0 16px;
  min-height: 100vh;
}
.tricolore { position: fixed; top: 0; left: 0; right: 0; height: 4px; display: flex; z-index: 1000; }
.tricolore span { flex: 1; }
.tricolore .t-bleu { background: var(--bleu-france); }
.tricolore .t-blanc { background: var(--blanc); }
.tricolore .t-rouge { background: var(--rouge-marianne); }

.bandeau-etat { background: var(--blanc); border-bottom: 2px solid var(--bleu-france); position: relative; margin-bottom: 20px; }
.bandeau-etat::before {
  content: ''; position: absolute; top: 0; left: 0; right: 0; height: 4px;
  background: linear-gradient(to right, var(--bleu-france) 0 33.33%, var(--blanc) 33.33% 66.66%, var(--rouge-marianne) 66.66% 100%);
}
.bandeau-etat-content { max-width: 1400px; margin: 0 auto; display: flex; align-items: center; gap: 16px; padding: 16px 20px; }
.bloc-marianne { display: flex; align-items: center; gap: 14px; padding: 10px 18px; background: var(--blanc); border-left: 4px solid var(--bleu-france); border-right: 4px solid var(--rouge-marianne); flex-shrink: 0; }
.marianne-sceau { width: 56px; height: 56px; border-radius: 50%; background: radial-gradient(circle at 30% 30%, var(--bleu-clair), var(--bleu-france)); color: var(--blanc); display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 17px; border: 3px solid var(--blanc); box-shadow: 0 0 0 2px var(--bleu-france), 0 4px 12px rgba(0,0,145,.25); letter-spacing: .5px; position: relative; }
.marianne-sceau::after { content: ''; position: absolute; inset: -6px; border-radius: 50%; border: 1px dashed rgba(0,0,145,.3); }
.bloc-marque-txt { font-size: 11px; color: var(--gris-texte); line-height: 1.4; }
.bloc-marque-txt .republique { display: block; font-weight: 800; color: var(--bleu-france); font-size: 16px; letter-spacing: .5px; text-transform: uppercase; }
.bloc-marque-txt .ministere { display: block; font-size: 10px; color: var(--gris-texte); margin-top: 2px; }
.bloc-marque-txt .direction { display: block; font-size: 9px; color: var(--gris-leger); margin-top: 2px; text-transform: uppercase; letter-spacing: 1px; }
.bloc-devise { margin-left: auto; text-align: right; font-size: 11px; color: var(--bleu-france); letter-spacing: 3px; text-transform: uppercase; font-weight: 700; line-height: 1.6; }
.bloc-devise em { display: block; font-style: normal; }
.bloc-devise .ref-legale { font-family: monospace; font-size: 8px; color: var(--gris-leger); letter-spacing: .5px; margin-top: 4px; font-weight: 400; text-transform: none; }

.main-container { max-width: 1400px; margin: 0 auto; padding: 0 16px; }
.header { text-align: center; padding: 28px 20px; margin-bottom: 20px; background: linear-gradient(135deg, var(--blanc), #f0f3ff); border-radius: 16px; border: 1px solid var(--gris-bordure); position: relative; overflow: hidden; }
.header::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 6px; background: linear-gradient(90deg, var(--bleu-france) 0 33.33%, var(--blanc) 33.33% 66.66%, var(--rouge-marianne) 66.66% 100%); }
.header h1 { font-size: 2rem; font-weight: 700; letter-spacing: 1.5px; background: linear-gradient(90deg, var(--bleu-france), var(--bleu-clair), var(--rouge-marianne)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.header p { color: var(--gris-texte); font-size: 0.95rem; margin-top: 8px; }

.controls { background: var(--blanc); border: 1px solid var(--gris-bordure); border-radius: 12px; padding: 14px 18px; margin-bottom: 16px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center; box-shadow: 0 2px 8px rgba(0,0,145,.04); }
.controls label { color: var(--gris-leger); font-size: 0.65rem; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 700; }
.controls button { background: var(--blanc); border: 1px solid var(--gris-bordure); color: var(--gris-texte); padding: 8px 14px; font-family: inherit; font-size: 12px; font-weight: 600; cursor: pointer; border-radius: 20px; letter-spacing: .5px; transition: all 0.2s; }
.controls button:hover { border-color: var(--bleu-france); color: var(--bleu-france); background: var(--bleu-pale); }
.controls button.active { background: var(--bleu-france); color: var(--blanc); border-color: var(--bleu-france); }
.controls button.btn-vert { border-color: #16a34a; color: #16a34a; }
.controls button.btn-vert:hover { background: #dcfce7; }
.controls button.btn-vert.active { background: #16a34a; color: var(--blanc); border-color: #16a34a; }

.stats-bar { background: var(--blanc); border: 1px solid var(--gris-bordure); border-radius: 12px; padding: 14px 20px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 20px; border-top: 3px solid var(--bleu-france); }
.stat { display: flex; flex-direction: column; gap: 2px; }
.stat-label { color: var(--gris-leger); font-size: 0.6rem; letter-spacing: 1.5px; text-transform: uppercase; font-weight: 700; }
.stat-value { color: var(--bleu-france); font-size: 20px; font-weight: 800; letter-spacing: 1px; }
.stat-value.mil { color: var(--rouge-marianne); }
.stat-value.sat { color: #d97706; }
.stat-value.utc { color: var(--gris-texte); font-size: 16px; }

.kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 20px; }
.kpi { padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,145,.08); display: flex; flex-direction: column; gap: 6px; transition: transform 0.2s, box-shadow 0.2s; border-top: 4px solid transparent; }
.kpi:hover { transform: translateY(-4px); box-shadow: 0 8px 28px rgba(0,0,145,.2); }
.kpi.bleu { background: linear-gradient(135deg, var(--bleu-france), var(--bleu-clair)); color: var(--blanc); border-top-color: var(--bleu-france); }
.kpi.blanc { background: var(--blanc); color: var(--noir); border-top-color: var(--bleu-france); }
.kpi.rouge { background: linear-gradient(135deg, var(--rouge-marianne), #ff4d5e); color: var(--blanc); border-top-color: var(--rouge-marianne); }
.kpi-label { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 700; opacity: 0.9; }
.kpi-value { font-size: 2rem; font-weight: 800; line-height: 1.1; }
.kpi-sub { font-size: 0.8rem; opacity: 0.75; }

.chart-section { display: grid; grid-template-columns: repeat(auto-fit, minmax(420px, 1fr)); gap: 20px; margin-bottom: 20px; }
.chart-card { background: var(--blanc); border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,145,.08); padding: 12px; min-height: 280px; border-left: 4px solid var(--bleu-france); }
.chart-card:nth-child(even) { border-left-color: var(--rouge-marianne); }

.map-container { border: 2px solid var(--bleu-france); border-radius: 16px; background: var(--blanc); margin-bottom: 20px; position: relative; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,145,.08); }
.map-container::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 4px; background: linear-gradient(90deg, var(--bleu-france) 0 33.33%, var(--blanc) 33.33% 66.66%, var(--rouge-marianne) 66.66% 100%); z-index: 500; }
#map { width: 100%; height: 480px; background: var(--gris-carte); }
.map-overlay { position: absolute; top: 14px; right: 14px; background: rgba(255,255,255,0.96); border: 1px solid var(--bleu-france); border-radius: 10px; padding: 12px 16px; font-size: 11px; z-index: 1000; pointer-events: none; box-shadow: 0 4px 12px rgba(0,0,145,.15); min-width: 200px; }
.map-overlay .row { display: flex; justify-content: space-between; gap: 16px; margin-bottom: 5px; }
.map-overlay .label { color: var(--gris-leger); font-size: 10px; text-transform: uppercase; letter-spacing: 1px; font-weight: 700; }
.map-overlay .value { color: var(--bleu-france); font-weight: 800; font-size: 12px; }
.map-overlay .titre { color: var(--bleu-france); font-weight: 800; font-size: 10px; letter-spacing: 2px; text-transform: uppercase; padding-bottom: 6px; margin-bottom: 6px; border-bottom: 1px solid var(--gris-bordure); text-align: center; }

.forecast-section { background: var(--blanc); border-radius: 12px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,145,.08); margin-bottom: 20px; border-top: 3px solid var(--rouge-marianne); }
.forecast-section h2 { color: var(--bleu-france); font-size: 1.4rem; margin-bottom: 16px; padding-bottom: 8px; border-bottom: 3px solid var(--rouge-marianne); display: inline-block; }
.forecast-bars { display: flex; flex-direction: column; gap: 8px; }
.forecast-row { display: grid; grid-template-columns: 160px 80px 60px 1fr; align-items: center; gap: 12px; padding: 8px 12px; background: var(--gris-fond); border-radius: 8px; }
.forecast-time { font-size: 0.85rem; color: var(--gris-texte); font-weight: 600; }
.forecast-kp { font-weight: 800; font-size: 1rem; color: var(--bleu-france); }
.forecast-scale { font-size: 0.75rem; font-weight: 700; padding: 2px 8px; border-radius: 4px; text-align: center; }
.forecast-scale.g1 { background: #ffd580; color: #7a4a00; }
.forecast-scale.g2 { background: #ff8c66; color: #7a1c00; }
.forecast-scale.g3 { background: var(--rouge-marianne); color: var(--blanc); }
.forecast-bar-wrap { background: var(--gris-bordure); border-radius: 4px; height: 20px; overflow: hidden; }
.forecast-bar { height: 100%; background: linear-gradient(90deg, var(--bleu-france), var(--rouge-marianne)); border-radius: 4px; transition: width 0.6s ease-out; }

.footer-officiel { background: var(--blanc); border-top: 2px solid var(--bleu-france); padding: 28px 20px 20px; text-align: center; color: var(--gris-texte); font-size: 12px; margin-top: 40px; position: relative; }
.footer-officiel::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 4px; background: linear-gradient(to right, var(--bleu-france) 0 33.33%, var(--blanc) 33.33% 66.66%, var(--rouge-marianne) 66.66% 100%); }
.footer-officiel .devise-footer { font-size: 14px; color: var(--bleu-france); letter-spacing: 5px; text-transform: uppercase; font-weight: 800; margin-bottom: 12px; }
.footer-officiel .mention-legale { color: var(--gris-leger); font-size: 10px; font-family: monospace; letter-spacing: .5px; margin-top: 10px; line-height: 1.7; }
.footer-officiel .copyright-footer { margin-top: 14px; font-family: monospace; font-size: 10px; color: var(--gris-leger); }
.footer-officiel .copyright-footer .sig { font-weight: 800; letter-spacing: 2px; background: linear-gradient(90deg, var(--bleu-france), var(--rouge-marianne)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }

.live-dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; background: var(--rouge-marianne); margin-right: 6px; animation: pulse 1.5s infinite; }
@keyframes pulse { 0%,100%{opacity:1;transform:scale(1);} 50%{opacity:0.4;transform:scale(1.3);} }

::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: var(--gris-fond); }
::-webkit-scrollbar-thumb { background: var(--gris-bordure); border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: var(--bleu-france); }

@media (max-width: 700px) {
  .bandeau-etat-content { flex-direction: column; gap: 12px; padding: 12px; }
  .bloc-devise { margin-left: 0; text-align: center; }
  .bloc-devise em { display: inline; margin: 0 6px; }
  .header h1 { font-size: 1.3rem; }
  .chart-section { grid-template-columns: 1fr; }
  .controls button { width: 100%; }
  #map { height: 350px; }
  .stats-bar { flex-direction: column; align-items: flex-start; gap: 12px; }
}
CSS
ok "style.css"

# =====================================================================
# 7. APP.JS
# =====================================================================
log "Génération app.js..."
cat > "$DASHBOARD_DIR/app.js" <<'JS'
'use strict';

const DATA_URL = "data.json";
const REFRESH_MS = 5000;
const COLORS = { bleu: "#000091", bleuClair: "#6a6af4", rouge: "#E1000F", blanc: "#ffffff", gris: "#f6f6f6", texte: "#1e1e1e" };
const PLOT_CONFIG = { responsive: true, displayModeBar: false };
const PLOT_LAYOUT_BASE = {
  margin: { t: 40, r: 20, b: 40, l: 50 },
  paper_bgcolor: COLORS.blanc,
  plot_bgcolor: COLORS.blanc,
  font: { family: "Marianne, Segoe UI, sans-serif", color: COLORS.texte, size: 11 },
  xaxis: { gridcolor: "#e5e5f0", zeroline: false },
  yaxis: { gridcolor: "#e5e5f0", zeroline: false },
};

const state = {
  data: null,
  autoRefresh: true,
  timer: null,
};

function fmt(v, d=2) {
  if (v === null || v === undefined) return "—";
  if (typeof v === "number") {
    if (Math.abs(v) >= 1e5) return v.toExponential(2);
    if (Math.abs(v) < 1e-4 && v !== 0) return v.toExponential(2);
    return v.toFixed(d);
  }
  return v;
}

function xrayClass(f) {
  if (f === null || f === undefined) return "—";
  if (f >= 1e-4) return "X";
  if (f >= 1e-5) return "M";
  if (f >= 1e-6) return "C";
  if (f >= 1e-7) return "B";
  return "A";
}

function kpColor(k) {
  if (k >= 6) return COLORS.rouge;
  if (k >= 5) return "#ff8c66";
  if (k >= 4) return "#ffd580";
  return COLORS.bleuClair;
}

function timeSince(iso) {
  if (!iso) return "—";
  const d = new Date(iso), now = new Date(), diff = (now - d) / 1000;
  if (diff < 60) return `il y a ${Math.floor(diff)}s`;
  if (diff < 3600) return `il y a ${Math.floor(diff / 60)}min`;
  if (diff < 86400) return `il y a ${Math.floor(diff / 3600)}h`;
  return d.toLocaleString("fr-FR");
}

function renderKPI(d) {
  const rt = d.realtime || {}, om = d.omni || {};
  document.getElementById("kpi-kp").textContent = fmt(rt.kp);
  document.getElementById("kpi-kp-time").textContent = rt.kp_time || "—";
  document.getElementById("kpi-xray").textContent = fmt(rt.xray);
  document.getElementById("kpi-xray-class").textContent = `Classe ${xrayClass(rt.xray)}`;
  document.getElementById("kpi-dst").textContent = fmt(om.dst, 1);
  document.getElementById("kpi-wind").textContent = fmt(rt.wind_speed, 1);
  document.getElementById("kpi-density").textContent = fmt(rt.wind_density, 2);
  document.getElementById("kpi-bz").textContent = fmt(rt.bz, 2);

  document.getElementById("stat-maj").textContent = timeSince(d.generated_at);
  document.getElementById("stat-files").textContent = d.files_count;
  document.getElementById("stat-alerts").textContent = d.alerts_count;
  document.getElementById("stat-regions").textContent = d.regions_count;

  document.getElementById("ov-kp").textContent = fmt(rt.kp);
  document.getElementById("ov-xray").textContent = xrayClass(rt.xray);
  document.getElementById("ov-dst").textContent = fmt(om.dst, 1);
  document.getElementById("ov-wind").textContent = fmt(rt.wind_speed, 1);
  document.getElementById("ov-bz").textContent = fmt(rt.bz, 2);
}

function plotLine(id, x, y, name, color, yTitle, logy=false) {
  const trace = { x, y, type: "scatter", mode: "lines+markers", name, line: { color, width: 2 }, marker: { color, size: 4 } };
  const layout = { ...PLOT_LAYOUT_BASE, title: { text: name, font: { size: 13, color: COLORS.bleu } }, yaxis: { ...PLOT_LAYOUT_BASE.yaxis, title: yTitle, type: logy ? "log" : "linear" } };
  Plotly.react(id, [trace], layout, PLOT_CONFIG);
}

function plotForecast(id, fc) {
  const x = fc.map(v => v.time), y = fc.map(v => v.kp), colors = y.map(kpColor);
  const trace = { x, y, type: "bar", marker: { color: colors }, text: fc.map(v => v.scale || ""), textposition: "outside" };
  const layout = { ...PLOT_LAYOUT_BASE, title: { text: "Prévision Kp 3 jours", font: { size: 13, color: COLORS.bleu } }, yaxis: { ...PLOT_LAYOUT_BASE.yaxis, title: "Kp", range: [0, 7] },
    shapes: [
      { type: "line", y0: 5, y1: 5, x0: 0, x1: 1, xref: "paper", line: { color: "#ff8c66", width: 1, dash: "dot" } },
      { type: "line", y0: 6, y1: 6, x0: 0, x1: 1, xref: "paper", line: { color: COLORS.rouge, width: 1, dash: "dot" } }
    ] };
  Plotly.react(id, [trace], layout, PLOT_CONFIG);
}

function renderCharts(d) {
  const s = d.series || {}, t = s.time || [];
  plotLine("chart-kp", t, s.kp, "Kp", COLORS.bleu, "Kp");
  plotLine("chart-xray", t, s.xray, "X-ray", COLORS.rouge, "W/m²", true);
  plotLine("chart-dst", t, s.dst, "Dst", COLORS.bleu, "nT");
  plotLine("chart-wind", t, s.wind_speed, "Vent (km/s)", COLORS.rouge, "km/s");
  plotLine("chart-bz", t, s.bz, "Bz", COLORS.bleu, "nT");
  plotForecast("chart-forecast", (d.forecast && d.forecast.kp_3day) || []);
}

function renderForecastBars(d) {
  const c = document.getElementById("forecast-bars");
  const fc = ((d.forecast && d.forecast.kp_3day) || []).sort((a, b) => new Date(a.time) - new Date(b.time));
  c.innerHTML = "";
  fc.forEach(item => {
    const t = new Date(item.time);
    const ts = t.toLocaleString("fr-FR", { month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" });
    const sc = (item.scale || "").toLowerCase();
    const pct = Math.min(100, (item.kp / 7) * 100);
    const row = document.createElement("div");
    row.className = "forecast-row";
    row.innerHTML = `
      <span class="forecast-time">${ts}</span>
      <span class="forecast-kp">${item.kp.toFixed(2)}</span>
      <span class="forecast-scale ${sc}">${item.scale || "—"}</span>
      <div class="forecast-bar-wrap"><div class="forecast-bar" style="width:${pct}%"></div></div>`;
    c.appendChild(row);
  });
}

async function fetchData() {
  try {
    const r = await fetch(DATA_URL + "?t=" + Date.now());
    if (!r.ok) throw new Error("HTTP " + r.status);
    const d = await r.json();
    state.data = d;
    renderKPI(d);
    renderCharts(d);
    renderForecastBars(d);
    document.getElementById("stat-utc").textContent = new Date().toISOString().slice(11, 19);
  } catch (e) {
    console.error("fetch:", e);
  }
}

// =====================================================================
// MAP LEAFLET — centrée France / monde
// =====================================================================
let map = null;
function initMap() {
  map = L.map("map", { center: [46.6, 2.2], zoom: 4, zoomControl: true });
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "&copy; OpenStreetMap",
    maxZoom: 18,
  }).addTo(map);

  // Marqueur France
  L.marker([46.6, 2.2], {
    icon: L.divIcon({
      className: "obs-marker",
      html: '<div class="obs-dot"></div>',
      iconSize: [14, 14],
      iconAnchor: [7, 7],
    }),
  }).addTo(map).bindPopup("<b>France</b><br>Cellule de veille spatiale");

  // Cercles de couverture
  L.circle([46.6, 2.2], { radius: 2000 * 1000, color: "#000091", fillColor: "#000091", fillOpacity: 0.04, weight: 1.5, dashArray: "6,6" }).addTo(map);
  L.circle([46.6, 2.2], { radius: 5000 * 1000, color: "#E1000F", fillColor: "#E1000F", fillOpacity: 0.02, weight: 1, dashArray: "4,8" }).addTo(map);
}

// =====================================================================
// TOGGLES
// =====================================================================
function setupToggles() {
  const toggle = (btnId, sectionId) => {
    const btn = document.getElementById(btnId);
    const section = document.getElementById(sectionId);
    btn.addEventListener("click", () => {
      const active = btn.classList.toggle("active");
      section.style.display = active ? "" : "none";
    });
  };
  toggle("btn-kpi", "section-kpi");
  toggle("btn-charts", "section-charts");
  toggle("btn-map", "section-map");
  toggle("btn-forecast", "section-forecast");

  document.getElementById("btn-refresh").addEventListener("click", fetchData);

  const btnAuto = document.getElementById("btn-auto");
  btnAuto.addEventListener("click", () => {
    state.autoRefresh = !state.autoRefresh;
    btnAuto.classList.toggle("active", state.autoRefresh);
    btnAuto.textContent = state.autoRefresh ? "🔄 AUTO 5s" : "⏸️ AUTO OFF";
    if (state.autoRefresh) startAuto();
    else stopAuto();
  });
}

function startAuto() {
  if (state.timer) clearInterval(state.timer);
  state.timer = setInterval(fetchData, REFRESH_MS);
}

function stopAuto() {
  if (state.timer) clearInterval(state.timer);
  state.timer = null;
}

// =====================================================================
// DÉMARRAGE
// =====================================================================
document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("copyrightYear").textContent = new Date().getFullYear();
  initMap();
  setupToggles();
  fetchData();
  startAuto();
});
JS
ok "app.js"

# =====================================================================
# 8. GRAPH.PY
# =====================================================================
log "Génération graph.py..."
cat > "$BASE_DIR/graph.py" <<'PY'
#!/usr/bin/env python3
"""graph.py — spacewatch : data.json + plots + CSV."""
import json, glob, os, csv
from datetime import datetime, timezone
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
EXPORT_DIR = os.path.join(BASE_DIR, "export")
PLOT_DIR   = os.path.join(BASE_DIR, "plots")
DASH_DIR   = os.path.join(BASE_DIR, "dashboard")
CSV_FILE   = os.path.join(BASE_DIR, "spacewatch_series.csv")
STATE_FILE = os.path.join(BASE_DIR, ".watch_state.json")


def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, encoding="utf-8") as fh:
                return json.load(fh)
        except Exception:
            pass
    return {"seen": [], "last_run": None}


def save_state(state):
    with open(STATE_FILE, "w", encoding="utf-8") as fh:
        json.dump(state, fh, indent=2)


def load_files():
    files = sorted(glob.glob(os.path.join(EXPORT_DIR, "spacewatch_*.json")))
    data = []
    for f in files:
        n = os.path.basename(f)
        if n == "latest.json":
            continue
        try:
            with open(f, encoding="utf-8") as fh:
                o = json.load(fh)
            o["_file"] = n
            o["_dt"] = datetime.fromisoformat(o["generated_at"])
            data.append(o)
        except Exception as e:
            print(f"[!] {n}: {e}")
    data.sort(key=lambda x: x["_dt"])
    return data


def extract_series(data):
    s = {k: [] for k in ["time", "kp", "wind_speed", "wind_density", "wind_temp",
                          "bx", "by", "bz", "bt", "xray", "dst", "f107"]}
    for d in data:
        rt = d.get("realtime", {})
        om = d.get("omni_indices", {})
        s["time"].append(d["_dt"])
        s["kp"].append(rt.get("kp", {}).get("value"))
        s["wind_speed"].append(rt.get("wind", {}).get("speed"))
        s["wind_density"].append(rt.get("wind", {}).get("density"))
        s["wind_temp"].append(rt.get("wind", {}).get("temp"))
        s["bx"].append(rt.get("mag", {}).get("bx"))
        s["by"].append(rt.get("mag", {}).get("by"))
        s["bz"].append(rt.get("mag", {}).get("bz"))
        s["bt"].append(rt.get("mag", {}).get("bt"))
        s["xray"].append(rt.get("xray", {}).get("flux"))
        s["dst"].append(om.get("dst", {}).get("value"))
        s["f107"].append(om.get("f107", {}).get("value"))
    return s


def export_dashboard_json(data, series):
    os.makedirs(DASH_DIR, exist_ok=True)
    last = data[-1]
    rt = last.get("realtime", {})
    om = last.get("omni_indices", {})
    fc = last.get("forecast", {}).get("kp_3day", [])
    payload = {
        "generated_at": last.get("generated_at"),
        "files_count": len(data),
        "first_file": data[0]["_file"],
        "last_file": last["_file"],
        "realtime": {
            "kp": rt.get("kp", {}).get("value"),
            "kp_time": rt.get("kp", {}).get("time"),
            "wind_speed": rt.get("wind", {}).get("speed"),
            "wind_density": rt.get("wind", {}).get("density"),
            "wind_temp": rt.get("wind", {}).get("temp"),
            "bx": rt.get("mag", {}).get("bx"),
            "by": rt.get("mag", {}).get("by"),
            "bz": rt.get("mag", {}).get("bz"),
            "bt": rt.get("mag", {}).get("bt"),
            "xray": rt.get("xray", {}).get("flux"),
        },
        "omni": {"dst": om.get("dst", {}).get("value"), "f107": om.get("f107", {}).get("value")},
        "forecast": {"max_kp": last.get("forecast", {}).get("max_kp_forecast"), "kp_3day": fc},
        "alerts_count": len(last.get("alerts", [])),
        "regions_count": len(last.get("solar_regions", [])),
        "series": {
            "time": [t.isoformat() for t in series["time"]],
            "kp": series["kp"], "xray": series["xray"], "dst": series["dst"],
            "wind_speed": series["wind_speed"], "wind_density": series["wind_density"],
            "wind_temp": series["wind_temp"], "bz": series["bz"], "bt": series["bt"],
        },
    }
    with open(os.path.join(DASH_DIR, "data.json"), "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, ensure_ascii=False)
    print("[+] dashboard/data.json")


def run(verbose=True):
    data = load_files()
    if not data:
        if verbose: print("[!] Aucun fichier.")
        return 0, []
    state = load_state()
    seen = set(state.get("seen", []))
    current = {d["_file"] for d in data}
    new = sorted(current - seen)
    if verbose:
        print(f"[i] {len(data)} fichier(s)")
        if new:
            print(f"[+] {len(new)} nouveau(x): " + ", ".join(new))
    s = extract_series(data)
    export_dashboard_json(data, s)
    state["seen"] = sorted(current)
    state["last_run"] = datetime.now(timezone.utc).isoformat()
    save_state(state)
    if verbose: print("[✓] Terminé.")
    return len(data), new


if __name__ == "__main__":
    run()
PY
ok "graph.py"

# =====================================================================
# 9. WATCH.PY
# =====================================================================
log "Génération watch.py..."
cat > "$BASE_DIR/watch.py" <<'PY'
#!/usr/bin/env python3
"""watch.py — surveille export/ et relance graph.run()."""
import sys, time, importlib
from datetime import datetime
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
EXPORT_DIR = BASE_DIR / "export"


def scan():
    if not EXPORT_DIR.exists(): return []
    return sorted(f.name for f in EXPORT_DIR.glob("spacewatch_*.json") if f.name != "latest.json")


def run_graph():
    if "graph" in sys.modules:
        importlib.reload(sys.modules["graph"])
    else:
        sys.path.insert(0, str(BASE_DIR))
        importlib.import_module("graph")
    g = sys.modules["graph"]
    t0 = time.time()
    print(f"\n[{datetime.now():%H:%M:%S}] ▶ graph.run()")
    try:
        n, new = g.run(verbose=True)
        print(f"[{datetime.now():%H:%M:%S}] ✓ {time.time()-t0:.1f}s ({n} fichiers)")
    except Exception as e:
        print(f"[{datetime.now():%H:%M:%S}] ✗ {e}")


def main():
    interval = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    print(f"WATCH export/ (intervalle={interval}s) — Ctrl+C pour arrêter")
    run_graph()
    seen = set(scan())
    try:
        while True:
            cur = set(scan())
            new = sorted(cur - seen)
            if new:
                print(f"\n[{datetime.now():%H:%M:%S}] 🔔 " + ", ".join(new))
                run_graph()
                seen = cur
            else:
                sys.stdout.write("."); sys.stdout.flush()
            time.sleep(interval)
    except KeyboardInterrupt:
        print("\n[✓] Arrêt.")


if __name__ == "__main__":
    main()
PY
ok "watch.py"

# =====================================================================
# 10. GÉNÉRATION INITIALE
# =====================================================================
log "Génération initiale du dashboard..."
python "$BASE_DIR/graph.py"

# =====================================================================
# 11. SERVEUR HTTP
# =====================================================================
cd "$DASHBOARD_DIR"
python -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
HTTP_PID=$!
ok "Serveur HTTP : http://localhost:$PORT (PID $HTTP_PID)"

# =====================================================================
# 12. NAVIGATEUR
# =====================================================================
URL="http://localhost:$PORT"
sleep 1
if command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then open "$URL" >/dev/null 2>&1 &
fi
ok "Navigateur ouvert : $URL"

# =====================================================================
# 13. WATCH MODE
# =====================================================================
echo ""
echo -e "${BLEU}${GRAS}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BLEU}${GRAS}  DASHBOARD MARIANNE ACTIF — http://localhost:$PORT${RESET}"
echo -e "${BLEU}${GRAS}  Ctrl+C pour arrêter${RESET}"
echo -e "${BLEU}${GRAS}═══════════════════════════════════════════════════════════════${RESET}"
echo ""

cd "$BASE_DIR"
python watch.py "$INTERVAL" &
WATCH_PID=$!
wait "$WATCH_PID"