const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

process.env.SD_DATA_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'sd-hist-'));
const config = require('./config');
const page = (n) => ({ pages: [{ name: 'P', buttons: Array.from({ length: n }, (_, i) => ({ id: `b${i}`, label: 'B', type: 'open', target: 'calc.exe' })) }] });

test('cada mudança guarda a versão anterior e dá para voltar', () => {
  config.save(page(1), 'pc');
  config.save(page(2), 'celular');
  config.save(page(3), 'pc');
  const h = config.history();
  assert.deepStrictEqual(h.map((x) => x.buttons), [2, 1]); // a mais nova primeiro
  assert.strictEqual(h[0].source, 'uma mudança no editor do PC');
  assert.strictEqual(h[1].source, 'uma mudança no celular');
  const back = config.restore(h[0].id);
  assert.strictEqual(back.pages[0].buttons.length, 2);
  assert.strictEqual(config.history()[0].buttons, 3); // a restauração também pode ser desfeita
});

test('guarda só as 30 últimas e recusa id estranho', () => {
  for (let i = 0; i < 35; i++) config.save(page(1), 'pc');
  assert.strictEqual(config.history().length, 30);
  assert.throws(() => config.restore('../buttons'), /inválida/);
  assert.throws(() => config.restore('1-pc'), /não existe/);
});

test('desfazer várias vezes volta passo a passo', () => {
  for (let n = 1; n <= 4; n++) config.save(page(n), 'pc');
  const count = () => JSON.parse(fs.readFileSync(path.join(process.env.SD_DATA_DIR, 'buttons.json'), 'utf8')).pages[0].buttons.length;
  assert.strictEqual(count(), 4);
  config.undo(); assert.strictEqual(count(), 3);
  config.undo(); assert.strictEqual(count(), 2);
  config.undo(); assert.strictEqual(count(), 1);
});
