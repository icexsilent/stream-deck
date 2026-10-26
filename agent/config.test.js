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
  assert.throws(() => validate({ pages: [] }), /pelo menos uma página/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'hotkey', keys: 'ctrl+banana' }])), /banana/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'rm' }])), /tipo/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'open', target: 'x' }, { id: 'a', label: 'B', type: 'open', target: 'y' }])), /repetido/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'obs', action: 'scene' }])), /cena/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'open', target: 'x', color: 'red' }])), /cor/);
  assert.throws(() => validate({ columns: 0, ...page([]) }), /columns/);
});

test('ícones, jogos, páginas e jogos ocultos', () => {
  const c = validate({ hiddenGames: ['steam-1', 'steam-1'], pages: [
    { name: 'P', buttons: [
      { id: 'a', label: 'A', type: 'game', game: 'steam-730', icon: 'game-steam-730.jpg' },
      { id: 'b', label: 'B', type: 'page', page: 'Jogos' },
    ] },
    { name: 'Jogos', auto: true, buttons: [{ id: 'x', label: 'X', type: 'game', game: 'steam-9' }] },
  ] });
  assert.strictEqual(c.pages.length, 1); // página automática não é salva
  assert.strictEqual(c.pages[0].buttons[0].icon, 'game-steam-730.jpg');
  assert.deepStrictEqual(c.hiddenGames, ['steam-1']);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'open', target: 'x', icon: '../server.js' }])), /ícone/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'open', target: 'a" & del' }])), /aspas/);
  assert.throws(() => validate(page([{ id: 'a', label: 'A', type: 'game' }])), /jogo/);
  assert.throws(() => validate({ pages: [{ name: 'J', auto: true, buttons: [] }] }), /página sua/);
});

test('features: padrão novo, migração e liga/desliga da página OBS', () => {
  const { applyFeatures } = require('./config');
  const fresh = validate(require('./buttons.example.json'));
  assert.deepStrictEqual([fresh.features, fresh.setupDone, fresh.pages.map((p) => p.name)], [{ games: false, obs: false, widgets: false }, false, ['Principal']]);
  const legacy = validate({ pages: [{ name: 'P', buttons: [] }, { name: 'OBS', buttons: [{ id: 'o', label: 'O', type: 'obs', action: 'toggleStream' }] }] });
  assert.deepStrictEqual([legacy.features, legacy.setupDone, legacy.pages[1].template], [{ games: true, obs: true, widgets: false }, true, 'obs']);
  const on = validate(applyFeatures(fresh, { obs: true }));
  assert.deepStrictEqual([on.pages.map((p) => p.name), on.setupDone], [['Principal', 'OBS'], true]);
  assert.strictEqual(validate(applyFeatures(on, { obs: true })).pages.length, 2); // não duplica
  assert.deepStrictEqual(validate(applyFeatures(on, { obs: false })).pages.map((p) => p.name), ['Principal']);
});

test('Preset do Criador é válido e não leva senha nem caminho pessoal', () => {
  const preset = require('./presets/creator.json');
  const c = validate({ ...preset.config, setupDone: true });
  assert.ok(c.pages.length > 0);
  const text = JSON.stringify(preset);
  assert.ok(!/password/i.test(text));
  assert.ok(!text.includes(require('node:os').userInfo().username + '\\'), 'caminho com o nome do usuário');
});
