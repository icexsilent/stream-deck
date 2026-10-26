// Opens the Windows file picker on the PC, then reads the program's name and a 256px icon from the shell.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFile } = require('node:child_process');
const { ICONS } = require('./games');

const PS = String.raw`
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class ShellIcon {
  [ComImport, Guid("bcc18b79-ba16-442f-80c4-8a59c30c463b"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  interface IShellItemImageFactory { void GetImage(SIZE size, int flags, out IntPtr phbm); }
  [StructLayout(LayoutKind.Sequential)] struct SIZE { public int cx, cy; }
  [StructLayout(LayoutKind.Sequential)] struct BITMAP { public int bmType, bmWidth, bmHeight, bmWidthBytes; public ushort bmPlanes, bmBitsPixel; public IntPtr bmBits; }
  [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
  static extern void SHCreateItemFromParsingName(string path, IntPtr pbc, ref Guid riid, out IShellItemImageFactory ppv);
  [DllImport("gdi32.dll")] static extern int GetObject(IntPtr h, int size, ref BITMAP bm);
  [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr h);
  // Copies the DIB's pixels directly, since Image.FromHbitmap drops the alpha channel and gives icons a black box.
  public static void Save(string file, string outPng) {
    Guid iid = new Guid("bcc18b79-ba16-442f-80c4-8a59c30c463b");
    IShellItemImageFactory f; SHCreateItemFromParsingName(file, IntPtr.Zero, ref iid, out f);
    IntPtr h; f.GetImage(new SIZE { cx = 256, cy = 256 }, 0x4 /* icon only */, out h);
    try {
      BITMAP bm = new BITMAP(); GetObject(h, Marshal.SizeOf(typeof(BITMAP)), ref bm);
      using (var view = new Bitmap(bm.bmWidth, bm.bmHeight, bm.bmWidthBytes, PixelFormat.Format32bppArgb, bm.bmBits))
      using (var copy = new Bitmap(view)) {
        copy.RotateFlip(RotateFlipType.RotateNoneFlipY); // shell DIBs are bottom-up
        copy.Save(outPng, ImageFormat.Png);
      }
    } finally { DeleteObject(h); }
  }
}
'@
# The agent runs in the background, and Windows won't bring a background program's dialog to the front.
# A shown, always-on-top owner window keeps the dialog above the editor instead of hidden behind it.
$owner = New-Object Windows.Forms.Form -Property @{
  TopMost = $true; ShowInTaskbar = $true; Text = 'Stream Deck'; FormBorderStyle = 'None'
  StartPosition = 'CenterScreen'; Size = New-Object Drawing.Size 1, 1; Opacity = 0.01
}
$owner.Show()
$owner.Activate()
$dlg = New-Object Windows.Forms.OpenFileDialog -Property @{
  Title = 'Escolha o programa para o botão'
  Filter = 'Programas e atalhos (*.exe;*.lnk;*.bat;*.url)|*.exe;*.lnk;*.bat;*.url|Todos os arquivos (*.*)|*.*'
  InitialDirectory = [Environment]::GetFolderPath('ProgramFiles')
  DereferenceLinks = $false
}
if ($dlg.ShowDialog($owner) -ne 'OK') { exit 0 }
$file = $dlg.FileName
$label = [IO.Path]::GetFileNameWithoutExtension($file)
if ($file -like '*.exe') {
  $desc = (Get-Item -LiteralPath $file).VersionInfo.FileDescription
  if ($desc -and $desc.Trim().Length -le 40) { $label = $desc.Trim() }
}
$icon = $true
try { [ShellIcon]::Save($file, $env:SD_ICON_OUT) } catch {
  try { [Drawing.Icon]::ExtractAssociatedIcon($file).ToBitmap().Save($env:SD_ICON_OUT) } catch { $icon = $false }
}
@{ target = $file; label = $label; icon = $icon } | ConvertTo-Json -Compress
`;

let busy = false;

/** Returns { target, label, icon } or null when the user cancels. */
async function pickApp() {
  if (busy) throw new Error('a janela de escolher programa já está aberta no PC');
  busy = true;
  fs.mkdirSync(ICONS, { recursive: true });
  const tmp = path.join(ICONS, `tmp-${crypto.randomBytes(4).toString('hex')}.png`);
  try {
    const stdout = await new Promise((resolve, reject) =>
      execFile('powershell', ['-NoProfile', '-STA', '-EncodedCommand', Buffer.from(PS, 'utf16le').toString('base64')],
        { env: { ...process.env, SD_ICON_OUT: tmp }, windowsHide: true, timeout: 10 * 60_000 },
        (err, out, errOut) => (err ? reject(new Error(errOut.trim() || err.message)) : resolve(out))));
    if (!stdout.trim()) return null;
    const r = JSON.parse(stdout.trim());
    let icon;
    if (r.icon && fs.existsSync(tmp)) {
      // Same program -> same file name, so re-adding an app doesn't pile up copies of its icon.
      icon = `app-${crypto.createHash('sha1').update(r.target.toLowerCase()).digest('hex').slice(0, 12)}.png`;
      fs.renameSync(tmp, path.join(ICONS, icon));
    }
    return { target: r.target, label: r.label.slice(0, 40), icon };
  } finally {
    busy = false;
    fs.rmSync(tmp, { force: true });
  }
}

module.exports = { pickApp };
