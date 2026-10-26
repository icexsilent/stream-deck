const test = require('node:test');
const assert = require('node:assert');
const { toVks } = require('./keys');

test('converte combos em virtual-keys', () => {
  assert.deepStrictEqual(toVks('ctrl+shift+m'), [0x11, 0x10, 0x4d]);
  assert.deepStrictEqual(toVks('F1'), [0x70]);
  assert.deepStrictEqual(toVks('f24'), [0x87]);
  assert.deepStrictEqual(toVks('win + 5'), [0x5b, 0x35]);
  assert.deepStrictEqual(toVks('volumeup'), [0xaf]);
});

test('rejeita teclas desconhecidas', () => {
  assert.throws(() => toVks('ctrl+banana'), /banana/);
  assert.throws(() => toVks('f25'));
});
