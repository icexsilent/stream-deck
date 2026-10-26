const { spawn } = require('node:child_process');
const { OBSWebSocket } = require('obs-websocket-js');
const { toVks } = require('./keys');
const widgets = require('./widgets');

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

const obs = new OBSWebSocket();
let obsConnected = false;
obs.on('ConnectionClosed', () => { obsConnected = false; });

async function obsCall(cfg, request, data) {
  if (!cfg.obs) throw new Error('OBS não configurado: adicione "obs": {"url": "ws://127.0.0.1:4455", "password": "..."} no buttons.json');
  if (!obsConnected) {
    try {
      await obs.connect(cfg.obs.url, cfg.obs.password || undefined);
    } catch (e) {
      throw new Error(`não conectou no OBS (${cfg.obs.url}): abra o OBS e ative Ferramentas > Configurações do WebSocket. ${e.message}`);
    }
    obsConnected = true;
  }
  await obs.call(request, data);
}

// Quoted by hand: Epic launch links contain "&", which cmd would otherwise treat as a second command.
function open(target) {
  spawn('cmd', ['/c', `start "" "${target}"`], { detached: true, stdio: 'ignore', windowsVerbatimArguments: true }).unref();
}

function launchGame(id, games) {
  const g = games.find((x) => x.id === id);
  if (!g) throw new Error('jogo não encontrado: foi desinstalado? Toque em "Procurar jogos" no editor.');
  if (g.launch.uri) return open(g.launch.uri);
  spawn(g.launch.exe, g.launch.args ?? [], { detached: true, stdio: 'ignore' }).unref();
}

async function run(b, cfg, games = [], long = false) {
  if (b.type === 'widget') {
    const r = widgets.press(b, long);
    if (typeof r === 'string') return pressKeys(toVks(r)); // media keys for the music widget
    if (r?.open) return open(r.open);
    return;
  }
  if (long) return; // long press only means something to widgets
  if (b.type === 'hotkey') return pressKeys(toVks(b.keys));
  if (b.type === 'open') return open(b.target);
  if (b.type === 'game') return launchGame(b.game, games);
  if (b.type === 'page') return; // page switches happen on the device
  if (b.action === 'scene') return obsCall(cfg, 'SetCurrentProgramScene', { sceneName: b.name });
  if (b.action === 'toggleMute') return obsCall(cfg, 'ToggleInputMute', { inputName: b.name });
  if (b.action === 'toggleStream') return obsCall(cfg, 'ToggleStream');
  if (b.action === 'toggleRecord') return obsCall(cfg, 'ToggleRecord');
}

module.exports = { run };
