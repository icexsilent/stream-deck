const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');

const EXT = ['.mp3', '.wav', '.ogg'];

// Local copy: WPF MediaPlayer plays on the default device; the path goes in an env var so quotes in it can't break the script.
const PS = `Add-Type -AssemblyName PresentationCore
$p = New-Object System.Windows.Media.MediaPlayer
$p.Volume = [double]$env:SOM_VOL
$p.Open([uri]$env:SOM_FILE); $p.Play()
for ($i = 0; $i -lt 50 -and -not $p.NaturalDuration.HasTimeSpan; $i++) { Start-Sleep -Milliseconds 100 }
if ($p.NaturalDuration.HasTimeSpan) { Start-Sleep -Milliseconds ($p.NaturalDuration.TimeSpan.TotalMilliseconds + 200) }`;

function check(file, volume) {
  if (!(volume >= 0 && volume <= 100)) throw new Error('volume deve ser de 0 a 100');
  if (!EXT.includes(path.extname(file).toLowerCase())) throw new Error(`formato não suportado (use ${EXT.join(', ')})`);
  if (!fs.existsSync(file)) throw new Error(`arquivo não encontrado: ${file}`);
}

module.exports = {
  check,
  actions: {
    play({ file, volume, target }) {
      check(file, volume);
      // No "detached": on Windows it starts PowerShell without a console and it quits before playing.
      const opts = { stdio: 'ignore', windowsHide: true };
      // Discord copy: Windows routes ffplay.exe to "CABLE Input" (set once in the volume mixer), so no device code here.
      if (target !== 'só pc') {
        spawn('ffplay', ['-nodisp', '-autoexit', '-loglevel', 'quiet', '-volume', String(volume), file], opts).on('error', () => {}).unref();
      }
      if (target !== 'só discord') {
        spawn('powershell', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(PS, 'utf16le').toString('base64')],
          { ...opts, env: { ...process.env, SOM_FILE: file, SOM_VOL: String(volume / 100) } }).unref();
      }
    },
  },
};
