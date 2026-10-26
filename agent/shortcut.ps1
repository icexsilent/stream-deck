# Cria o atalho "Stream Deck" (Área de Trabalho e Menu Iniciar) que abre o editor numa janela própria, como um programa.
# Uso: powershell -ExecutionPolicy Bypass -File shortcut.ps1
$ErrorActionPreference = 'Stop'
$agent = $PSScriptRoot
$ico = Join-Path $agent 'streamdeck.ico'

# Draws the app icon once: a 3x3 grid of keys with one amber key.
if (-not (Test-Path $ico)) {
  Add-Type -AssemblyName System.Drawing
  $bmp = New-Object Drawing.Bitmap 256, 256
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([Drawing.Color]::FromArgb(15, 16, 18))
  $key = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(58, 63, 71))
  $amber = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(245, 165, 36))
  for ($r = 0; $r -lt 3; $r++) { for ($c = 0; $c -lt 3; $c++) {
    $b = if ($r -eq 0 -and $c -eq 0) { $amber } else { $key }
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $x = 24 + $c * 72; $y = 24 + $r * 72; $s = 64; $rad = 14
    $path.AddArc($x, $y, $rad, $rad, 180, 90); $path.AddArc($x + $s - $rad, $y, $rad, $rad, 270, 90)
    $path.AddArc($x + $s - $rad, $y + $s - $rad, $rad, $rad, 0, 90); $path.AddArc($x, $y + $s - $rad, $rad, $rad, 90, 90)
    $g.FillPath($b, $path)
  } }
  $png = New-Object IO.MemoryStream
  $bmp.Save($png, [Drawing.Imaging.ImageFormat]::Png)
  # ICO container holding one 256px PNG image.
  $bytes = $png.ToArray()
  $out = New-Object IO.BinaryWriter ([IO.File]::Create($ico))
  $out.Write([uint16]0); $out.Write([uint16]1); $out.Write([uint16]1)
  $out.Write([byte]0); $out.Write([byte]0); $out.Write([byte]0); $out.Write([byte]0)
  $out.Write([uint16]1); $out.Write([uint16]32); $out.Write([uint32]$bytes.Length); $out.Write([uint32]22)
  $out.Write($bytes); $out.Close()
}

$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw 'Microsoft Edge não encontrado.' }

$sh = New-Object -ComObject WScript.Shell
foreach ($dir in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
  $lnk = $sh.CreateShortcut((Join-Path $dir 'Stream Deck.lnk'))
  $lnk.TargetPath = $edge
  $lnk.Arguments = '--app=http://localhost:3000/editor --window-size=1440,900'
  $lnk.IconLocation = $ico
  $lnk.Description = 'Editor do Stream Deck'
  $lnk.Save()
}
Write-Host 'Atalho "Stream Deck" criado na Área de Trabalho e no Menu Iniciar.'
