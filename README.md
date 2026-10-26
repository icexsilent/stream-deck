# Stream Deck pelo Wi-Fi

App no celular (Android, depois iOS) que controla o PC pela rede local, sem cabos.

## Rodar o agente (PC com Windows)

```bash
cd agent
npm install
npm start
```

1. O terminal mostra um link `http://192.168.x.x:3000/?t=...`
2. Abra esse link no navegador do celular (mesmo Wi-Fi)
3. Na primeira vez, o Windows pergunta sobre o Firewall: permita em **Redes privadas**

## Configurar botões

Edite `agent/buttons.json` e reinicie o agente.

- `"type": "hotkey"`, `"keys": "ctrl+shift+m"`: aperta um atalho. Teclas: `ctrl shift alt win`, `a-z`, `0-9`, `f1-f24`, `enter esc space tab`, `up down left right`, `volumeup volumedown mute`, `playpause next prev printscreen`
- `"type": "open"`, `"target": "calc.exe"`: abre um programa, arquivo ou URL

O celular só envia o `id` do botão. O que cada botão faz fica no PC.

## Segurança

O agente gera um token em `agent/.token` (fora do git). Sem o token, a conexão é recusada. Para trocar o token, apague o arquivo e reinicie.

## Plano

- [x] **Fase 1:** agente no PC + controle pelo navegador
- [ ] **Fase 2:** app Android em Flutter
- [ ] **Fase 3:** pareamento por QR code + descoberta automática (mDNS) + reconexão
- [ ] **Fase 4:** editor de botões, perfis, OBS, ícone na bandeja, instalador
- [ ] **Fase 5:** iOS (Codemagic + TestFlight) e publicação nas lojas

## Protocolo (WebSocket, `ws://PC:3000/?t=TOKEN`)

| Direção | Mensagem |
|---|---|
| PC → celular | `{"type":"buttons","buttons":[{"id","label"}]}` |
| celular → PC | `{"type":"press","id":"mic"}` |
| PC → celular | `{"type":"ok","id":"mic"}` ou `{"type":"error","id","error"}` |
