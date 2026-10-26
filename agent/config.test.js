const test = require('node:test');
const assert = require('node:assert');
const { validate } = require('./config');

const page = (buttons) => ({ pages: [{ name: 'P', buttons }] });

test('aceita config válida e descarta campos extras', () => {
  const c = validate({ columns: 4, pages: [{ name: ' Live ', buttons: [
    { id: 'a', label: 'A', type: 'hotkey', keys: 'ctrl+a', color: '#ff0000', junk: 1 },
    { id: 'b', label: 'B', type: 'obs', action: 'scene', name: 'Jogo' },
    { id: 'c', label: 'C', type: 'obs', action: 'toggleStream' },
    { id: 'd', label: 'D', type: 'open', target: 'calc.exe' },
  ] }] });
  assert.strictEqual(c.pages[0].name, 'Live');
  assert.deepStrictEqual(c.pages[0].buttons[0], { id: 'a', label: 'A', type: 'hotkey', color: '#ff0000', keys: 'ctrl+a' });
  assert.strictEqual(c.columns, 4);
});

test('migra o formato antigo da Fase 1', () => {
  const c = validate({ buttons: [{ id: 'a', label: 'A', type: 'hotkey', keys: 'f1' }] });
  assert.strictEqual(c.pages[0].name, 'Principal');
  assert.strictEqual(c.columns, 3);
});

test('rejeita configs ruins', () => {
  assert.throws(() => validate({ pages: [] }), /pelo menos uma/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'hotkey', keys: 'ctrl+banana' }])), /banana/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'rm' }])), /tipo/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'open', target: 'x' }, { id: 'a', label: 'B', type: 'open', target: 'y' }])), /repetido/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'obs', action: 'scene' }])), /cena/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'open', target: 'x', color: 'red' }])), /cor/);
  assert.throws(() => validate({ columns: 0, ...page([]) }), /columns/);
});
