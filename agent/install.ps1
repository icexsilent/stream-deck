# Instala o agente: dependências, início automático com o Windows, atalho de pareamento e regra de Firewall.
# Uso: powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'
$agent = $PSScriptRoot
$startup = [Environment]::GetFolderPath('Startup')
$desktop = [Environment]::GetFolderPath('Desktop')
$port = 3000

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js não encontrado. Instale em https://nodejs.org e rode de novo.' }

Write-Host '1/4 Instalando dependências...'
Push-Location $agent
try { npm install --omit=dev --no-audit --no-fund | Out-Null; if ($LASTEXITCODE) { throw 'npm install falhou' } } finally { Pop-Location }

Write-Host '2/4 Configurando para iniciar com o Windows...'
# Stop a running copy first so the new one can take the port.
Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
  $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($_.OwningProcess)"
  if ($p.Name -eq 'node.exe' -and $p.CommandLine -like '*server.js*') { Stop-Process -Id $p.ProcessId -Force }
}
# VBScript runs node with no console window; output goes to agent.log for troubleshooting.
$vbs = Join-Path $startup 'Stream Deck Agent.vbs'
@"
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "$agent"
sh.Run "cmd /c node server.js > agent.log 2>&1", 0, False
"@ | Set-Content -Encoding ASCII $vbs

Write-Host '3/4 Criando atalhos "Stream Deck" (editor) e "Stream Deck - Parear"...'
& (Join-Path $agent 'shortcut.ps1')
"[InternetShortcut]`r`nURL=http://localhost:$port/pair" | Set-Content -Encoding ASCII (Join-Path $desktop 'Stream Deck - Parear.url')

Write-Host '4/4 Liberando no Firewall (redes privadas)...'
$node = (Get-Command node).Source
$rule = "netsh advfirewall firewall delete rule name=`"Stream Deck Agent`" >nul 2>&1 & " +
        "netsh advfirewall firewall add rule name=`"Stream Deck Agent`" dir=in action=allow program=`"$node`" profile=private enable=yes"
try {
  Start-Process cmd -ArgumentList "/c $rule" -Verb RunAs -WindowStyle Hidden -Wait
} catch {
  Write-Warning 'Firewall não liberado (permissão de administrador negada). Se o celular não conectar, rode este script de novo e clique em Sim.'
}

Start-Process wscript -ArgumentList "`"$vbs`""
Start-Sleep -Seconds 2
Start-Process "http://localhost:$port/pair"
Write-Host "`nPronto. O agente está rodando e vai iniciar sozinho com o Windows."
Write-Host 'Leia o QR code que abriu no navegador com o app do celular.'
