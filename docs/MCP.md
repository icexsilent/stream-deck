# Controlar o Stream Deck por um assistente de IA (MCP)

O Stream Deck tem um servidor **MCP** (o padrão aberto que Claude Code, Goose e OpenCode usam para ferramentas). Com ele você pede, em português normal:

- "cria um botão na Principal que abre o Spotify"
- "faz uma página Live com botões de cena do OBS"
- "aperta o botão de mutar o mic"
- "desfaz isso"

Toda mudança feita pela IA vai para o **🕘 Histórico** e pode ser desfeita.

## Qual caminho usar

O servidor é o arquivo `mcp.js` dentro da pasta do Stream Deck. O PC precisa estar com o Stream Deck rodando.

| Instalação | Comando |
|---|---|
| Pelo `StreamDeck-PC.zip` | `%LOCALAPPDATA%\StreamDeck\node\node.exe` com o argumento `%LOCALAPPDATA%\StreamDeck\app\mcp.js` |
| Pelo código (repositório) | `node` com o argumento `C:\caminho\stream-deck\agent\mcp.js` |

Nos exemplos abaixo, troque o caminho pelo seu.

## Claude Code

```powershell
claude mcp add --scope user stream-deck -- node E:\ICEX\StreamDeck\agent\mcp.js
```

Abra uma sessão nova e peça: "lista meus botões do Stream Deck".

## Goose

App: **Settings → Extensions → Add custom extension**:

- Type: **STDIO**
- Name: `stream-deck`
- Command: `node E:\ICEX\StreamDeck\agent\mcp.js`

Terminal: rode `goose configure` → **Add Extension** → **Command-line Extension** e use o mesmo comando.

## OpenCode

No arquivo `%USERPROFILE%\.config\opencode\opencode.json`:

```json
{
  "mcp": {
    "stream-deck": {
      "type": "local",
      "command": ["node", "E:\\ICEX\\StreamDeck\\agent\\mcp.js"],
      "enabled": true
    }
  }
}
```

## Ferramentas disponíveis

| Ferramenta | O que faz |
|---|---|
| `listar_botoes` | páginas, botões, jogos detectados, plugins e configurações |
| `criar_botao` | cria um botão numa página (qualquer tipo: atalho, programa, jogo, OBS, widget, plugin…) |
| `editar_botao` | muda campos de um botão |
| `apagar_botao` | apaga um botão |
| `criar_pagina` | cria uma página vazia |
| `apertar_botao` | executa um botão no PC |
| `desfazer` | volta a última mudança |

## Testar sem IA

```powershell
cd agent
'{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node mcp.js
```
