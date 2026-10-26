# Long-lived helper for live keys: prints one JSON line per second with the playing media and master volume.
# Reads commands from stdin: "mute" toggles mute, "vol <0-100>" sets the volume.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
  int f(); int g(); int h(); int i();
  int SetMasterVolumeLevelScalar(float level, Guid ctx);
  int j(); int GetMasterVolumeLevelScalar(out float level);
  int k(); int l(); int m(); int n();
  int SetMute([MarshalAs(UnmanagedType.Bool)] bool mute, Guid ctx);
  int GetMute(out bool mute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice { int Activate(ref Guid id, int ctx, IntPtr p, [MarshalAs(UnmanagedType.IUnknown)] out object o); }
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator { int f(); int GetDefaultAudioEndpoint(int flow, int role, out IMMDevice d); }
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumerator { }
public static class Vol {
  static IAudioEndpointVolume Ep() {
    var e = (IMMDeviceEnumerator)new MMDeviceEnumerator(); IMMDevice d; e.GetDefaultAudioEndpoint(0, 1, out d);
    Guid id = typeof(IAudioEndpointVolume).GUID; object o; d.Activate(ref id, 23, IntPtr.Zero, out o); return (IAudioEndpointVolume)o;
  }
  public static int Level { get { float v; Ep().GetMasterVolumeLevelScalar(out v); return (int)Math.Round(v * 100); } set { Ep().SetMasterVolumeLevelScalar(Math.Max(0, Math.Min(100, value)) / 100f, Guid.Empty); } }
  public static bool Muted { get { bool m; Ep().GetMute(out m); return m; } set { Ep().SetMute(value, Guid.Empty); } }
}
'@

# WinRT media session (what Windows shows on the volume flyout: Spotify, YouTube in the browser, etc.).
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
function Await($op, [Type]$type) { $t = $asTask.MakeGenericMethod($type).Invoke($null, @($op)); $t.Wait(-1) | Out-Null; $t.Result }
$null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime]
$mgr = Await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])

# [Console]::In is already consumed by powershell -File; read the raw stdin stream instead.
$reader = New-Object IO.StreamReader ([Console]::OpenStandardInput())
$pending = $reader.ReadLineAsync()
while ($true) {
  while ($pending.IsCompleted) {
    $cmd = $pending.Result
    if ($null -eq $cmd) { exit 0 } # agent closed stdin
    try {
      if ($cmd -eq 'mute') { [Vol]::Muted = -not [Vol]::Muted }
      elseif ($cmd -match '^vol (\d+)$') { [Vol]::Level = [int]$Matches[1] }
    } catch {}
    $pending = $reader.ReadLineAsync()
  }
  $media = $null
  try {
    $s = $mgr.GetCurrentSession()
    if ($s) {
      $p = Await ($s.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
      $media = @{ title = $p.Title; artist = $p.Artist; playing = ($s.GetPlaybackInfo().PlaybackStatus -eq 'Playing'); app = $s.SourceAppUserModelId }
    }
  } catch {}
  $vol = $null
  try { $vol = @{ level = [Vol]::Level; muted = [Vol]::Muted } } catch {}
  @{ media = $media; volume = $vol } | ConvertTo-Json -Compress -Depth 3
  Start-Sleep -Milliseconds 1000
}
