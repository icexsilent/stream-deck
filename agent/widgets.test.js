const test = require('node:test');
const assert = require('node:assert');
const { value, press, state, collect } = require('./widgets');

test('cronômetro: inicia, pausa, acaba e zera', (t) => {
  const b = { id: 't1', type: 'widget', widget: 'timer', minutes: 1 };
  assert.strictEqual(value(b).text, '1:00');
  t.mock.timers.enable({ apis: ['Date'], now: 0 });
  press(b, false); // inicia
  t.mock.timers.tick(15_000);
  assert.strictEqual(value(b).text, '0:45');
  press(b, false); // pausa
  t.mock.timers.tick(30_000);
  assert.strictEqual(value(b).text, '0:45');
  press(b, false); // continua
  t.mock.timers.tick(60_000);
  assert.ok(value(b).alert);
  press(b, false); // acabou: toque zera
  assert.strictEqual(value(b).text, '1:00');
  t.mock.timers.reset();
});

test('contador soma no toque e zera segurando', () => {
  const b = { id: 'c1', type: 'widget', widget: 'counter' };
  press(b, false); press(b, false); press(b, false);
  assert.strictEqual(value(b).text, '3');
  press(b, true);
  assert.strictEqual(value(b).text, '0');
  state.clear();
});

test('relógio, CPU e RAM têm valor; música manda tecla de mídia', () => {
  const v = collect([{ id: 'a', widget: 'clock' }, { id: 'b', widget: 'cpu' }, { id: 'c', widget: 'ram' }]);
  assert.match(v.a.text, /^\d{2}:\d{2}$/);
  assert.match(v.b.text, /^\d+%$/);
  assert.ok(v.c.progress > 0 && v.c.progress <= 1);
  assert.strictEqual(press({ widget: 'media' }, false), 'playpause');
  assert.strictEqual(press({ widget: 'media' }, true), 'next');
});
