// Finds installed games from Steam, Epic, Riot and Xbox, with cover art or icon copied into agent/icons.
const fs = require('node:fs');
const path = require('node:path');
const { execFile } = require('node:child_process');
const { promisify } = require('node:util');
const run = promisify(execFile);

const ICONS = path.join(__dirname, 'icons');
const STEAM_SKIP = new Set(['228980']); // Steamworks Common Redistributables
const RIOT_NAMES = { league_of_legends: 'League of Legends', valorant: 'VALORANT', bacon: 'Legends of Runeterra', lion: '2XKO' };
const RIOT_EXE = { league_of_legends: 'LeagueClient.exe', valorant: 'live/VALORANT.exe' };

const exists = (p) => { try { fs.accessSync(p); return true; } catch { return false; } };
const read = (p) => fs.readFileSync(p, 'utf8');

function parseVdfPaths(text) {
  return [...text.matchAll(/"path"\s+"([^"]+)"/g)].map((m) => m[1].replace(/\\\\/g, '\\'));
}

function parseAcf(text) {
  const get = (k) => new RegExp(`"${k}"\\s+"([^"]*)"`).exec(text)?.[1];
  return { appid: get('appid'), name: get('name'), stateFlags: Number(get('StateFlags') ?? 0) };
}

async function steamRoot() {
  try {
    const { stdout } = await run('reg', ['query', 'HKCU\\Software\\Valve\\Steam', '/v', 'SteamPath']);
    return /SteamPath\s+REG_SZ\s+(.+)/.exec(stdout)?.[1].trim().replace(/\//g, '\\');
  } catch {
    return null;
  }
}

function steamCover(root, id) {
  const dir = path.join(root, 'appcache', 'librarycache', id);
  const direct = [path.join(dir, 'library_600x900.jpg'), path.join(root, 'appcache', 'librarycache', `${id}_library_600x900.jpg`)].find(exists);
  if (direct) return direct;
  // Newer Steam keeps art in hash-named subfolders; portrait capsules first since tiles crop to a square.
  try {
    const subs = fs.readdirSync(dir);
    for (const f of ['library_capsule.jpg', 'library_600x900.jpg', 'library_header.jpg', 'header.jpg']) {
      for (const sub of subs) if (exists(path.join(dir, sub, f))) return path.join(dir, sub, f);
    }
  } catch {}
  return null;
}

async function scanSteam() {
  const root = await steamRoot();
  if (!root || !exists(path.join(root, 'steamapps', 'libraryfolders.vdf'))) return [];
  const games = [];
  for (const lib of parseVdfPaths(read(path.join(root, 'steamapps', 'libraryfolders.vdf')))) {
    let files = [];
    try { files = fs.readdirSync(path.join(lib, 'steamapps')).filter((f) => /^appmanifest_\d+\.acf$/.test(f)); } catch {}
    for (const f of files) {
      const a = parseAcf(read(path.join(lib, 'steamapps', f)));
      // StateFlags bit 4 = fully installed; skips half-downloaded games and Steam's own redistributables.
      if (!a.appid || !a.name || !(a.stateFlags & 4) || STEAM_SKIP.has(a.appid) || /redistributable|steamvr|proton/i.test(a.name)) continue;
      games.push({ id: `steam-${a.appid}`, label: a.name, source: 'Steam', launch: { uri: `steam://rungameid/${a.appid}` }, art: steamCover(root, a.appid) });
    }
  }
  return games;
}

function scanEpic(dir = 'C:\\ProgramData\\Epic\\EpicGamesLauncher\\Data\\Manifests') {
  let files = [];
  try { files = fs.readdirSync(dir).filter((f) => f.endsWith('.item')); } catch { return []; }
  const games = [];
  for (const f of files) {
    try {
      const j = JSON.parse(read(path.join(dir, f)));
      if (j.bIsIncompleteInstall || !j.DisplayName || !j.AppName) continue;
      const app = encodeURIComponent(`${j.CatalogNamespace}:${j.CatalogItemId}:${j.AppName}`);
      games.push({
        id: `epic-${j.AppName}`,
        label: j.DisplayName,
        source: 'Epic',
        launch: { uri: `com.epicgames.launcher://apps/${app}?action=launch&silent=true` },
        exe: j.LaunchExecutable ? path.join(j.InstallLocation, j.LaunchExecutable) : null,
      });
    } catch {}
  }
  return games;
}

function scanRiot(root = 'C:\\ProgramData\\Riot Games') {
  let client, dirs = [];
  try {
    client = JSON.parse(read(path.join(root, 'RiotClientInstalls.json'))).rc_default;
    dirs = fs.readdirSync(path.join(root, 'Metadata')).filter((d) => /^\w+\.live$/.test(d));
  } catch { return []; }
  const games = [];
  for (const d of dirs) {
    const product = d.replace(/\.live$/, '');
    let install;
    try { install = /product_install_full_path:\s*"([^"]+)"/.exec(read(path.join(root, 'Metadata', d, `${d}.product_settings.yaml`)))?.[1]; } catch {}
    if (!install || !exists(install) || !RIOT_NAMES[product]) continue;
    games.push({
      id: `riot-${product}`,
      label: RIOT_NAMES[product],
      source: 'Riot',
      launch: { exe: client, args: [`--launch-product=${product}`, '--launch-patchline=live'] },
      exe: RIOT_EXE[product] ? path.join(install, RIOT_EXE[product]) : client,
    });
  }
  return games;
}

