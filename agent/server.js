const http = require('node:http');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawn } = require('node:child_process');
const { WebSocketServer } = require('ws');
const { toVks } = require('./keys');

const PORT = Number(process.env.PORT) || 3000;

// The phone only sends a button id; what each id does lives here on the PC, so the phone can't run arbitrary commands.
const buttons = JSON.parse(fs.readFileSync(path.join(__dirname, 'buttons.json'), 'utf8')).buttons;
for (const b of buttons) {
  if (b.type === 'hotkey') b.vks = toVks(b.keys); // fails at startup on a bad key, not on press
  else if (b.type !== 'open') throw new Error(`tipo desconhecido no botão "${b.id}": ${b.type}`);
}

const tokenFile = path.join(__dirname, '.token');
if (!fs.existsSync(tokenFile)) fs.writeFileSync(tokenFile, crypto.randomBytes(16).toString('hex'));
const token = fs.readFileSync(tokenFile, 'utf8').trim();

// One long-lived PowerShell process presses keys via user32, so a press costs ~1 ms instead of a new process.
const PS = `
$ProgressPreference = 'SilentlyContinue'
Add-Type -Name K -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);'
while ($null -ne ($line = [Console]::In.ReadLine())) {
  $vks = @($line -split ',' | ForEach-Object { [byte]$_ })
  foreach ($v in $vks) { [W.K]::keybd_event($v, 0, 0, [UIntPtr]::Zero) }
  [array]::Reverse($vks)
  foreach ($v in $vks) { [W.K]::keybd_event($v, 0, 2, [UIntPtr]::Zero) }
}`;
let keyboard;
function pressKeys(vks) {
  if (!keyboard || keyboard.exitCode !== null) {
    keyboard = spawn('powershell', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(PS, 'utf16le').toString('base64')], { stdio: ['pipe', 'ignore', 'inherit'] });
  }
  keyboard.stdin.write(vks.join(',') + '\n');
}

function run(b) {
  if (b.type === 'hotkey') pressKeys(b.vks);
  else spawn('cmd', ['/c', 'start', '', b.target], { detached: true, stdio: 'ignore' }).unref();
}

const page = fs.readFileSync(path.join(__dirname, 'public', 'index.html'));
const server = http.createServer((req, res) => {
  if (new URL(req.url, 'http://x').pathname !== '/') return res.writeHead(404).end();
  res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }).end(page);
});

function validToken(t) {
  const a = Buffer.from(t || ''), b = Buffer.from(token);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const wss = new WebSocketServer({ server });
wss.on('connection', (ws, req) => {
  if (!validToken(new URL(req.url, 'http://x').searchParams.get('t'))) return ws.close(4001, 'token inválido');
  ws.send(JSON.stringify({ type: 'buttons', buttons: buttons.map(({ id, label }) => ({ id, label })) }));
  ws.on('message', (data) => {
    let msg;
    try { msg = JSON.parse(data); } catch { return; }
    const b = msg.type === 'press' && buttons.find((x) => x.id === msg.id);
    if (!b) return ws.send(JSON.stringify({ type: 'error', id: msg.id, error: 'botão não existe' }));
    try {
      run(b);
      ws.send(JSON.stringify({ type: 'ok', id: b.id }));
    } catch (e) {
      ws.send(JSON.stringify({ type: 'error', id: b.id, error: e.message }));
    }
  });
});

server.listen(PORT, () => {
  console.log('Stream Deck agent rodando. Abra no celular (mesmo Wi-Fi):');
  for (const list of Object.values(os.networkInterfaces())) {
    for (const i of list) if (i.family === 'IPv4' && !i.internal) console.log(`  http://${i.address}:${PORT}/?t=${token}`);
  }
});
