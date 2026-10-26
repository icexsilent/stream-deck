const fs = require('node:fs');
const path = require('node:path');
const { toVks } = require('./keys');
const { KINDS: WIDGETS } = require('./widgets');

// SD_DATA_DIR lets tests use a temp folder instead of the real buttons.json.
const DATA = process.env.SD_DATA_DIR || __dirname;
const FILE = path.join(DATA, 'buttons.json');
const HISTORY = path.join(DATA, 'history');
const KEEP = 30;
// Read as "Antes de …" in the Histórico list.
const SOURCES = { pc: 'uma mudança no editor do PC', celular: 'uma mudança no celular', config: 'uma mudança nas Configurações', preset: 'aplicar o Preset do Criador', restaurar: 'uma restauração', ia: 'uma mudança do assistente de IA' };
const COLOR = /^#[0-9a-f]{6}$/i;
const OBS_ACTIONS = ['scene', 'toggleMute', 'toggleStream', 'toggleRecord'];
const ICON = /^[\w-]{1,80}\.(png|jpe?g|webp|gif)$/i;

// Pages added or removed as a whole by the switches in Configurações; `template` marks them so the switch finds them again.
const TEMPLATES = {
  obs: { name: 'OBS', buttons: [
    { id: 'obs-live', label: '🔴 Live on/off', type: 'obs', action: 'toggleStream', color: '#dc2626' },
    { id: 'obs-rec', label: '⏺️ Gravar on/off', type: 'obs', action: 'toggleRecord' },
    { id: 'obs-mic', label: '🎙️ Mic OBS', type: 'obs', action: 'toggleMute', name: 'Mic/Aux' },
    { id: 'obs-cena1', label: '🎬 Cena 1', type: 'obs', action: 'scene', name: 'Cena' },
  ] },
  widgets: { name: 'Widgets', buttons: [
    { id: 'w-clock', label: 'Relógio', type: 'widget', widget: 'clock' },
    { id: 'w-cpu', label: 'CPU', type: 'widget', widget: 'cpu' },
    { id: 'w-ram', label: 'RAM', type: 'widget', widget: 'ram' },
    { id: 'w-gpu', label: 'GPU', type: 'widget', widget: 'gpu' },
    { id: 'w-media', label: 'Música', type: 'widget', widget: 'media' },
    { id: 'w-volume', label: 'Volume', type: 'widget', widget: 'volume' },
    { id: 'w-timer', label: 'Timer 5 min', type: 'widget', widget: 'timer', minutes: 5 },
    { id: 'w-counter', label: 'Contador', type: 'widget', widget: 'counter' },
    { id: 'w-weather', label: 'Clima', type: 'widget', widget: 'weather', city: 'São Paulo' },
  ] },
};
const FEATURES = ['games', 'obs', 'widgets'];

