// Plugins: each folder in agent/plugins has a plugin.json (what the editor shows) and an index.js (what runs).
// Same idea as Goose extensions: new actions plug in without touching the agent.
const fs = require('node:fs');
const path = require('node:path');

const DIR = path.join(__dirname, 'plugins');
const ID = /^[a-z0-9-]{1,40}$/;
const FIELD_TYPES = ['text', 'textarea', 'number', 'select'];

const loaded = new Map(); // id -> { manifest, impl }

function checkManifest(m, folder) {
  if (!ID.test(m.id ?? '') || m.id !== folder) throw new Error(`"id" deve ser igual ao nome da pasta (${folder})`);
  if (typeof m.name !== 'string' || !m.name) throw new Error('falta "name"');
  if (!m.actions || typeof m.actions !== 'object') throw new Error('falta "actions"');
  for (const [aid, a] of Object.entries(m.actions)) {
    if (!ID.test(aid)) throw new Error(`ação com id inválido: ${aid}`);
    if (typeof a.label !== 'string') throw new Error(`ação ${aid} sem "label"`);
    for (const f of a.fields ?? []) {
      if (!/^\w{1,40}$/.test(f.key ?? '') || !FIELD_TYPES.includes(f.type)) throw new Error(`ação ${aid}: campo inválido ${JSON.stringify(f)}`);
      if (f.type === 'select' && !Array.isArray(f.options)) throw new Error(`ação ${aid}: campo ${f.key} sem "options"`);
    }
  }
}

/** Loads every plugin; a broken one is skipped with a message instead of stopping the agent. */
function loadAll() {
  loaded.clear();
  let folders = [];
  try { folders = fs.readdirSync(DIR, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name); } catch { return []; }
  const errors = [];
  for (const folder of folders) {
    try {
      const manifest = JSON.parse(fs.readFileSync(path.join(DIR, folder, 'plugin.json'), 'utf8'));
      checkManifest(manifest, folder);
      const impl = require(path.join(DIR, folder, 'index.js'));
      for (const aid of Object.keys(manifest.actions)) {
        if (typeof impl.actions?.[aid] !== 'function') throw new Error(`index.js não exporta actions.${aid}`);
      }
      loaded.set(manifest.id, { manifest, impl });
    } catch (e) {
      errors.push(`plugin "${folder}" ignorado: ${e.message}`);
    }
  }
  return errors;
}

/** What the editor and app need to build the form for each plugin action. */
const list = () => [...loaded.values()].map(({ manifest: m }) => ({ id: m.id, name: m.name, description: m.description ?? '', actions: m.actions }));

async function run(b, ctx) {
  const p = loaded.get(b.plugin);
  if (!p) throw new Error(`plugin "${b.plugin}" não está instalado neste PC`);
  const action = p.manifest.actions[b.action];
  if (!action) throw new Error(`o plugin "${p.manifest.name}" não tem a ação "${b.action}"`);
  const params = {};
  for (const f of action.fields ?? []) {
    const v = b.params?.[f.key] ?? f.default;
    if (f.required && (v === undefined || v === '')) throw new Error(`preencha "${f.label}" no botão`);
    params[f.key] = f.type === 'number' && v !== undefined ? Number(v) : v;
  }
  return p.impl.actions[b.action](params, ctx);
}

module.exports = { loadAll, list, run, DIR };
