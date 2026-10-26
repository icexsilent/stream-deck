// Live keys: each widget button gets a value { text, sub?, progress?, alert? } recomputed every second.
const os = require('node:os');
const path = require('node:path');
const readline = require('node:readline');
const { spawn, execFile } = require('node:child_process');

const KINDS = {
  clock: 'Relógio',
  cpu: 'Uso da CPU',
  ram: 'Uso da memória RAM',
  gpu: 'Uso da placa de vídeo',
  media: 'Música tocando',
  volume: 'Volume do PC',
  timer: 'Cronômetro (contagem regressiva)',
  counter: 'Contador',
  weather: 'Clima',
};

// ---- system samplers ----
let lastCpu = os.cpus();
let cpuPct = 0;
function sampleCpu() {
  const now = os.cpus();
  let idle = 0, total = 0;
  now.forEach((c, i) => {
    const p = lastCpu[i]?.times ?? c.times;
    for (const k of Object.keys(c.times)) total += c.times[k] - p[k];
    idle += c.times.idle - p.idle;
  });
  lastCpu = now;
  if (total > 0) cpuPct = Math.round(100 * (1 - idle / total));
}

let gpu = null; // { pct, temp? }
let gpuBusy = false;
let hasNvidiaSmi = true;
function sampleGpu() {
  if (gpuBusy) return;
  gpuBusy = true;
  const done = () => { gpuBusy = false; };
  if (hasNvidiaSmi) {
    execFile('nvidia-smi', ['--query-gpu=utilization.gpu,temperature.gpu', '--format=csv,noheader,nounits'], { windowsHide: true, timeout: 4000 }, (err, out) => {
      if (err) { hasNvidiaSmi = false; return done(); }
      const [pct, temp] = out.trim().split('\n')[0].split(',').map(Number);
      gpu = { pct, temp };
      done();
    });
  } else {
    // Any GPU vendor: Windows' own counter, slower (~2 s), so sampled less often by the caller.
    execFile('powershell', ['-NoProfile', '-Command', "[math]::Round(((Get-Counter '\\GPU Engine(*engtype_3D)\\Utilization Percentage').CounterSamples | Measure-Object CookedValue -Sum).Sum)"],
      { windowsHide: true, timeout: 8000 }, (err, out) => {
        if (!err && out.trim()) gpu = { pct: Math.min(100, Number(out.trim())) };
        done();
      });
  }
}