// Throws a readable error on anything the phone or a hand edit could get wrong; the file is only written after this passes.
function validate(cfg) {
  if (!cfg || typeof cfg !== 'object') throw new Error('config inválida');
  if (cfg.buttons && !cfg.pages) cfg = { pages: [{ name: 'Principal', buttons: cfg.buttons }] }; // formato antigo (Fase 1)
  const columns = cfg.columns ?? 3;
  if (!Number.isInteger(columns) || columns < 1 || columns > 8) throw new Error('columns deve ser de 1 a 8');
  // Auto pages (Jogos) are rebuilt by the agent from the game scan, never stored.
  if (!Array.isArray(cfg.pages) || !cfg.pages.some((p) => !p?.auto)) throw new Error('precisa de pelo menos uma página sua');
  const ids = new Set();
  const pages = cfg.pages.filter((p) => !p.auto).map((p, pi) => {
    if (typeof p.name !== 'string' || !p.name.trim()) throw new Error(`página ${pi + 1} sem nome`);
    if (!Array.isArray(p.buttons)) throw new Error(`página "${p.name}" sem lista de botões`);
    return {
      name: p.name.trim(),
      ...(TEMPLATES[p.template] ? { template: p.template } : {}),
      buttons: p.buttons.map((b) => {
        const where = `botão "${b.label ?? b.id}" na página "${p.name}"`;
        if (typeof b.id !== 'string' || !/^[\w-]{1,40}$/.test(b.id)) throw new Error(`${where}: id inválido`);
        if (ids.has(b.id)) throw new Error(`${where}: id repetido "${b.id}"`);
        ids.add(b.id);
        if (typeof b.label !== 'string' || b.label.length > 40) throw new Error(`${where}: texto inválido (máx. 40)`);
        if (b.color !== undefined && !COLOR.test(b.color)) throw new Error(`${where}: cor deve ser #rrggbb`);
        const out = { id: b.id, label: b.label, type: b.type };
        if (b.color) out.color = b.color;
        if (b.icon !== undefined && b.icon !== null) {
          if (typeof b.icon !== 'string' || !ICON.test(b.icon)) throw new Error(`${where}: ícone inválido`);
          out.icon = b.icon;
        }
        if (b.type === 'hotkey') {
          if (typeof b.keys !== 'string' || !b.keys.trim()) throw new Error(`${where}: falta o atalho de teclado`);
          toVks(b.keys); out.keys = b.keys;
        }
        else if (b.type === 'open') {
          if (typeof b.target !== 'string' || !b.target.trim()) throw new Error(`${where}: falta o programa a abrir`);
          if (b.target.includes('"')) throw new Error(`${where}: o caminho não pode ter aspas`); // it is quoted for cmd at launch
          out.target = b.target.trim();
        } else if (b.type === 'obs') {
          if (!OBS_ACTIONS.includes(b.action)) throw new Error(`${where}: ação OBS deve ser ${OBS_ACTIONS.join(', ')}`);
          out.action = b.action;
          if (b.action === 'scene' || b.action === 'toggleMute') {
            if (typeof b.name !== 'string' || !b.name.trim()) throw new Error(`${where}: falta o nome da cena/fonte`);
            out.name = b.name.trim();
          }
        } else if (b.type === 'game' || b.type === 'page') {
          const v = b[b.type];
          if (typeof v !== 'string' || !v.trim()) throw new Error(`${where}: escolha ${b.type === 'game' ? 'o jogo' : 'a página'}`);
          out[b.type] = v;
        } else if (b.type === 'widget') {
          if (!WIDGETS[b.widget]) throw new Error(`${where}: widget deve ser ${Object.keys(WIDGETS).join(', ')}`);
          out.widget = b.widget;
          if (b.widget === 'timer') {
            const m = b.minutes ?? 5;
            if (!Number.isInteger(m) || m < 1 || m > 600) throw new Error(`${where}: minutos do cronômetro de 1 a 600`);
            out.minutes = m;
          }
          if (b.widget === 'weather') {
            if (typeof b.city !== 'string' || !b.city.trim() || b.city.length > 60) throw new Error(`${where}: escreva a cidade do clima`);
            out.city = b.city.trim();
          }
        } else if (b.type === 'plugin') {
          // Which plugins exist is checked at press time, so a button survives a plugin being removed and reinstalled.
          if (!/^[a-z0-9-]{1,40}$/.test(b.plugin ?? '') || !/^[a-z0-9-]{1,40}$/.test(b.action ?? '')) throw new Error(`${where}: escolha a ação do plugin`);
          const params = b.params ?? {};
          if (typeof params !== 'object' || Array.isArray(params) || Object.keys(params).length > 20) throw new Error(`${where}: parâmetros do plugin inválidos`);
          for (const [k, v] of Object.entries(params)) {
            if (!/^\w{1,40}$/.test(k) || !['string', 'number'].includes(typeof v) || String(v).length > 4000) throw new Error(`${where}: parâmetro "${k}" inválido`);
          }
          Object.assign(out, { plugin: b.plugin, action: b.action, params });
        } else throw new Error(`${where}: tipo deve ser hotkey, open, obs, game, page, widget ou plugin`);
        return out;
      }),
    };
  });
  const out = { columns, pages };
  if (cfg.features === undefined) {
    // Configs from before Configurações existed: keep what that user already had, and skip the first-run questions.
    const legacyObs = pages.find((p) => p.name === 'OBS' && p.buttons.some((b) => b.type === 'obs'));
    if (legacyObs) legacyObs.template = 'obs';
    out.features = { games: true, obs: Boolean(legacyObs), widgets: false };
    out.setupDone = true;
  } else {
    if (typeof cfg.features !== 'object' || cfg.features === null) throw new Error('features inválido');
    out.features = Object.fromEntries(FEATURES.map((f) => [f, cfg.features[f] === true]));
    out.setupDone = cfg.setupDone === true;
  }
  if (cfg.hiddenGames !== undefined) {
    if (!Array.isArray(cfg.hiddenGames) || cfg.hiddenGames.some((g) => typeof g !== 'string')) throw new Error('hiddenGames inválido');
    out.hiddenGames = [...new Set(cfg.hiddenGames)];
  }
  if (cfg.obs) {
    if (typeof cfg.obs.url !== 'string') throw new Error('obs.url inválido');
    out.obs = { url: cfg.obs.url, password: String(cfg.obs.password ?? '') };
  }
  return out;
}

