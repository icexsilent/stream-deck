const fs = require('node:fs');
const path = require('node:path');
const { toVks } = require('./keys');

const FILE = path.join(__dirname, 'buttons.json');
const COLOR = /^#[0-9a-f]{6}$/i;
const OBS_ACTIONS = ['scene', 'toggleMute', 'toggleStream', 'toggleRecord'];
const ICON = /^[\w-]{1,80}\.(png|jpe?g|webp|gif)$/i;

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
        } else throw new Error(`${where}: tipo deve ser hotkey, open, obs, game ou page`);
        return out;
      }),
    };
  });
  const out = { columns, pages };
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

function load() {
  // buttons.json is personal (OBS password, edits from the phone) and stays out of git; first run starts from the example.
  if (!fs.existsSync(FILE)) fs.copyFileSync(path.join(__dirname, 'buttons.example.json'), FILE);
  return validate(JSON.parse(fs.readFileSync(FILE, 'utf8')));
}

function save(cfg) {
  const clean = validate(cfg);
  fs.writeFileSync(FILE + '.tmp', JSON.stringify(clean, null, 2) + '\n');
  fs.renameSync(FILE + '.tmp', FILE); // atomic swap so a crash never leaves a half-written config
  return clean;
}

module.exports = { validate, load, save };
