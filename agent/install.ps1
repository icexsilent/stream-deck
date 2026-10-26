# Instala o agente: início automático com o Windows, atalhos, regra de Firewall.
# Pacote (StreamDeck-PC.zip): copia tudo para %LOCALAPPDATA%\StreamDeck e usa o Node que vem junto.
# Repositório (desenvolvimento): roda desta pasta e usa o Node instalado.
# Uso: duplo clique em "Instalar Stream Deck.bat", ou powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'
$port = 3000
$bundledNode = Join-Path (Split-Path $PSScriptRoot) 'node\node.exe'

function Stop-Agent {
  Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($_.OwningProcess)"
    if ($p.Name -eq 'node.exe' -and $p.CommandLine -like '*server.js*') { Stop-Process -Id $p.ProcessId -Force; Start-Sleep -Milliseconds 500 }
  }
}

Write-Host '1/5 Preparando arquivos...'
Stop-Agent
if (Test-Path $bundledNode) {
  $dest = Join-Path $env:LOCALAPPDATA 'StreamDeck'
  # Updates keep the user's buttons, pairing token and icons.
  robocopy (Split-Path $PSScriptRoot) $dest /E /NFL /NDL /NJH /NJS /NP /XF buttons.json .token agent.log /XD (Join-Path $PSScriptRoot 'icons') | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "Falha ao copiar arquivos para $dest" }
  $agent = Join-Path $dest 'app'
  $node = Join-Path $dest 'node\node.exe'
} else {
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js não encontrado. Use o StreamDeck-PC.zip da página de Releases, ou instale o Node em https://nodejs.org.' }
  $agent = $PSScriptRoot
  $node = (Get-Command node).Source
  Push-Location $agent
  try { npm install --omit=dev --no-audit --no-fund | Out-Null; if ($LASTEXITCODE) { throw 'npm install falhou' } } finally { Pop-Location }
}

Write-Host '2/5 Configurando para iniciar com o Windows...'
# VBScript starts node with no console window; output goes to agent.log for troubleshooting.
$cmd = 'cmd /c ""' + $node + '" server.js > agent.log 2>&1"'
$vbs = Join-Path ([Environment]::GetFolderPath('Startup')) 'Stream Deck Agent.vbs'
@"
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "$agent"
sh.Run "$($cmd.Replace('"', '""'))", 0, False
"@ | Set-Content -Encoding ASCII $vbs

Write-Host '3/5 Criando atalhos "Stream Deck" (editor) e "Stream Deck - Parear"...'
& (Join-Path $agent 'shortcut.ps1')
"[InternetShortcut]`r`nURL=http://localhost:$port/pair" | Set-Content -Encoding ASCII (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Stream Deck - Parear.url')

Write-Host '4/5 Liberando no Firewall (redes privadas)...'
$rule = "netsh advfirewall firewall delete rule name=`"Stream Deck Agent`" >nul 2>&1 & " +
        "netsh advfirewall firewall add rule name=`"Stream Deck Agent`" dir=in action=allow program=`"$node`" profile=private enable=yes"
try {
  Start-Process cmd -ArgumentList "/c $rule" -Verb RunAs -WindowStyle Hidden -Wait
} catch {
  Write-Warning 'Firewall não liberado (permissão de administrador negada). Se o celular não conectar, rode o instalador de novo e clique em Sim.'
}

Write-Host '5/5 Iniciando...'
Start-Process wscript -ArgumentList "`"$vbs`""
Start-Sleep -Seconds 3
Start-Process "http://localhost:$port/pair"
Write-Host "`nPronto! O Stream Deck está rodando e vai iniciar sozinho com o Windows."
Write-Host '1. Instale o app no celular (veja o README).'
Write-Host '2. Leia o QR code que abriu no navegador.'
Write-Host '3. Para criar botões, abra o atalho "Stream Deck" na Área de Trabalho.'
