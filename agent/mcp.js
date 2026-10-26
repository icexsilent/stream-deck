#!/usr/bin/env node
// MCP server (stdio): lets AI assistants — Claude Code, Goose, OpenCode — read and change the Stream Deck.
// It talks to the running agent over the same local WebSocket the editor uses. Protocol: JSON-RPC 2.0, one message per line.
const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline');

const PORT = Number(process.env.PORT) || 3000;
const DATA = process.env.SD_DATA_DIR || __dirname;
const VERSION = require('./package.json').version;

/** Opens a session with the agent, runs fn(session), closes. Every change is saved in 🕘 Histórico, so it can be undone. */
async function withAgent(fn) {
  let token;
  try { token = fs.readFileSync(path.join(DATA, '.token'), 'utf8').trim(); } catch { throw new Error('Stream Deck não está instalado neste PC (sem .token).'); }
  const ws = new WebSocket(`ws://127.0.0.1:${PORT}/?t=${encodeURIComponent(token)}`);
  const inbox = [];
  const waiters = [];
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    const w = waiters.findIndex((x) => x.match(m));
    if (w >= 0) waiters.splice(w, 1)[0].resolve(m); else inbox.push(m);
  };
  const next = (match, ms = 8000) => {
    const i = inbox.findIndex(match);
    if (i >= 0) return Promise.resolve(inbox.splice(i, 1)[0]);
    return new Promise((resolve, reject) => {
      const t = setTimeout(() => reject(new Error('o Stream Deck não respondeu')), ms);
      waiters.push({ match, resolve: (m) => { clearTimeout(t); resolve(m); } });
    });
  };
  await new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = () => reject(new Error(`o Stream Deck não está rodando (porta ${PORT}). Ligue o PC ou rode o instalador.`));
  });
  try {
    const { config } = await next((m) => m.type === 'config');
    const send = (msg) => ws.send(JSON.stringify(msg));
    // Waits for the agent's answer to a change; errors carry the agent's own message (e.g. a bad hotkey).
    const commit = async (msg) => {
      send(msg);
      const r = await next((m) => m.type === 'saved' || (m.type === 'error' && !m.id));
      if (r.type === 'error') throw new Error(r.error);
    };
    return await fn({ config, send, next, commit });
  } finally {
    ws.close();
  }
}

const userPages = (config) => config.pages.filter((p) => !p.auto);
const findPage = (config, name) => {
  const p = userPages(config).find((x) => x.name.toLowerCase() === String(name ?? '').toLowerCase());
  if (!p) throw new Error(`página "${name}" não existe. Páginas: ${userPages(config).map((x) => x.name).join(', ')}`);
  return p;
};
const findButton = (config, id) => {
  for (const p of userPages(config)) {
    const i = p.buttons.findIndex((b) => b.id === id);
    if (i >= 0) return { page: p, index: i };
  }
  throw new Error(`botão "${id}" não existe. Use listar_botoes para ver os ids.`);
};
const save = (s, config) => s.commit({ type: 'save', source: 'ia', config: { columns: config.columns, pages: userPages(config), hiddenGames: config.hiddenGames ?? [] } });
const newId = () => `ia${Date.now().toString(36)}`;

const BUTTON_HELP = `Botão no formato do Stream Deck: {"label": texto até 40 caracteres (emoji ok), "type": um destes, "color"?: "#rrggbb"}.
Tipos e campos:
- hotkey: "keys" ex. "ctrl+shift+m" (ctrl shift alt win, a-z, 0-9, f1-f24, enter esc space tab, up down left right, volumeup volumedown mute, playpause next prev printscreen)
- open: "target" programa, arquivo ou site (ex. "calc.exe", "C:\\\\Jogos\\\\jogo.exe", "https://youtube.com")
- game: "game" id de um jogo de listar_botoes.jogos
- obs: "action" toggleStream|toggleRecord|scene|toggleMute, e "name" (cena/fonte) para scene e toggleMute
- page: "page" nome da página para onde ir
- widget: "widget" clock|cpu|ram|gpu|media|volume|timer|counter|weather; "minutes" no timer; "city" no weather
- plugin: "plugin" id, "action" id da ação, "params" campos (veja listar_botoes.plugins)`;

