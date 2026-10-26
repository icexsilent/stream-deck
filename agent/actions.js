const { spawn } = require('node:child_process');
const { OBSWebSocket } = require('obs-websocket-js');
const { toVks } = require('./keys');

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

async function run(b, cfg) {
  if (b.type === 'hotkey') return pressKeys(toVks(b.keys));
  if (b.type === 'open') return void spawn('cmd', ['/c', 'start', '', b.target], { detached: true, stdio: 'ignore' }).unref();
  if (b.action === 'scene') return obsCall(cfg, 'SetCurrentProgramScene', { sceneName: b.name });
  if (b.action === 'toggleMute') return obsCall(cfg, 'ToggleInputMute', { inputName: b.name });
  if (b.action === 'toggleStream') return obsCall(cfg, 'ToggleStream');
  if (b.action === 'toggleRecord') return obsCall(cfg, 'ToggleRecord');
}

module.exports = { run };
