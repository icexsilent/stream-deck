const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const plugins = require('./plugins');
const { validate } = require('./config');

test('carrega os plugins que vêm junto', () => {
  assert.deepStrictEqual(plugins.loadAll(), []);
  const ids = plugins.list().map((p) => p.id).sort();
  assert.deepStrictEqual(ids, ['texto', 'webhook']);
});

test('webhook chama a URL com o corpo e reclama de erro HTTP', async () => {
  let got;
  const srv = http.createServer((req, res) => {
    let body = '';
    req.on('data', (c) => (body += c));
    req.on('end', () => { got = { method: req.method, type: req.headers['content-type'], body }; res.writeHead(req.url === '/ruim' ? 500 : 200).end(); });
  }).listen(0);
  const url = `http://127.0.0.1:${srv.address().port}`;
  await plugins.run({ plugin: 'webhook', action: 'call', params: { url: url + '/ok', body: '{"a":1}' } }, {});
  assert.deepStrictEqual(got, { method: 'POST', type: 'application/json', body: '{"a":1}' });
  await assert.rejects(plugins.run({ plugin: 'webhook', action: 'call', params: { url: url + '/ruim' } }, {}), /500/);
  srv.close();
});

test('texto usa o teclado do agente e campos obrigatórios são cobrados', async () => {
  const typed = [];
  const ctx = { typeText: (t) => typed.push(t), pressKeys: (k) => typed.push(`<${k}>`) };
  await plugins.run({ plugin: 'texto', action: 'type', params: { text: 'olá 🎮', enter: 'sim' } }, ctx);
  assert.deepStrictEqual(typed, ['olá 🎮', '<enter>']);
  await assert.rejects(plugins.run({ plugin: 'texto', action: 'type', params: {} }, ctx), /Texto/);
  await assert.rejects(plugins.run({ plugin: 'nao-existe', action: 'x' }, ctx), /não está instalado/);
});

test('botão de plugin é validado', () => {
  const ok = validate({ pages: [{ name: 'P', buttons: [{ id: 'a', label: 'A', type: 'plugin', plugin: 'webhook', action: 'call', params: { url: 'https://x' } }] }] });
  assert.deepStrictEqual(ok.pages[0].buttons[0].params, { url: 'https://x' });
  assert.throws(() => validate({ pages: [{ name: 'P', buttons: [{ id: 'a', label: 'A', type: 'plugin', plugin: '../x', action: 'call' }] }] }), /ação do plugin/);
  assert.throws(() => validate({ pages: [{ name: 'P', buttons: [{ id: 'a', label: 'A', type: 'plugin', plugin: 'w', action: 'c', params: { a: { b: 1 } } }] }] }), /inválido/);
});
