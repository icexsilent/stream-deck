# Stream Deck pelo Wi-Fi

App no celular (Android, e depois iOS) que controla o PC pela rede local, sem cabos.

- `agent/`: programa que roda no PC com Windows (Node.js)
- `app/`: app do celular (Flutter)

## Instalar no PC (uma vez)

```powershell
cd C:\Users\vinic\projetos\stream-deck\agent
powershell -ExecutionPolicy Bypass -File install.ps1
```

1. Clique em **Sim** quando o Windows pedir permissão. É para liberar o Firewall nas redes privadas.
2. O navegador abre o QR code de pareamento.
3. O agente passa a iniciar sozinho com o Windows. Para abrir o QR de novo, use o atalho **Stream Deck - Parear** na Área de Trabalho.

Para remover: `powershell -ExecutionPolicy Bypass -File uninstall.ps1`.
Para rodar sem instalar: `npm install` e depois `npm start`.

## Instalar no celular (Android)

1. Copie `app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` para o celular, ou baixe o APK na aba Releases do GitHub.
2. Abra o arquivo e permita "instalar apps desconhecidos".
3. Abra o app e leia o QR code do PC.

Sem o app, também dá para usar pelo navegador: leia o QR com a câmera do celular.

## Editor no PC

Abra o atalho **Stream Deck** na Área de Trabalho ou no Menu Iniciar (o agente precisa estar rodando). Ele abre numa janela própria, e também em http://localhost:3000/editor.

- **Páginas** à esquerda, **botões** no meio, **propriedades** à direita.
- **+** cria um botão. Arraste para reordenar. `Delete` apaga e `Ctrl+S` salva.
- Cada botão tem texto, imagem (envie PNG ou JPG), cor e ação: atalho (o **⏺ Gravar** captura as teclas), abrir programa ou site, abrir jogo, OBS, ir para outra página.
- **🎮 Jogos:** página automática com os jogos instalados (Steam, Epic, Riot, Xbox), com capa. Desmarque os que não quer ver. **Procurar jogos** atualiza a lista.
- **📱 Parear celular** mostra o QR code.

Se o atalho sumir, recrie com `powershell -ExecutionPolicy Bypass -File agent\shortcut.ps1`.

## Usar

- **Tocar num botão:** executa a ação no PC.
- **✏️ no topo:** modo edição. Toque num botão para mudar texto, cor e ação. **+** adiciona botão ou página, as setas reordenam, e segurar uma página renomeia ou apaga. **✓** salva no PC.
- **Ações:** atalho de teclado, abrir programa/arquivo/site, abrir jogo, ir para outra página, e OBS (live, gravação, trocar cena, mutar fonte).
- **🎮 Jogos:** aba com todos os jogos do PC. Tocar abre o jogo.
- Se o IP do PC mudar, o app acha o PC sozinho na rede (mDNS).

### OBS

1. No OBS, abra **Ferramentas > Configurações do Servidor WebSocket**, ative o servidor e copie a senha.
2. No PC, coloque a senha em `agent/buttons.json`, em `"obs": { "url": "ws://127.0.0.1:4455", "password": "..." }`.
3. Reinicie o agente (rode o `install.ps1` de novo ou reinicie o PC).

A senha do OBS fica só no PC e nunca vai para o celular.

## Segurança

- O QR code carrega um token. Quem tem o token controla o PC, inclusive editando botões que abrem programas, então não compartilhe o QR.
- `agent/buttons.json` (seus botões e a senha do OBS) fica fora do git. O modelo inicial é `buttons.example.json`.
- Para trocar o token: apague `agent/.token`, reinicie o agente e pareie de novo.
- A página `/pair` só abre no próprio PC.

## Desenvolvimento

```bash
cd agent && npm test        # testes do agente
cd app && flutter test      # testes do app
cd app && flutter build apk --release --split-per-abi
```

Flutter está em `C:\Users\vinic\dev\flutter` e o Android SDK em `%LOCALAPPDATA%\Android\Sdk`.

### Protocolo (WebSocket `ws://PC:3000/?t=TOKEN`)

| Direção | Mensagem |
|---|---|
| PC → celular | `{"type":"config","config":{"columns":3,"pages":[{"name","buttons":[...]}]}}` (ao conectar e após salvar) |
| celular → PC | `{"type":"press","id":"mic"}` → `{"type":"ok","id"}` ou `{"type":"error","id","error"}` |
| celular → PC | `{"type":"save","config":{...}}` → `{"type":"saved"}` ou `{"type":"error","error"}` |
| celular → PC | `{"type":"ping"}` → `{"type":"pong"}` (a cada 10 s, detecta Wi-Fi caído) |

## Plano

- [x] **Fase 1:** agente no PC + controle pelo navegador
- [x] **Fase 2:** app Android em Flutter
- [x] **Fase 3:** pareamento por QR code, descoberta automática (mDNS), reconexão
- [x] **Fase 4:** editor de botões, páginas, OBS, início com o Windows, instalador
- [x] **Extra:** editor no PC, aba de jogos automática, imagens nos botões, visual novo
- [ ] **Fase 5:** iOS e lojas. Configuração pronta (`codemagic.yaml`), faltam as contas: veja [docs/PUBLICAR.md](docs/PUBLICAR.md)