async function scanXbox(root = 'C:\\XboxGames') {
  let dirs = [];
  try { dirs = fs.readdirSync(root).filter((d) => !['GameSave', 'Shaders'].includes(d)); } catch { return []; }
  if (!dirs.length) return [];
  let apps = [];
  try {
    const { stdout } = await run('powershell', ['-NoProfile', '-Command', 'Get-StartApps | ConvertTo-Json -Compress'], { maxBuffer: 8 << 20 });
    apps = [].concat(JSON.parse(stdout));
  } catch { return []; }
  return dirs.flatMap((d) => {
    const app = apps.find((a) => a.Name === d) ?? apps.find((a) => a.Name?.startsWith(d));
    return app ? [{ id: `xbox-${d.replace(/\W+/g, '-')}`, label: d, source: 'Xbox', launch: { uri: `shell:AppsFolder\\${app.AppID}` } }] : [];
  });
}

// Copies Steam covers and extracts exe icons (one PowerShell call for all) into agent/icons, skipping ones already there.
async function collectArt(games) {
  fs.mkdirSync(ICONS, { recursive: true });
  const toExtract = [];
  for (const g of games) {
    const cover = path.join(ICONS, `game-${g.id}.jpg`);
    const icon = path.join(ICONS, `game-${g.id}.png`);
    if (g.art) {
      if (!exists(cover)) fs.copyFileSync(g.art, cover);
      g.icon = path.basename(cover);
    } else if (g.exe && exists(g.exe)) {
      if (!exists(icon)) toExtract.push([g.exe, icon]);
      g.icon = path.basename(icon);
    }
  }
  if (toExtract.length) {
    const lines = toExtract.map(([exe, out]) => `try { [Drawing.Icon]::ExtractAssociatedIcon('${exe.replace(/'/g, "''")}').ToBitmap().Save('${out.replace(/'/g, "''")}') } catch {}`);
    await run('powershell', ['-NoProfile', '-Command', `Add-Type -AssemblyName System.Drawing; ${lines.join('; ')}`]).catch(() => {});
    for (const g of games) if (g.icon && !exists(path.join(ICONS, g.icon))) delete g.icon;
  }
  return games;
}

async function scanAll() {
  const lists = await Promise.all([scanSteam(), scanEpic(), scanRiot(), scanXbox()].map((p) => Promise.resolve(p).catch(() => [])));
  const games = await collectArt(lists.flat());
  return games.sort((a, b) => a.label.localeCompare(b.label, 'pt-BR')).map(({ id, label, source, launch, icon }) => ({ id, label, source, launch, icon }));
}

module.exports = { scanAll, parseVdfPaths, parseAcf, scanEpic, scanRiot, ICONS };
