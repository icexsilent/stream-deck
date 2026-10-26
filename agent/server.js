const http = require('node:http');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const QRCode = require('qrcode');
const { Bonjour } = require('bonjour-service');
const { WebSocketServer } = require('ws');
const config = require('./config');
const { run } = require('./actions');
const { scanAll, ICONS } = require('./games');
const { pickApp } = require('./apps');
const widgets = require('./widgets');
const plugins = require('./plugins');
for (const err of plugins.loadAll()) console.warn(err);

const PORT = Number(process.env.PORT) || 3000;
const PRESET_DIR = path.join(__dirname, 'presets');

function creatorPreset() {
  try { return JSON.parse(fs.readFileSync(path.join(PRESET_DIR, 'creator.json'), 'utf8')); } catch { return null; }
}

// What Configurações shows about the preset before the user applies it.
function presetSummary() {
  const p = creatorPreset();
  if (!p) return null;
  return { name: p.name, version: p.version, updatedAt: p.updatedAt, pages: p.config.pages.length, buttons: p.config.pages.reduce((n, pg) => n + pg.buttons.length, 0) };
}
let cfg = config.load(); // fails at startup on a bad buttons.json, not on press
let games = [];
let scanning = false;

const tokenFile = path.join(__dirname, '.token');
if (!fs.existsSync(tokenFile)) fs.writeFileSync(tokenFile, crypto.randomBytes(16).toString('hex'));
const token = fs.readFileSync(tokenFile, 'utf8').trim();

// Private LAN addresses first, so the QR points at the Wi-Fi adapter rather than a VPN or WSL one.
function lanIps() {
  const ips = Object.values(os.networkInterfaces()).flat().filter((i) => i.family === 'IPv4' && !i.internal).map((i) => i.address);
  const rank = (ip) => (ip.startsWith('192.168.') ? 0 : ip.startsWith('10.') ? 1 : 2);
  return ips.sort((a, b) => rank(a) - rank(b));
}
const pairUrl = (ip) => `http://${ip}:${PORT}/?t=${token}`;

function gamesPage() {
  const hidden = new Set(cfg.hiddenGames ?? []);
  return {
    name: 'Jogos',
    auto: true,
    buttons: games.filter((g) => !hidden.has(g.id)).map((g) => ({ id: `auto-${g.id}`, label: g.label, type: 'game', game: g.id, icon: g.icon })),
  };
}

// What phones and the editor see: the user's pages plus the generated Jogos page. The OBS password never leaves the PC.
const publicConfig = () => ({
  ...cfg,
  pages: cfg.features.games && games.length ? [...cfg.pages, gamesPage()] : cfg.pages,
  obs: cfg.obs ? { url: cfg.obs.url } : undefined,
  games: games.map(({ id, label, source, icon }) => ({ id, label, source, icon })),
  scanning,
  creatorPreset: presetSummary(),
  plugins: plugins.list(),
});