const TOOLS = [
  {
    name: 'listar_botoes',
    description: 'Lista as páginas e botões do Stream Deck, os jogos detectados no PC, os plugins instalados e as configurações. Use antes de criar ou editar.',
    inputSchema: { type: 'object', properties: {} },
    run: () => withAgent(async ({ config }) => ({
      colunas: config.columns,
      paginas: userPages(config).map((p) => ({ nome: p.name, botoes: p.buttons })),
      configuracoes: config.features,
      jogos: (config.games ?? []).map(({ id, label, source }) => ({ id, label, source })),
      plugins: config.plugins ?? [],
    })),
  },
  {
    name: 'criar_botao',
    description: `Cria um botão numa página. ${BUTTON_HELP}`,
    inputSchema: {
      type: 'object',
      properties: { pagina: { type: 'string', description: 'Nome da página (ex. "Principal")' }, botao: { type: 'object', description: 'O botão, sem "id"' } },
      required: ['pagina', 'botao'],
    },
    run: ({ pagina, botao }) => withAgent(async (s) => {
      const b = { ...botao, id: newId() };
      findPage(s.config, pagina).buttons.push(b);
      await save(s, s.config);
      return `Botão "${b.label}" criado na página ${pagina} (id ${b.id}). Já aparece no celular.`;
    }),
  },
  {
    name: 'editar_botao',
    description: `Muda campos de um botão existente (só os campos enviados). ${BUTTON_HELP}`,
    inputSchema: {
      type: 'object',
      properties: { id: { type: 'string' }, campos: { type: 'object', description: 'Campos a trocar, ex. {"label": "Live", "color": "#dc2626"}' } },
      required: ['id', 'campos'],
    },
    run: ({ id, campos }) => withAgent(async (s) => {
      const { page, index } = findButton(s.config, id);
      page.buttons[index] = { ...page.buttons[index], ...campos, id };
      await save(s, s.config);
      return `Botão ${id} atualizado.`;
    }),
  },
  {
    name: 'apagar_botao',
    description: 'Apaga um botão pelo id. Dá para desfazer com a ferramenta desfazer.',
    inputSchema: { type: 'object', properties: { id: { type: 'string' } }, required: ['id'] },
    run: ({ id }) => withAgent(async (s) => {
      const { page, index } = findButton(s.config, id);
      const [b] = page.buttons.splice(index, 1);
      await save(s, s.config);
      return `Botão "${b.label}" apagado.`;
    }),
  },
  {
    name: 'criar_pagina',
    description: 'Cria uma página nova, vazia.',
    inputSchema: { type: 'object', properties: { nome: { type: 'string' } }, required: ['nome'] },
    run: ({ nome }) => withAgent(async (s) => {
      if (userPages(s.config).some((p) => p.name.toLowerCase() === nome.toLowerCase())) throw new Error(`já existe a página ${nome}`);
      s.config.pages = [...userPages(s.config), { name: nome, buttons: [] }];
      await save(s, s.config);
      return `Página ${nome} criada.`;
    }),
  },
  {
    name: 'apertar_botao',
    description: 'Aperta um botão, como se tocasse nele no celular (executa a ação no PC).',
    inputSchema: { type: 'object', properties: { id: { type: 'string' } }, required: ['id'] },
    run: ({ id }) => withAgent(async (s) => {
      s.send({ type: 'press', id });
      const r = await s.next((m) => (m.type === 'ok' || m.type === 'error') && m.id === id);
      if (r.type === 'error') throw new Error(r.error);
      return `Botão ${id} apertado.`;
    }),
  },
  {
    name: 'desfazer',
    description: 'Desfaz a última mudança nos botões (vale para mudanças feitas por você, pelo PC ou pelo celular).',
    inputSchema: { type: 'object', properties: {} },
    run: () => withAgent(async (s) => { await s.commit({ type: 'undo' }); return 'Última mudança desfeita.'; }),
  },
];

// ---- JSON-RPC over stdio ----
const reply = (id, result) => process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, result }) + '\n');
const fail = (id, code, message) => process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, error: { code, message } }) + '\n');

async function handle(msg) {
  const { id, method, params } = msg;
  if (id === undefined) return; // notifications (e.g. notifications/initialized) need no answer
  if (method === 'initialize') {
    return reply(id, {
      protocolVersion: params?.protocolVersion ?? '2025-06-18',
      capabilities: { tools: {} },
      serverInfo: { name: 'stream-deck', version: VERSION },
      instructions: 'Controla o Stream Deck pelo Wi-Fi deste PC. Comece com listar_botoes. Toda mudança fica no histórico e pode ser desfeita.',
    });
  }
  if (method === 'ping') return reply(id, {});
  if (method === 'tools/list') return reply(id, { tools: TOOLS.map(({ run, ...t }) => t) });
  if (method === 'tools/call') {
    const tool = TOOLS.find((t) => t.name === params?.name);
    if (!tool) return fail(id, -32602, `ferramenta desconhecida: ${params?.name}`);
    try {
      const out = await tool.run(params.arguments ?? {});
      return reply(id, { content: [{ type: 'text', text: typeof out === 'string' ? out : JSON.stringify(out, null, 2) }] });
    } catch (e) {
      // Tool errors go back to the model as results, so it can fix the input and try again.
      return reply(id, { content: [{ type: 'text', text: `Erro: ${e.message}` }], isError: true });
    }
  }
  return fail(id, -32601, `método não suportado: ${method}`);
}

if (require.main === module) {
  readline.createInterface({ input: process.stdin }).on('line', (line) => {
    if (!line.trim()) return;
    let msg;
    try { msg = JSON.parse(line); } catch { return fail(null, -32700, 'JSON inválido'); }
    handle(msg).catch((e) => fail(msg.id ?? null, -32603, e.message));
  });
}

module.exports = { handle, TOOLS };