/** Turns the Jogos tab and the template pages (OBS, Widgets) on or off; returns a new config. */
function applyFeatures(cfg, features) {
  const next = structuredClone(cfg);
  next.features = { ...cfg.features, ...Object.fromEntries(FEATURES.filter((f) => typeof features[f] === 'boolean').map((f) => [f, features[f]])) };
  next.setupDone = true;
  for (const [key, tpl] of Object.entries(TEMPLATES)) {
    const has = next.pages.some((p) => p.template === key);
    if (next.features[key] && !has) {
      const used = new Set(next.pages.flatMap((p) => p.buttons.map((b) => b.id)));
      const page = { ...structuredClone(tpl), template: key };
      for (const b of page.buttons) if (used.has(b.id)) b.id = `${b.id}-${Date.now().toString(36)}`;
      next.pages.push(page);
    } else if (!next.features[key] && has) {
      next.pages = next.pages.filter((p) => p.template !== key);
    }
  }
  if (!next.pages.length) next.pages = [{ name: 'Principal', buttons: [] }];
  return next;
}

function load() {
  // buttons.json is personal (OBS password, edits from the phone) and stays out of git; first run starts from the example.
  if (!fs.existsSync(FILE)) fs.copyFileSync(path.join(__dirname, 'buttons.example.json'), FILE);
  return validate(JSON.parse(fs.readFileSync(FILE, 'utf8')));
}

// Plandex-style safety net: before every change, the current file is copied to history/, so any change can be undone.
function snapshot(source) {
  if (!fs.existsSync(FILE)) return;
  fs.mkdirSync(HISTORY, { recursive: true });
  fs.copyFileSync(FILE, path.join(HISTORY, `${Date.now()}-${SOURCES[source] ? source : 'pc'}.json`));
  const old = fs.readdirSync(HISTORY).filter((f) => /^\d+-\w+\.json$/.test(f)).sort().reverse().slice(KEEP);
  for (const f of old) fs.rmSync(path.join(HISTORY, f), { force: true });
}

/** Newest first: { id, at, source, pages, buttons } — each entry is how things were before that change. */
function history() {
  let files = [];
  try { files = fs.readdirSync(HISTORY).filter((f) => /^\d+-\w+\.json$/.test(f)).sort().reverse(); } catch { return []; }
  return files.flatMap((f) => {
    try {
      const c = JSON.parse(fs.readFileSync(path.join(HISTORY, f), 'utf8'));
      const [at, source] = f.replace('.json', '').split('-');
      return [{ id: f.replace('.json', ''), at: Number(at), source: SOURCES[source] ?? source, pages: c.pages.length, buttons: c.pages.reduce((n, p) => n + p.buttons.length, 0) }];
    } catch { return []; }
  });
}

/** Puts an old version back (the current one goes to history too, so a restore can be undone). */
function restore(id) {
  if (!/^\d+-\w+$/.test(id ?? '')) throw new Error('versão inválida');
  const file = path.join(HISTORY, `${id}.json`);
  if (!fs.existsSync(file)) throw new Error('essa versão não existe mais');
  return save(JSON.parse(fs.readFileSync(file, 'utf8')), 'restaurar');
}

/** Steps back one change per call: uses the newest snapshot that isn't a restore, then drops it so the next undo goes further back. */
function undo() {
  const entry = history().find((h) => !h.id.endsWith('-restaurar'));
  if (!entry) throw new Error('nada para desfazer');
  const restored = restore(entry.id);
  fs.rmSync(path.join(HISTORY, `${entry.id}.json`), { force: true });
  return restored;
}

function save(cfg, source = 'pc') {
  const clean = validate(cfg);
  snapshot(source);
  fs.writeFileSync(FILE + '.tmp', JSON.stringify(clean, null, 2) + '\n');
  fs.renameSync(FILE + '.tmp', FILE); // atomic swap so a crash never leaves a half-written config
  return clean;
}

module.exports = { validate, load, save, applyFeatures, FEATURES, history, restore, undo };
