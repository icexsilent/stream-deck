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

const PORT = Number(process.env.PORT) || 3000;
let cfg = config.load(); // fails at startup on a bad buttons.json, not on press

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

// The phone never sees the OBS password.
const publicConfig = () => ({ ...cfg, obs: cfg.obs ? { url: cfg.obs.url } : undefined });

const page = fs.readFileSync(path.join(__dirname, 'public', 'index.html'));
const isLocal = (req) => ['127.0.0.1', '::1', '::ffff:127.0.0.1'].includes(req.socket.remoteAddress);

const server = http.createServer(async (req, res) => {
  const { pathname } = new URL(req.url, 'http://x');
  if (pathname === '/') return res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }).end(page);
  // The pairing page shows the token, so only this PC may open it.
  if (pathname === '/pair' && isLocal(req)) {
    const cards = await Promise.all(lanIps().map(async (ip) => `<figure>${await QRCode.toString(pairUrl(ip), { type: 'svg', margin: 1 })}<figcaption>${ip}</figcaption></figure>`));
    return res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }).end(`<!doctype html><meta charset="utf-8"><title>Parear Stream Deck</title>
<style>body{font-family:system-ui;background:#111;color:#eee;text-align:center;padding:24px}figure{display:inline-block;margin:16px;background:#fff;padding:12px;border-radius:12px;color:#111}svg{width:260px;height:260px}</style>
<h1>Leia o QR code no app Stream Deck</h1><p>Ou na câmera do celular, para usar pelo navegador. Se aparecer mais de um, use o do seu Wi-Fi (normalmente 192.168.x.x).</p>${cards.join('')}`);
  }
  res.writeHead(404).end();
});

function validToken(t) {
  const a = Buffer.from(t || ''), b = Buffer.from(token);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const wss = new WebSocketServer({ server });
const send = (ws, msg) => ws.send(JSON.stringify(msg));
const broadcast = (msg) => wss.clients.forEach((c) => c.authed && send(c, msg));

wss.on('connection', (ws, req) => {
  if (!validToken(new URL(req.url, 'http://x').searchParams.get('t'))) return ws.close(4001, 'token inválido');
  ws.authed = true;
  send(ws, { type: 'config', config: publicConfig() });
  ws.on('message', async (data) => {
    let msg;
    try { msg = JSON.parse(data); } catch { return; }
    if (msg.type === 'ping') return send(ws, { type: 'pong' });
    if (msg.type === 'save') {
      try {
        cfg = config.save({ ...msg.config, obs: cfg.obs }); // OBS settings are edited on the PC only
        send(ws, { type: 'saved' });
        broadcast({ type: 'config', config: publicConfig() });
      } catch (e) {
        send(ws, { type: 'error', error: e.message });
      }
      return;
    }
    const b = msg.type === 'press' && cfg.pages.flatMap((p) => p.buttons).find((x) => x.id === msg.id);
    if (!b) return send(ws, { type: 'error', id: msg.id, error: 'botão não existe' });
    try {
      await run(b, cfg);
      send(ws, { type: 'ok', id: b.id });
    } catch (e) {
      send(ws, { type: 'error', id: b.id, error: e.message });
    }
  });
});

server.listen(PORT, async () => {
  const [ip] = lanIps();
  console.log(`Stream Deck agent rodando na porta ${PORT}.`);
  if (ip) {
    console.log('\nLeia este QR code no app (ou na câmera do celular):');
    console.log(await QRCode.toString(pairUrl(ip), { type: 'terminal', small: true }));
    console.log(`Link: ${pairUrl(ip)}`);
  }
  console.log(`QR code maior: abra http://localhost:${PORT}/pair neste PC.`);
  // Lets the app find the PC again when the router hands it a new IP.
  new Bonjour().publish({ name: `Stream Deck ${os.hostname()}`.slice(0, 63), type: 'streamdeck', port: PORT });
});
