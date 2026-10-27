# Stream Deck pelo Wi-Fi

Transforme o celular num Stream Deck: botões que controlam o PC pela rede Wi-Fi, sem cabos. Atalhos de teclado, abrir programas e jogos, volume, mídia, OBS, Discord e soundboard.

## Sumário

1. [O que você precisa](#1-o-que-você-precisa)
2. [Instalar no PC](#2-instalar-no-pc)
3. [Instalar no celular](#3-instalar-no-celular)
4. [Conferir se está funcionando](#4-conferir-se-está-funcionando)
5. [Criar e editar botões](#5-criar-e-editar-botões)
6. [Discord: mutar, ensurdecer, soundboard e mensagens](#6-discord)
7. [OBS](#7-obs)
8. [Outros recursos](#8-outros-recursos): jogos, widgets, widget da tela inicial, histórico, plugins, preset, IA
9. [Atualizar](#9-atualizar)
10. [Desinstalar](#10-desinstalar)
11. [Problemas comuns](#11-problemas-comuns)
12. [Segurança](#12-segurança)
13. [Para desenvolvedores](#13-para-desenvolvedores)

---

## 1. O que você precisa

- **PC:** Windows 10 ou 11.
- **Celular:** Android 7 ou mais novo. iPhone funciona pelo navegador (veja [iPhone](#iphone)).
- PC e celular **no mesmo Wi-Fi** (ou o PC no cabo e o celular no Wi-Fi do mesmo roteador).
- Não precisa instalar Node.js nem nada antes: o pacote do PC já vem com tudo.

Tudo para baixar fica em **[Releases → última versão](https://github.com/icexsilent/stream-deck/releases/latest)**.

---

## 2. Instalar no PC

1. Baixe o **[StreamDeck-PC.zip](https://github.com/icexsilent/stream-deck/releases/latest/download/StreamDeck-PC.zip)**.
2. Abra a pasta **Downloads**, clique com o botão direito no `StreamDeck-PC.zip` → **Extrair tudo…** → **Extrair**.
   - Não rode o instalador de dentro do zip, ele precisa estar extraído.
3. Na pasta extraída, dê dois cliques em **`Instalar Stream Deck.bat`**.
   - Se aparecer "O Windows protegeu o computador": clique em **Mais informações** → **Executar assim mesmo**.
4. Uma janela preta mostra o progresso em 5 etapas:
   1. Preparando arquivos (copia tudo para `%LOCALAPPDATA%\StreamDeck`)
   2. Configurando para iniciar com o Windows
   3. Criando os atalhos **Stream Deck** e **Stream Deck - Parear** na Área de Trabalho
   4. Liberando no Firewall: **clique em Sim** quando o Windows pedir permissão. Sem isso o celular não conecta.
   5. Iniciando
5. O navegador abre sozinho com um **QR code**. Deixe essa página aberta para o próximo passo.
6. Aperte qualquer tecla para fechar a janela preta.

A partir de agora o Stream Deck liga sozinho toda vez que o Windows inicia, sem janela aberta.

---

## 3. Instalar no celular

### Android

1. No celular, baixe o **[StreamDeck-Android.apk](https://github.com/icexsilent/stream-deck/releases/latest/download/StreamDeck-Android.apk)**.
   - Celular muito antigo (antes de 2017) e o app não instala? Use o **[StreamDeck-Android-antigo.apk](https://github.com/icexsilent/stream-deck/releases/latest/download/StreamDeck-Android-antigo.apk)**.
2. Abra o arquivo baixado (pela notificação ou pelo app **Arquivos → Downloads**).
3. Se aparecer "instalar apps desconhecidos": toque em **Configurações** → ative **Permitir desta fonte** → volte e toque em **Instalar**.
4. Abra o app **Stream Deck** e permita o uso da câmera.
5. Aponte a câmera para o QR code que está aberto no PC.
6. Na primeira vez, o app pergunta se você quer a **aba Jogos** e a **página OBS**. Escolha e pronto (dá para mudar depois em **⋮ → Configurações**).

O pareamento fica salvo. Nas próximas vezes, é só abrir o app: ele encontra o PC sozinho na rede.

### iPhone

Ainda não tem app de iPhone, mas funciona pelo navegador:

1. Abra a **Câmera** do iPhone e aponte para o QR code do PC.
2. Toque no link que aparece. O Stream Deck abre no Safari.
3. Para deixar com cara de app: no Safari, toque em **Compartilhar → Adicionar à Tela de Início**.

---

## 4. Conferir se está funcionando

1. Toque no botão **🧮 Calculadora** no celular: a calculadora deve abrir no PC.
2. Toque em **🔊 Volume +**: o volume do PC sobe.

Se não funcionou, veja [Problemas comuns](#11-problemas-comuns).

Endereços úteis no PC (só funcionam com o Stream Deck rodando):

| Endereço | O que é |
|---|---|
| `http://localhost:3000/editor` | editor de botões (mesmo que o atalho **Stream Deck**) |
| `http://localhost:3000/pair` | QR code de pareamento (mesmo que o atalho **Stream Deck - Parear**) |

---

## 5. Criar e editar botões

### No PC (editor completo)

1. Abra o atalho **Stream Deck** na Área de Trabalho ou no Menu Iniciar.
2. Para criar um botão:
   - **➕ Adicionar programa:** escolha qualquer `.exe` ou atalho. O botão já vem com o nome e o ícone do programa.
   - **+**: cria um botão vazio para você configurar.
3. Clique no botão para editar: **texto**, **imagem**, **cor** e **ação**.
4. Arraste para reordenar. `Delete` apaga o botão selecionado.
5. **`Ctrl+S` salva.** O celular atualiza na hora.

Outras opções do editor:

- **⚙️ Configurações:** aba Jogos, página OBS, página Widgets, plugins e Preset do Criador.
- **📱 Parear celular:** mostra o QR code de novo.
- **🕘 Histórico** e `Ctrl+Z`: desfazem mudanças.

### No celular

1. Toque no **✏️** no topo para entrar no modo edição.
2. Toque num botão para mudar texto, cor e ação.
3. **+** adiciona botão ou página. As setas reordenam. Segurar o nome de uma página renomeia ou apaga.
4. Toque em **Salvar** para mandar para o PC.

### Tipos de ação

| Ação | O que faz | Exemplo |
|---|---|---|
| Atalho de teclado | aperta teclas no PC | `ctrl+shift+m` |
| Abrir | abre programa, arquivo, pasta ou site | `calc.exe`, `C:\Jogos\jogo.exe`, `https://youtube.com` |
| Jogo | abre um jogo detectado (Steam, Epic, Riot, Xbox) | escolha na lista |
| OBS | troca cena, muta fonte, inicia/para live ou gravação | veja [OBS](#7-obs) |
| Página | vai para outra página de botões | "Live" |
| Widget ao vivo | mostra informação que atualiza sozinha | relógio, CPU, música… |
| Plugin | ações extras: Webhook, Texto, Áudio | veja [Plugins](#plugins) |

**Gravar atalho:** no editor do PC, clique em **⏺ Gravar** e aperte as teclas. Ou digite à mão, separando com `+`:

| Teclas aceitas | |
|---|---|
| Modificadores | `ctrl`, `shift`, `alt`, `win` |
| Letras e números | `a` a `z`, `0` a `9` |
| Funções | `f1` a `f24` |
| Especiais | `enter`, `esc`, `space`, `tab`, `backspace`, `up`, `down`, `left`, `right`, `printscreen` |
| Mídia | `volumeup`, `volumedown`, `mute`, `playpause`, `next`, `prev` |

Dica: `f13` a `f24` não existem no teclado comum, então são ótimas para atalhos em programas (Discord, OBS) sem conflitar com nada.

---

## 6. Discord

São quatro coisas que dá para fazer com o Discord. Faça só as que você quiser.

### 6.1 Mutar e ensurdecer pelo celular

O Discord só obedece atalhos que você cadastrar nele. Para funcionar mesmo com o Discord minimizado ou dentro de um jogo:

1. No Discord, abra **Configurações de usuário** (engrenagem ao lado do seu nome) → **Atalhos de teclado** (Keybinds).
2. Clique em **Adicionar um atalho**:
   - Ação: **Ativar/desativar mudo** (Toggle Mute)
   - Atalho: clique em **Gravar atalho** e aperte `Ctrl+Shift+M` (ou `F13`, veja a dica acima)
3. Clique em **Adicionar um atalho** de novo:
   - Ação: **Ativar/desativar ensurdecer** (Toggle Deafen)
   - Atalho: `Ctrl+Shift+D` (ou `F14`)
4. No editor do Stream Deck, crie dois botões com ação **Atalho de teclado**:
   - `🎙️ Mutar mic` → `ctrl+shift+m` (esse já vem pronto nos botões de exemplo)
   - `🎧 Ensurdecer` → `ctrl+shift+d`
5. `Ctrl+S` para salvar. Teste numa chamada.

O mesmo vale para outras ações do Discord (Push to talk, Ativar/desativar câmera, Compartilhar tela…): cadastre o atalho no Discord e use o mesmo atalho no botão.

### 6.2 Soundboard: tocar sons no Discord

O plugin **Áudio** toca um som no seu fone e, ao mesmo tempo, manda para a chamada do Discord. Para isso o Windows precisa de um "cabo de áudio virtual". Configuração feita uma vez só:

**Passo 1: instalar o FFmpeg** (o plugin usa o `ffplay` dele para mandar o som para o Discord)

1. Abra o **PowerShell** (botão direito no Iniciar → **Terminal** ou **Windows PowerShell**).
2. Rode:
   ```powershell
   winget install Gyan.FFmpeg
   ```
3. Feche e abra o PowerShell de novo e confira:
   ```powershell
   ffplay -version
   ```
   Se aparecer a versão, está instalado.
4. **Reinicie o PC.** O Stream Deck liga com o Windows e só enxerga o FFmpeg depois de reiniciar.

**Passo 2: instalar o VB-Cable** (o cabo virtual)

1. Baixe em [vb-audio.com/Cable](https://vb-audio.com/Cable/) (botão **Download**, é grátis).
2. Extraia o zip, clique com o botão direito em **`VBCABLE_Setup_x64.exe`** → **Executar como administrador** → **Install Driver**.
3. Reinicie o PC.
4. Confira se o seu som continua saindo no fone/caixa: clique no ícone de som na barra de tarefas e veja se o dispositivo de saída é o seu fone, **não** o "CABLE Input". Se mudou, troque de volta.

**Passo 3: criar o botão de som**

1. No editor do Stream Deck, crie um botão com ação **Plugin** → **Áudio** → **Tocar som**.
2. **Arquivo de som:** clique em **Procurar…** e escolha um `.mp3`, `.wav` ou `.ogg`.
3. **Volume:** de 0 a 100 (padrão 80).
4. **Onde tocar:**
   - `pc e discord`: você ouve no fone e o Discord também (padrão)
   - `só pc`: só você ouve
   - `só discord`: só a chamada ouve
5. `Ctrl+S`.

**Passo 4: mandar o ffplay para o cabo** (para o som sair no Discord)

1. Use um som **longo** (30 segundos ou mais) para dar tempo, e toque o botão.
2. Enquanto o som toca, abra o mixer:
   - **Windows 11:** **Configurações → Sistema → Som → Mixer de volume**
   - **Windows 10:** **Configurações → Sistema → Som → Preferências de volume do aplicativo e dispositivo**
3. Na linha **ffplay**, mude a **Saída** para **CABLE Input (VB-Audio Virtual Cable)**.

O Windows lembra dessa escolha. Não precisa repetir.

**Passo 5: juntar seu microfone e os sons no Discord**

O Discord só escuta um microfone. Para ele ouvir **sua voz e os sons**, mande o seu microfone também para o cabo:

1. Aperte `Win+R`, digite `mmsys.cpl` e aperte Enter.
2. Aba **Gravação** → clique duas vezes no **seu microfone** → aba **Escutar**.
3. Marque **Escutar este dispositivo** e, em **Reproduzir neste dispositivo**, escolha **CABLE Input (VB-Audio Virtual Cable)** → **OK**.
   - Atenção: escolha o CABLE Input, **não** o seu fone. No fone você ouviria a própria voz.
4. No Discord: **Configurações de usuário → Voz e vídeo → Dispositivo de entrada** → **CABLE Output (VB-Audio Virtual Cable)**.
5. Ainda em Voz e vídeo, clique em **Vamos verificar** e fale: a barra deve mexer. Toque um som pelo celular: a barra também mexe.

Pronto: sua voz e os sons vão juntos para a chamada. O mudo do Discord (6.1) muta os dois.

> Se preferir não mexer no microfone, pule o Passo 5 e deixe o Discord no seu microfone normal: aí os sons só tocam para você.

**Sem o VB-Cable:** o plugin percebe sozinho e toca o som só no PC, uma vez. Os sons não chegam ao Discord.

**Para tirar o VB-Cable depois** (desfaça os Passos 5 e 2, nesta ordem):

1. `Win+R` → `mmsys.cpl` → aba **Gravação** → seu microfone → aba **Escutar** → **desmarque** **Escutar este dispositivo** → **OK**. Sem isso, depois de tirar o cabo, você passa a ouvir a própria voz no fone.
2. No Discord: **Voz e vídeo → Dispositivo de entrada** → volte para o **seu microfone**.
3. **Configurações → Aplicativos → Aplicativos instalados → VBCABLE, The Virtual Audio Cable → Desinstalar**, e reinicie o PC.

### 6.3 Mandar mensagem num canal (webhook)

Um botão que posta uma mensagem num canal do Discord, por exemplo "Estou ao vivo!". Precisa ser administrador do servidor (ou ter permissão de Gerenciar webhooks).

1. No Discord, passe o mouse no canal → **⚙️ Editar canal** → **Integrações** → **Webhooks** → **Novo webhook**.
2. Dê um nome (é o nome que aparece como autor da mensagem) e clique em **Copiar URL do webhook**.
3. No editor do Stream Deck, crie um botão com ação **Plugin** → **Webhook** → **Chamar URL**:
   - **URL:** cole a URL copiada (começa com `https://discord.com/api/webhooks/…`)
   - **Método:** `POST`
   - **Corpo:**
     ```json
     {"content": "🔴 Estou ao vivo! Vem assistir"}
     ```
4. `Ctrl+S` e toque o botão: a mensagem aparece no canal.

Quem tem a URL do webhook consegue postar no canal. Não compartilhe.

### 6.4 Digitar mensagens prontas no chat

Plugin **Texto**: digita um texto onde o cursor estiver (chat do Discord, do jogo, WhatsApp…).

1. Crie um botão com ação **Plugin** → **Texto** → **Digitar texto**.
2. **Texto:** `gg wp! 🎉` (aceita acentos e emoji).
3. **Apertar Enter no final:** `sim` para enviar direto.
4. Clique na caixa de mensagem do Discord e toque o botão no celular.

---

## 7. OBS

1. No OBS, abra **Ferramentas → Configurações do Servidor WebSocket**.
2. Marque **Ativar servidor WebSocket**, clique em **Mostrar informações de conexão** e copie a **senha**. A porta padrão é `4455`.
3. Abra o Bloco de Notas, **Arquivo → Abrir** e cole na barra de endereço:
   ```
   %LOCALAPPDATA%\StreamDeck\app\buttons.json
   ```
4. Procure a linha do `"obs"` (no final do arquivo) e coloque a senha:
   ```json
   "obs": { "url": "ws://127.0.0.1:4455", "password": "SUA_SENHA" }
   ```
5. Salve e reinicie o PC (ou rode o `Instalar Stream Deck.bat` de novo).
6. Ligue a **página OBS** em **⚙️ Configurações** (ou crie botões com a ação **OBS**):
   - **Trocar cena:** digite o nome da cena exatamente como está no OBS
   - **Mutar fonte:** nome da fonte de áudio (ex.: `Mic/Aux`)
   - **Iniciar/parar transmissão** e **Iniciar/parar gravação**

O OBS precisa estar aberto. A senha fica só no PC e nunca vai para o celular.

---

## 8. Outros recursos

### Aba Jogos

1. Ligue em **⚙️ Configurações → Aba Jogos** (PC) ou **⋮ → Configurações** (celular).
2. Os jogos instalados (Steam, Epic, Riot e Xbox) aparecem sozinhos, com capa. Tocar abre o jogo.
3. No editor do PC dá para esconder os jogos que você não quer.

### Widgets ao vivo

Teclas que mostram informação e atualizam a cada segundo. Ligue a **📊 Página Widgets** em Configurações, ou crie uma tecla com a ação **Widget ao vivo**.

| Widget | Mostra | Tocar | Segurar |
|---|---|---|---|
| Relógio | hora e data do PC | — | — |
| CPU / RAM / GPU | uso em %, RAM em GB, temperatura da GPU (NVIDIA) | abre o Gerenciador de Tarefas | — |
| Música | o que está tocando (Spotify, YouTube…) | play/pause | próxima |
| Volume | volume do PC | mudo liga/desliga | — |
| Cronômetro | contagem regressiva (você escolhe os minutos) | inicia/pausa | zera |
| Contador | um número | +1 | zera |
| Clima | temperatura agora na sua cidade | — | — |

### Widget na tela inicial (Android)

Até 6 botões direto na tela inicial do celular, sem abrir o app:

1. No app, **⋮ → Configurações → Widget da tela inicial**.
2. Escolha a página e toque em **Adicionar à tela inicial**.

### Histórico e Desfazer

Antes de cada mudança, o Stream Deck guarda como estava (últimas 30 versões).

- **PC:** `Ctrl+Z` desfaz. O botão **🕘 Histórico** lista as versões para voltar a qualquer uma.
- **Celular:** **⋮ → Configurações → Desfazer última mudança**.

### Plugins

Vêm três prontos: **Webhook** (chama uma URL: Discord, Home Assistant, IFTTT, n8n…), **Texto** (digita um texto pronto) e **Áudio** (soundboard). Veja os usos no [Discord](#6-discord).

Para instalar outro plugin:

1. Copie a pasta do plugin para `%LOCALAPPDATA%\StreamDeck\app\plugins`.
2. Reinicie o PC (ou rode o instalador de novo).
3. Confira em **⚙️ Configurações → Plugins** no editor.

Plugins rodam código no seu PC: só instale de quem você confia. Para criar os seus: [docs/PLUGINS.md](docs/PLUGINS.md).

### Preset do Criador

Os botões e páginas que o criador do app usa, atualizados a cada versão. Em **Configurações → Usar o Preset do Criador**.

Atenção: isso **substitui** todos os seus botões (dá para voltar pelo 🕘 Histórico).

### Assistente de IA (MCP)

Peça para o Claude Code, Goose ou OpenCode "cria um botão que abre o Spotify" e ele cria. Exemplo com o Claude Code, instalado pelo zip:

```powershell
claude mcp add --scope user stream-deck -- "$env:LOCALAPPDATA\StreamDeck\node\node.exe" "$env:LOCALAPPDATA\StreamDeck\app\mcp.js"
```

Abra uma sessão nova e peça "lista meus botões do Stream Deck". Outros assistentes e a lista de ferramentas: [docs/MCP.md](docs/MCP.md).

---

## 9. Atualizar

### PC

1. Baixe o **StreamDeck-PC.zip** novo nos [Releases](https://github.com/icexsilent/stream-deck/releases/latest).
2. Extraia (botão direito → **Extrair tudo…**).
3. Dois cliques no **`Instalar Stream Deck.bat`** da pasta nova e **Sim** no pedido do Firewall.

Seus botões (`buttons.json`), o pareamento (`.token`) e os ícones continuam. O celular reconecta sozinho, sem ler o QR de novo.

Para conferir a versão instalada, abra `%LOCALAPPDATA%\StreamDeck\app\package.json` e veja o campo `"version"`.

### Celular

Baixe o **StreamDeck-Android.apk** novo e instale **por cima** do atual (não desinstale antes, senão perde o pareamento).

---

## 10. Desinstalar

- **PC:** dois cliques em **`Desinstalar Stream Deck.bat`** (na pasta extraída do zip). Remove tudo, **inclusive seus botões**. Para guardar os botões antes, copie o `%LOCALAPPDATA%\StreamDeck\app\buttons.json`.
- **Celular:** desinstale o app normalmente.

---

## 11. Problemas comuns

| Problema | O que fazer |
|---|---|
| Celular não conecta | Confira se os dois estão no mesmo Wi-Fi (Wi-Fi de visitantes isola os aparelhos). Rode o instalador de novo e clique em **Sim** no Firewall. A rede do Windows precisa estar como **Privada**: **Configurações → Rede e Internet → Wi-Fi/Ethernet → (sua rede) → Perfil de rede: Privada**. |
| "Procurando o PC na rede…" | O PC está desligado ou o Stream Deck não está rodando. Reinicie o PC ou rode o instalador de novo. |
| Perdi o QR code | Atalho **Stream Deck - Parear** na Área de Trabalho, **📱 Parear celular** no editor, ou `http://localhost:3000/pair`. |
| Botão de atalho não faz nada no jogo | Alguns jogos rodando como administrador ignoram teclas de programas comuns. Abra o jogo sem "Executar como administrador". |
| Discord não muta | O atalho precisa estar cadastrado em **Discord → Atalhos de teclado** (6.1), igual ao do botão. |
| Som toca só no PC, não no Discord | FFmpeg instalado e PC reiniciado? (`ffplay -version` no PowerShell). O **ffplay** está saindo no **CABLE Input** no mixer? O Discord está com entrada **CABLE Output**? |
| Discord não ouve minha voz | Faltou o Passo 5 do soundboard (**Escutar este dispositivo** → CABLE Input), ou volte o Dispositivo de entrada do Discord para o seu microfone. |
| Ouço minha própria voz | Em `mmsys.cpl` → microfone → Escutar, o destino deve ser **CABLE Input**, não o seu fone. |
| OBS não conecta | OBS aberto, WebSocket ativado e a senha certa no `buttons.json`. Depois de mudar o arquivo, reinicie o PC. |
| Webhook dá erro | A URL precisa começar com `https://`. Erro 401/404: o webhook foi apagado no Discord, crie outro. |

Para ver o que o programa está fazendo, abra `%LOCALAPPDATA%\StreamDeck\app\agent.log` no Bloco de Notas.

---

## 12. Segurança

- O QR code tem uma senha (token) única do seu PC. **Quem tem o QR controla o PC**, então não compartilhe nem mostre em live.
- Tudo acontece na sua rede local. Nada passa pela internet (exceto o que você mandar, como webhooks) e o app não coleta dados.
- Para trocar o token: apague `%LOCALAPPDATA%\StreamDeck\app\.token`, reinicie o PC e pareie o celular de novo.

---

## 13. Para desenvolvedores

### Estrutura

- `agent/`: programa do PC (Node.js). Servidor WebSocket, editor web, detector de jogos, plugins e servidor MCP.
- `app/`: app do celular (Flutter).
- `scripts/`: empacotamento e Preset do Criador.
- `docs/`: [PLUGINS.md](docs/PLUGINS.md), [MCP.md](docs/MCP.md), [PUBLICAR.md](docs/PUBLICAR.md).

### Rodar pelo código

Precisa de [Git](https://git-scm.com/download/win) e [Node.js 24](https://nodejs.org) (para o app: [Flutter](https://docs.flutter.dev/get-started/install/windows)).

```powershell
git clone https://github.com/icexsilent/stream-deck.git
cd stream-deck\agent
npm install
npm start          # roda o agente desta pasta (porta 3000; mude com $env:PORT = '3001')
npm test           # testes do agente
```

Se o Stream Deck instalado estiver rodando, ele já ocupa a porta 3000. Feche antes ou use outra porta.

Para instalar a partir do código (inicia com o Windows usando o Node da sua máquina):

```powershell
powershell -ExecutionPolicy Bypass -File agent\install.ps1
```

App do celular:

```powershell
cd app
flutter pub get
flutter test
flutter run        # com o celular ligado no USB em modo depuração
```

### Gerar uma versão

```powershell
node scripts/update-creator-preset.js                              # Preset do Criador = seus botões atuais
powershell -ExecutionPolicy Bypass -File scripts\package-pc.ps1    # gera dist\StreamDeck-PC.zip
cd app; flutter build apk --release --split-per-abi                # APKs em app\build\app\outputs\flutter-apk
```

Depois crie um Release no GitHub com os arquivos `StreamDeck-PC.zip`, `StreamDeck-Android.apk` e `StreamDeck-Android-antigo.apk` (os nomes precisam ser esses para os links deste README funcionarem).

O APK é assinado com a chave em `C:\Users\vinic\.stream-deck\` (fora do git). **Faça backup dessa pasta**: sem ela os celulares não aceitam atualização. Para iOS e lojas, veja [docs/PUBLICAR.md](docs/PUBLICAR.md).

### Protocolo (WebSocket `ws://PC:3000/?t=TOKEN`)

| Direção | Mensagem |
|---|---|
| PC → celular | `{"type":"config","config":{...}}` ao conectar e a cada mudança |
| celular → PC | `{"type":"press","id":"mic"}` → `{"type":"ok","id"}` ou `{"type":"error","id","error"}` |
| celular → PC | `save`, `setFeatures`, `applyPreset` → `{"type":"saved"}` ou `{"type":"error","error"}` |
| celular → PC | `{"type":"rescan"}` procura jogos de novo; `{"type":"ping"}` → `pong` a cada 10 s |

O PC também se anuncia na rede via mDNS (`_streamdeck._tcp`), por isso o app encontra o PC sem digitar IP.