// Media and volume come from one resident PowerShell process (sysinfo.ps1) that prints a JSON line per second.
let sys = null;
let sysState = { media: null, volume: null };
function ensureSysinfo() {
  if (sys && sys.exitCode === null) return;
  sys = spawn('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(__dirname, 'sysinfo.ps1')], { windowsHide: true, stdio: ['pipe', 'pipe', 'ignore'] });
  readline.createInterface({ input: sys.stdout }).on('line', (l) => { try { sysState = JSON.parse(l); } catch {} });
  sys.on('exit', () => { sysState = { media: null, volume: null }; });
}
const sysCommand = (c) => { ensureSysinfo(); sys.stdin.write(c + '\n'); };

// ---- weather (Open-Meteo, no API key) ----
const weather = new Map(); // city -> { at, value }
const WMO = [[0, '☀️', 'Céu limpo'], [3, '⛅', 'Nublado'], [48, '🌫️', 'Neblina'], [57, '🌦️', 'Garoa'], [67, '🌧️', 'Chuva'], [77, '🌨️', 'Neve'], [82, '🌧️', 'Pancadas'], [86, '🌨️', 'Neve'], [99, '⛈️', 'Tempestade']];
async function fetchWeather(city) {
  const geo = await (await fetch(`https://geocoding-api.open-meteo.com/v1/search?count=1&language=pt&name=${encodeURIComponent(city)}`)).json();
  const place = geo.results?.[0];
  if (!place) return { text: '?', sub: 'cidade não encontrada', alert: true };
  const f = await (await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${place.latitude}&longitude=${place.longitude}&current=temperature_2m,weather_code`)).json();
  const code = f.current.weather_code;
  const [, icon, desc] = WMO.find(([max]) => code <= max) ?? WMO.at(-1);
  return { text: `${icon} ${Math.round(f.current.temperature_2m)}°`, sub: `${place.name} · ${desc}` };
}
function weatherValue(city) {
  const c = weather.get(city);
  if (!c || Date.now() - c.at > 15 * 60_000) {
    weather.set(city, { at: Date.now(), value: c?.value ?? { text: '…', sub: city } }); // marks the fetch as in flight
    fetchWeather(city).then((value) => weather.set(city, { at: Date.now(), value }))
      .catch(() => weather.set(city, { at: Date.now() - 14 * 60_000, value: { text: '—', sub: 'sem internet', alert: true } })); // retry in ~1 min
  }
  return weather.get(city).value;
}

// ---- per-button state (timers, counters) ----
// shortcut: kept in memory only, so counters and timers reset when the agent restarts; persist to a file if that matters.
const state = new Map();
const fmt = (ms) => {
  const s = Math.ceil(ms / 1000);
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), ss = String(s % 60).padStart(2, '0');
  return h ? `${h}:${String(m).padStart(2, '0')}:${ss}` : `${m}:${ss}`;
};

function value(b) {
  switch (b.widget) {
    case 'clock': {
      const d = new Date();
      return { text: d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }), sub: d.toLocaleDateString('pt-BR', { weekday: 'short', day: 'numeric', month: 'short' }) };
    }
    case 'cpu': return { text: `${cpuPct}%`, sub: 'CPU', progress: cpuPct / 100, alert: cpuPct >= 90 };
    case 'ram': {
      const used = os.totalmem() - os.freemem();
      const pct = Math.round((100 * used) / os.totalmem());
      return { text: `${pct}%`, sub: `RAM ${(used / 2 ** 30).toFixed(1)}/${Math.round(os.totalmem() / 2 ** 30)} GB`, progress: pct / 100, alert: pct >= 90 };
    }
    case 'gpu':
      if (!gpu) return { text: '…', sub: 'GPU' };
      return { text: `${gpu.pct}%`, sub: gpu.temp ? `GPU ${gpu.temp}°C` : 'GPU', progress: gpu.pct / 100, alert: gpu.temp >= 85 };
    case 'media': {
      const m = sysState.media;
      if (!m || !m.title) return { text: '⏹', sub: 'nada tocando' };
      return { text: `${m.playing ? '▶' : '⏸'} ${m.title}`, sub: m.artist || appName(m.app), playing: m.playing };
    }
    case 'volume': {
      const v = sysState.volume;
      if (!v) return { text: '…', sub: 'Volume' };
      return { text: v.muted ? '🔇' : `${v.level}%`, sub: v.muted ? 'mudo' : 'Volume', progress: v.level / 100, alert: v.muted };
    }
    case 'timer': {
      const total = (b.minutes ?? 5) * 60_000;
      const s = state.get(b.id) ?? { left: total, endAt: null };
      const left = s.endAt ? Math.max(0, s.endAt - Date.now()) : s.left;
      if (left === 0) return { text: '⏰ 0:00', sub: 'acabou! toque p/ zerar', progress: 0, alert: true };
      return { text: fmt(left), sub: s.endAt ? 'rodando' : 'parado · toque p/ iniciar', progress: left / total };
    }
    case 'counter': return { text: String(state.get(b.id) ?? 0), sub: 'toque +1 · segure zera' };
    case 'weather': return b.city ? weatherValue(b.city) : { text: '?', sub: 'escolha a cidade', alert: true };
    default: return { text: '?' };
  }
}

function appName(id = '') {
  const known = { spotify: 'Spotify', opera: 'Opera', chrome: 'Chrome', msedge: 'Edge', firefox: 'Firefox', vlc: 'VLC' };
  const hit = Object.keys(known).find((k) => id.toLowerCase().includes(k));
  return hit ? known[hit] : '';
}

/** Returns the media key to press for the agent's keyboard helper, or null when handled here. */
function press(b, long) {
  switch (b.widget) {
    case 'media': return long ? 'next' : 'playpause';
    case 'volume': sysCommand('mute'); return null;
    case 'cpu': case 'ram': case 'gpu': return { open: 'taskmgr.exe' };
    case 'timer': {
      const total = (b.minutes ?? 5) * 60_000;
      const s = state.get(b.id) ?? { left: total, endAt: null };
      const left = s.endAt ? Math.max(0, s.endAt - Date.now()) : s.left;
      if (long || left === 0) state.set(b.id, { left: total, endAt: null });
      else state.set(b.id, s.endAt ? { left, endAt: null } : { left, endAt: Date.now() + left });
      return null;
    }
    case 'counter': state.set(b.id, long ? 0 : (state.get(b.id) ?? 0) + 1); return null;
    default: return null;
  }
}

let tick = 0;
/** Recomputes every widget on the given buttons; returns { id: value }. */
function collect(buttons) {
  const kinds = new Set(buttons.map((b) => b.widget));
  if (kinds.has('cpu')) sampleCpu();
  if (kinds.has('gpu') && (hasNvidiaSmi ? tick % 2 === 0 : tick % 5 === 0)) sampleGpu();
  if (kinds.has('media') || kinds.has('volume')) ensureSysinfo();
  tick++;
  return Object.fromEntries(buttons.map((b) => [b.id, value(b)]));
}

module.exports = { KINDS, collect, press, value, state };
