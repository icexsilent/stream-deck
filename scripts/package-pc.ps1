# Gera dist\StreamDeck-PC.zip: o agente com as dependências e um Node portátil, pronto para outro PC sem nada instalado.
# Uso: powershell -ExecutionPolicy Bypass -File scripts\package-pc.ps1
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot
$dist = Join-Path $repo 'dist'
$pkg = Join-Path $dist 'StreamDeck-PC'
$version = (node -v).TrimStart('v') # same Node the agent is developed and tested with

Remove-Item -Recurse -Force $pkg -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "$pkg\app", "$pkg\node", "$dist\cache" | Out-Null

Write-Host "1/4 Node $version portátil..."
$nodeZip = Join-Path $dist "cache\node-v$version-win-x64.zip"
if (-not (Test-Path $nodeZip)) { Invoke-WebRequest "https://nodejs.org/dist/v$version/node-v$version-win-x64.zip" -OutFile $nodeZip -UseBasicParsing }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($nodeZip)
try {
  $entry = $zip.Entries | Where-Object { $_.FullName -eq "node-v$version-win-x64/node.exe" }
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, "$pkg\node\node.exe", $true)
} finally { $zip.Dispose() }

Write-Host '2/4 Agente (sem dados pessoais nem testes)...'
# Personal data (buttons.json, .token, icons, logs) must never ship to other people.
robocopy "$repo\agent" "$pkg\app" /E /NFL /NDL /NJH /NJS /NP /XF buttons.json .token agent.log streamdeck.ico *.test.js /XD "$repo\agent\node_modules" "$repo\agent\icons" | Out-Null # full paths: presets\icons must ship
if ($LASTEXITCODE -ge 8) { throw 'falha ao copiar o agente' }
Push-Location "$pkg\app"
try { npm ci --omit=dev --no-audit --no-fund | Out-Null; if ($LASTEXITCODE) { throw 'npm ci falhou' } } finally { Pop-Location }

Write-Host '3/4 Atalhos de instalar e desinstalar...'
"@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0app\install.ps1`"`r`npause" | Set-Content -Encoding ASCII "$pkg\Instalar Stream Deck.bat"
"@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0app\uninstall.ps1`"`r`npause" | Set-Content -Encoding ASCII "$pkg\Desinstalar Stream Deck.bat"

Write-Host '4/4 Compactando...'
$out = Join-Path $dist 'StreamDeck-PC.zip'
Remove-Item -Force $out -ErrorAction SilentlyContinue
# Windows PowerShell's zip helpers write "\" in entry paths, which breaks unzippers other than Explorer; entries are added by hand with "/".
$zip = [IO.Compression.ZipFile]::Open($out, [IO.Compression.ZipArchiveMode]::Create)
try {
  Get-ChildItem $pkg -Recurse -File | ForEach-Object {
    $name = $_.FullName.Substring($pkg.Length + 1).Replace('\', '/')
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $name, [IO.Compression.CompressionLevel]::Optimal)
  }
} finally { $zip.Dispose() }
Write-Host "Pronto: $out ($([math]::Round((Get-Item $out).Length / 1MB, 1)) MB)"
