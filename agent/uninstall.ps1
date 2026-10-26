# Para o agente e remove início automático, atalho e regra de Firewall. Não apaga buttons.json nem o token.
# Uso: powershell -ExecutionPolicy Bypass -File uninstall.ps1
$port = 3000
Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($_.OwningProcess)"
  if ($p.Name -eq 'node.exe' -and $p.CommandLine -like '*server.js*') { Stop-Process -Id $p.ProcessId -Force }
}
Remove-Item -ErrorAction SilentlyContinue (Join-Path ([Environment]::GetFolderPath('Startup')) 'Stream Deck Agent.vbs')
Remove-Item -ErrorAction SilentlyContinue (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Stream Deck - Parear.url')
try {
  Start-Process cmd -ArgumentList '/c netsh advfirewall firewall delete rule name="Stream Deck Agent"' -Verb RunAs -WindowStyle Hidden -Wait
} catch {
  Write-Warning 'Regra de Firewall não removida (permissão negada).'
}
Write-Host 'Agente parado e removido do início automático.'