const pages = {
  deck: fs.readFileSync(path.join(__dirname, 'public', 'index.html')),
  editor: fs.readFileSync(path.join(__dirname, 'public', 'editor.html'), 'utf8'),
  css: fs.readFileSync(path.join(__dirname, 'public', 'theme.css')),
  keytile: fs.readFileSync(path.join(__dirname, 'public', 'keytile.js')),
};
const isLocal = (req) => ['127.0.0.1', '::1', '::ffff:127.0.0.1'].includes(req.socket.remoteAddress);
const MIME = { png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', webp: 'image/webp', gif: 'image/gif' };

function validToken(t) {
  const a = Buffer.from(t || ''), b = Buffer.from(token);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const html = (res, body) => res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }).end(body);

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x');
  const { pathname } = url;
  if (pathname === '/') return html(res, pages.deck);
  if (pathname === '/favicon.ico') return res.writeHead(204).end();
  if (pathname === '/theme.css') return res.writeHead(200, { 'content-type': 'text/css; charset=utf-8' }).end(pages.css);
  if (pathname === '/keytile.js') return res.writeHead(200, { 'content-type': 'text/javascript; charset=utf-8' }).end(pages.keytile);

  // Icons: filenames are validated, so no path can escape the icons folder.
  const icon = /^\/icon\/([\w-]{1,80}\.(png|jpe?g|webp|gif))$/i.exec(pathname);
  if (icon) {
    if (!isLocal(req) && !validToken(url.searchParams.get('t'))) return res.writeHead(403).end();
    return fs.readFile(path.join(ICONS, icon[1]), (err, data) =>
      err ? res.writeHead(404).end() : res.writeHead(200, { 'content-type': MIME[icon[2].toLowerCase()], 'cache-control': 'max-age=86400' }).end(data));
  }

  // Everything below shows the token or changes files, so only this PC may use it.
  if (!isLocal(req)) return res.writeHead(404).end();
  if (pathname === '/editor') return html(res, pages.editor.replace('__TOKEN__', token));
  if (pathname === '/pair') {
    const cards = await Promise.all(lanIps().map(async (ip) => `<figure>${await QRCode.toString(pairUrl(ip), { type: 'svg', margin: 1 })}<figcaption>${ip}</figcaption></figure>`));
    return html(res, `<!doctype html><meta charset="utf-8"><title>Parear Stream Deck</title>
<style>body{font-family:system-ui;background:#0f1012;color:#e8e9eb;text-align:center;padding:24px}figure{display:inline-block;margin:16px;background:#fff;padding:12px;border-radius:12px;color:#111}svg{width:260px;height:260px}</style>
<h1>Leia o QR code no app Stream Deck</h1><p>Ou na câmera do celular, para usar pelo navegador. Se aparecer mais de um, use o do seu Wi-Fi (normalmente 192.168.x.x).</p>${cards.join('')}`);
  }
  if (pathname === '/api/pair.svg') {
    const [ip] = lanIps();
    return res.writeHead(200, { 'content-type': 'image/svg+xml' }).end(ip ? await QRCode.toString(pairUrl(ip), { type: 'svg', margin: 1 }) : '');
  }
  if (pathname === '/api/pick-app' && req.method === 'POST') {
    const json = (code, body) => res.writeHead(code, { 'content-type': 'application/json' }).end(JSON.stringify(body));
    try {
      const app = await pickApp();
      return json(200, app ?? { cancelled: true });
    } catch (e) {
      return json(500, { error: e.message });
    }
  }
  if (pathname === '/api/icon' && req.method === 'POST') {
    const ext = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/webp': 'webp', 'image/gif': 'gif' }[req.headers['content-type']];
    if (!ext) return res.writeHead(415).end('use PNG, JPG, WEBP ou GIF');
    const chunks = [];
    let size = 0;
    for await (const c of req) {
      size += c.length;
      if (size > 2 << 20) return res.writeHead(413).end('imagem maior que 2 MB');
      chunks.push(c);
    }
    const name = `user-${crypto.randomBytes(6).toString('hex')}.${ext}`;
    fs.mkdirSync(ICONS, { recursive: true });
    fs.writeFileSync(path.join(ICONS, name), Buffer.concat(chunks));
    return res.writeHead(200, { 'content-type': 'application/json' }).end(JSON.stringify({ icon: name }));
  }
  res.writeHead(404).end();
});

const wss = new WebSocketServer({ server });
const send = (ws, msg) => ws.send(JSON.stringify(msg));
const broadcast = (msg) => wss.clients.forEach((c) => c.authed && send(c, msg));

async function rescan() {
  if (scanning) return;
  scanning = true;
  broadcast({ type: 'config', config: publicConfig() });
  try {
    games = await scanAll();
  } catch (e) {
    console.error('Falha ao procurar jogos:', e.message);
  }
  scanning = false;
  broadcast({ type: 'config', config: publicConfig() });
}

