# Plugins

Um plugin adiciona ações novas ao Stream Deck sem mexer no programa. Ele aparece na ação **Plugin** do editor (PC e celular), com o formulário montado a partir do próprio plugin.

Vêm dois de exemplo: **Webhook** (chama uma URL: Home Assistant, IFTTT, Discord…) e **Texto** (digita um texto pronto).

## Instalar um plugin

1. Copie a pasta do plugin para a pasta `plugins` do Stream Deck:
   - instalado pelo zip: `%LOCALAPPDATA%\StreamDeck\app\plugins`
   - pelo código: `agent\plugins`
2. Reinicie o PC (ou rode o instalador de novo).
3. Confira em **⚙️ Configurações → Plugins** no editor.

Plugins rodam código no seu PC. Só instale plugins de quem você confia.

## Criar um plugin

Uma pasta com dois arquivos. O nome da pasta é o `id`.

`plugins/ola/plugin.json`: o que o editor mostra.

```json
{
  "id": "ola",
  "name": "Olá",
  "description": "Exemplo mínimo.",
  "version": "1.0.0",
  "actions": {
    "dizer": {
      "label": "Dizer olá",
      "description": "Digita uma saudação.",
      "fields": [
        { "key": "nome", "label": "Nome", "type": "text", "required": true },
        { "key": "jeito", "label": "Jeito", "type": "select", "options": ["oi", "olá"], "default": "olá" }
      ]
    }
  }
}
```

- **Tipos de campo:** `text`, `textarea`, `number`, `select` (com `options`), `file` (botão Procurar… no editor; `filter` opcional no formato do Windows, ex. `"Sons (*.mp3)|*.mp3"`).
- `required` faz o Stream Deck cobrar o campo. `default` é usado quando o botão não preencheu o campo.

`plugins/ola/index.js`: o que roda quando a tecla é tocada.

```js
module.exports = {
  actions: {
    async dizer({ nome, jeito }, ctx) {
      ctx.typeText(`${jeito}, ${nome}!`);
    },
  },
};
```

- Cada ação recebe os campos preenchidos no botão e um `ctx` com:
  - `ctx.typeText(texto)`: digita onde o cursor estiver
  - `ctx.pressKeys('ctrl+shift+m')`: aperta um atalho
  - `ctx.open('calc.exe')`: abre um programa, arquivo ou site
- Para mostrar um erro na tecla, lance um erro: `throw new Error('mensagem')`. Ela aparece no celular.
- Tem `fetch` disponível (Node 24) para falar com APIs.
