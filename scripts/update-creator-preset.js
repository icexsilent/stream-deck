// Snapshots the creator's current buttons (agent/buttons.json) into agent/presets/creator.json,
// which ships with every build as "Preset do Criador". Run: node scripts/update-creator-preset.js
const fs = require('node:fs');
const path = require('node:path');
const { validate } = require('../agent/config');

const agent = path.join(__dirname, '..', 'agent');
const outDir = path.join(agent, 'presets');
const iconOut = path.join(outDir, 'icons');

const cfg = validate(JSON.parse(fs.readFileSync(path.join(agent, 'buttons.json'), 'utf8')));
const version = /^version:\s*([\d.]+)/m.exec(fs.readFileSync(path.join(__dirname, '..', 'app', 'pubspec.yaml'), 'utf8'))[1];

// Game covers are regenerated on each PC by the game scan (and are the publishers' art), so only
// program icons and uploaded images travel with the preset.
fs.rmSync(iconOut, { recursive: true, force: true });
fs.mkdirSync(iconOut, { recursive: true });
const icons = new Set(cfg.pages.flatMap((p) => p.buttons.map((b) => b.icon)).filter((i) => i && !i.startsWith('game-')));
for (const icon of icons) {
  const src = path.join(agent, 'icons', icon);
  if (fs.existsSync(src)) fs.copyFileSync(src, path.join(iconOut, icon));
  else console.warn(`ícone não encontrado, botão vai sem imagem: ${icon}`);
}

// Paths under the creator's user folder become %APPDATA%-style variables, which cmd expands on each PC at launch.
const vars = ['LOCALAPPDATA', 'APPDATA', 'USERPROFILE'].filter((v) => process.env[v]);
for (const b of cfg.pages.flatMap((p) => p.buttons)) {
  if (b.type !== 'open') continue;
  for (const v of vars) {
    if (b.target.toLowerCase().startsWith(process.env[v].toLowerCase())) { b.target = `%${v}%${b.target.slice(process.env[v].length)}`; break; }
  }
}

const preset = {
  name: 'Preset do Criador',
  version,
  updatedAt: new Date().toISOString().slice(0, 10),
  config: { columns: cfg.columns, features: cfg.features, pages: cfg.pages, hiddenGames: cfg.hiddenGames ?? [] }, // never the OBS password
};
fs.writeFileSync(path.join(outDir, 'creator.json'), JSON.stringify(preset, null, 2) + '\n');
const count = cfg.pages.reduce((n, p) => n + p.buttons.length, 0);
console.log(`Preset do Criador atualizado: v${version}, ${cfg.pages.length} páginas, ${count} botões, ${icons.size} ícones.`);