wss.on('connection', (ws, req) => {
  if (!validToken(new URL(req.url, 'http://x').searchParams.get('t'))) return ws.close(4001, 'token inválido');
  ws.authed = true;
  send(ws, { type: 'config', config: publicConfig() });
  send(ws, { type: 'live', values: live });
  ws.on('message', async (data) => {
    let msg;
    try { msg = JSON.parse(data); } catch { return; }
    if (msg.type === 'ping') return send(ws, { type: 'pong' });
    if (msg.type === 'rescan') return rescan();
    if (msg.type === 'history') return send(ws, { type: 'history', items: config.history() });
    if (msg.type === 'restore' || msg.type === 'undo') {
      try {
        cfg = msg.type === 'undo' ? config.undo() : config.restore(msg.id);
        send(ws, { type: 'saved' });
        broadcast({ type: 'config', config: publicConfig() });
      } catch (e) {
        send(ws, { type: 'error', error: e.message });
      }
      return;
    }
    if (msg.type === 'setFeatures' || msg.type === 'applyPreset') {
      try {
        if (msg.type === 'setFeatures') {
          cfg = config.save(config.applyFeatures(cfg, msg.features ?? {}), 'config');
        } else {
          const preset = creatorPreset();
          if (!preset) throw new Error('esta versão não tem Preset do Criador');
          // Preset icons ship in presets/icons; copy them next to the user's own so buttons find them.
          fs.mkdirSync(ICONS, { recursive: true });
          for (const f of fs.readdirSync(path.join(PRESET_DIR, 'icons'))) fs.copyFileSync(path.join(PRESET_DIR, 'icons', f), path.join(ICONS, f));
          cfg = config.save({ ...preset.config, setupDone: true, obs: cfg.obs }, 'preset');
        }
        send(ws, { type: 'saved' });
        broadcast({ type: 'config', config: publicConfig() });
      } catch (e) {
        send(ws, { type: 'error', error: e.message });
      }
      return;
    }
    if (msg.type === 'save') {
      try {
        // OBS settings are edited on the PC only; features change only through Configurações, so older clients can't wipe them.
        cfg = config.save({ ...msg.config, obs: cfg.obs, features: cfg.features, setupDone: cfg.setupDone }, isLocal(req) ? (msg.source === 'ia' ? 'ia' : 'pc') : 'celular');
        send(ws, { type: 'saved' });
        broadcast({ type: 'config', config: publicConfig() });
      } catch (e) {
        send(ws, { type: 'error', error: e.message });
      }
      return;
    }
    const b = msg.type === 'press' && [...cfg.pages, ...(cfg.features.games ? [gamesPage()] : [])].flatMap((p) => p.buttons).find((x) => x.id === msg.id);
    if (!b) return send(ws, { type: 'error', id: msg.id, error: 'botão não existe' });
    try {
      await run(b, cfg, games, msg.long === true);
      if (b.type === 'widget') pushLive(); // show the new timer/counter/mute state right away
      send(ws, { type: 'ok', id: b.id });
    } catch (e) {
      send(ws, { type: 'error', id: b.id, error: e.message });
    }
  });
});

// Live keys: recompute every second and send only when something changed.
let live = {};
function pushLive() {
  const buttons = cfg.pages.flatMap((p) => p.buttons).filter((b) => b.type === 'widget');
  const next = buttons.length ? widgets.collect(buttons) : {};
  if (JSON.stringify(next) === JSON.stringify(live)) return;
  live = next;
  broadcast({ type: 'live', values: live });
}
setInterval(pushLive, 1000);

server.listen(PORT, async () => {
  const [ip] = lanIps();
  console.log(`Stream Deck agent rodando na porta ${PORT}.`);
  if (ip) {
    console.log('\nLeia este QR code no app (ou na câmera do celular):');
    console.log(await QRCode.toString(pairUrl(ip), { type: 'terminal', small: true }));
    console.log(`Link: ${pairUrl(ip)}`);
  }
  console.log(`Editor: http://localhost:${PORT}/editor`);
  // Lets the app find the PC again when the router hands it a new IP.
  new Bonjour().publish({ name: `Stream Deck ${os.hostname()}`.slice(0, 63), type: 'streamdeck', port: PORT });
  rescan();
});
