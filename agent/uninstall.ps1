# Para o agente e remove início automático, atalhos e regra de Firewall.
# Instalado pelo pacote: também apaga %LOCALAPPDATA%\StreamDeck (botões, ícones e pareamento).
# Uso: duplo clique em "Desinstalar Stream Deck.bat", ou powershell -ExecutionPolicy Bypass -File uninstall.ps1
$port = 3000
Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($_.OwningProcess)"
  if ($p.Name -eq 'node.exe' -and $p.CommandLine -like '*server.js*') { Stop-Process -Id $p.ProcessId -Force }
}
Remove-Item -ErrorAction SilentlyContinue (Join-Path ([Environment]::GetFolderPath('Startup')) 'Stream Deck Agent.vbs')
foreach ($f in @("$([Environment]::GetFolderPath('Desktop'))\Stream Deck - Parear.url", "$([Environment]::GetFolderPath('Desktop'))\Stream Deck.lnk", "$([Environment]::GetFolderPath('Programs'))\Stream Deck.lnk")) { Remove-Item -ErrorAction SilentlyContinue $f }
try {
  Start-Process cmd -ArgumentList '/c netsh advfirewall firewall delete rule name="Stream Deck Agent"' -Verb RunAs -WindowStyle Hidden -Wait
} catch {
  Write-Warning 'Regra de Firewall não removida (permissão negada).'
}
$installed = Join-Path $env:LOCALAPPDATA 'StreamDeck'
if (Test-Path $installed) {
  Set-Location $env:TEMP # the script may be running from inside that folder
  Start-Sleep -Milliseconds 500
  Remove-Item -Recurse -Force $installed -ErrorAction SilentlyContinue
}
Write-Host 'Stream Deck removido deste PC.'
