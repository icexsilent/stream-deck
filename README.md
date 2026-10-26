# Stream Deck pelo Wi-Fi

Transforme o celular num Stream Deck: botões que controlam o PC pela rede Wi-Fi, sem cabos. Atalhos de teclado, abrir programas e jogos, volume, mídia e OBS.

- **PC:** Windows 10 ou 11
- **Celular:** Android 7 ou mais novo (iPhone pelo navegador, veja abaixo)
- PC e celular precisam estar **no mesmo Wi-Fi**

## Como baixar e instalar

Tudo fica na página de downloads: **[Releases → última versão](https://github.com/icexsilent/stream-deck/releases/latest)**

### 1. No PC (5 min)

1. Baixe **[StreamDeck-PC.zip](https://github.com/icexsilent/stream-deck/releases/latest/download/StreamDeck-PC.zip)**.
2. Clique com o botão direito no arquivo → **Extrair tudo…** → **Extrair**. Não rode de dentro do zip.
3. Na pasta extraída, dê dois cliques em **`Instalar Stream Deck.bat`**.
   - Se o Windows avisar "O Windows protegeu o computador", clique em **Mais informações** → **Executar assim mesmo**.
4. Clique em **Sim** quando o Windows pedir permissão (é para liberar o Firewall na rede de casa).
5. O navegador abre um **QR code**. Deixe ele aberto.

Pronto: o Stream Deck fica instalado em `%LOCALAPPDATA%\StreamDeck` e liga sozinho junto com o Windows. Não precisa instalar mais nada (o Node.js já vem junto).

### 2. No celular Android (3 min)

1. No celular, baixe **[StreamDeck-Android.apk](https://github.com/icexsilent/stream-deck/releases/latest/download/StreamDeck-Android.apk)**.
   - Celular muito antigo (antes de 2017) e o app não instala? Use o **[StreamDeck-Android-antigo.apk](https://github.com/icexsilent/stream-deck/releases/latest/download/StreamDeck-Android-antigo.apk)**.
2. Abra o arquivo baixado. Se aparecer "instalar apps desconhecidos", toque em **Configurações** → ative **Permitir desta fonte** → volte e toque em **Instalar**.
3. Abra o app **Stream Deck** e aponte a câmera para o QR code do PC.

Na primeira vez, o app pergunta se você quer a **aba Jogos** e a **página OBS**. Dá para mudar depois em **⋮ → Configurações**.

### iPhone

Ainda não tem app de iPhone. Mas funciona pelo navegador: aponte a câmera do iPhone para o QR code do PC e toque no link. Dica: no Safari, **Compartilhar → Adicionar à Tela de Início** deixa com cara de app.

### Atualizar

Baixe a versão nova nos Releases e repita a instalação (PC: rode o `Instalar Stream Deck.bat` novo; celular: instale o APK novo por cima). Seus botões e o pareamento continuam.

### Desinstalar

- **PC:** dois cliques em **`Desinstalar Stream Deck.bat`** (na pasta extraída). Remove tudo, inclusive seus botões.
- **Celular:** desinstale o app normalmente.

## Como usar

### No celular

- **Tocar num botão:** executa a ação no PC.
- **✏️ no topo:** modo edição. Toque num botão para mudar texto, cor e ação. **+** adiciona botão ou página, as setas reordenam, segurar uma página renomeia ou apaga. **Salvar** manda para o PC.
- **⋮ → Configurações:** liga ou desliga a **aba Jogos** e a **página OBS**, e tem o **Preset do Criador**.

### No PC: o editor

Abra o atalho **Stream Deck** na Área de Trabalho ou no Menu Iniciar.

- **➕ Adicionar programa:** escolha qualquer `.exe` ou atalho. O botão já vem com o nome e o ícone do programa.
- **+** cria um botão. Arraste para reordenar. `Delete` apaga e `Ctrl+S` salva.
- Cada botão tem texto, imagem, cor e uma ação: atalho de teclado (o **⏺ Gravar** captura as teclas), abrir programa/arquivo/site, abrir jogo, OBS, ou ir para outra página.
- **⚙️ Configurações:** as mesmas opções do celular.
- **📱 Parear celular:** mostra o QR code de novo.

### Aba Jogos

Quando ligada, mostra sozinha os jogos instalados no PC (Steam, Epic, Riot e Xbox), com capa. Tocar abre o jogo. No editor do PC dá para esconder os jogos que você não quer.

### Preset do Criador

Os botões e páginas que o criador do app usa, atualizados a cada versão. Em **Configurações → Usar o Preset do Criador**. Atenção: isso **substitui** todos os seus botões.

### OBS

1. No OBS, abra **Ferramentas → Configurações do Servidor WebSocket**, ative o servidor e copie a senha.
2. Abra `%LOCALAPPDATA%\StreamDeck\app\buttons.json` no Bloco de Notas e coloque a senha em `"obs": { "url": "ws://127.0.0.1:4455", "password": "SUA_SENHA" }`.
3. Reinicie o PC (ou rode o instalador de novo).

A senha do OBS fica só no PC e nunca vai para o celular.

## Problemas comuns

- **O celular não conecta:** confira se os dois estão no mesmo Wi-Fi. Rode o instalador de novo e clique em **Sim** no pedido do Firewall.
- **"Procurando o PC na rede…":** o PC está desligado, ou o Stream Deck não está rodando. Reinicie o PC.
- **Perdi o QR code:** atalho **Stream Deck - Parear** na Área de Trabalho, ou **📱 Parear celular** no editor.

## Segurança

- O QR code tem uma senha (token) única do seu PC. Quem tem o QR controla o PC, então não compartilhe o QR.
- Tudo acontece na sua rede local. Nada passa pela internet e o app não coleta dados.
- Para trocar o token: apague `%LOCALAPPDATA%\StreamDeck\app\.token`, reinicie o PC e pareie de novo.

---

## Para desenvolvedores

- `agent/`: programa do PC (Node.js). Servidor WebSocket, editor web, detector de jogos.
- `app/`: app do celular (Flutter).
- `scripts/`: empacotamento e Preset do Criador.

```bash
cd agent && npm install && npm start   # roda o agente desta pasta
cd agent && npm test                   # testes do agente
cd app && flutter test                 # testes do app
```

### Gerar uma versão

```powershell
node scripts/update-creator-preset.js                                      # Preset do Criador = seus botões atuais
powershell -ExecutionPolicy Bypass -File scripts\package-pc.ps1            # dist\StreamDeck-PC.zip
cd app; flutter build apk --release --split-per-abi                        # APKs em app\build\app\outputs\flutter-apk
```

O APK é assinado com a chave em `C:\Users\vinic\.stream-deck\` (fora do git; faça backup, sem ela os celulares não aceitam atualização). Para iOS e lojas, veja [docs/PUBLICAR.md](docs/PUBLICAR.md).

### Protocolo (WebSocket `ws://PC:3000/?t=TOKEN`)

| Direção | Mensagem |
|---|---|
| PC → celular | `{"type":"config","config":{...}}` ao conectar e a cada mudança |
| celular → PC | `{"type":"press","id":"mic"}` → `{"type":"ok","id"}` ou `{"type":"error","id","error"}` |
| celular → PC | `save`, `setFeatures`, `applyPreset` → `{"type":"saved"}` ou `{"type":"error","error"}` |
| celular → PC | `{"type":"rescan"}` procura jogos de novo; `{"type":"ping"}` → `pong` a cada 10 s |
