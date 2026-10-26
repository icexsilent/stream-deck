const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { parseVdfPaths, parseAcf, scanEpic, scanRiot } = require('./games');

test('lê bibliotecas e manifestos da Steam', () => {
  const vdf = '"libraryfolders"\n{\n "0"\n {\n  "path"\t\t"C:\\\\Program Files (x86)\\\\Steam"\n }\n "1" { "path" "F:\\\\SteamLibrary" }\n}';
  assert.deepStrictEqual(parseVdfPaths(vdf), ['C:\\Program Files (x86)\\Steam', 'F:\\SteamLibrary']);
  assert.deepStrictEqual(parseAcf('"AppState"\n{\n\t"appid"\t\t"730"\n\t"name"\t\t"Counter-Strike 2"\n\t"StateFlags"\t\t"4"\n}'), { appid: '730', name: 'Counter-Strike 2', stateFlags: 4 });
});

test('lê manifestos da Epic e ignora instalação incompleta', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'epic-'));
  fs.writeFileSync(path.join(dir, 'a.item'), JSON.stringify({ DisplayName: 'GTA V', AppName: 'abc', CatalogNamespace: 'ns', CatalogItemId: 'it', InstallLocation: 'C:\\G', LaunchExecutable: 'g.exe' }));
  fs.writeFileSync(path.join(dir, 'b.item'), JSON.stringify({ DisplayName: 'Meio baixado', AppName: 'x', bIsIncompleteInstall: true }));
  const games = scanEpic(dir);
  assert.strictEqual(games.length, 1);
  assert.strictEqual(games[0].launch.uri, 'com.epicgames.launcher://apps/ns%3Ait%3Aabc?action=launch&silent=true');
});

test('lê jogos da Riot só se estiverem instalados', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'riot-'));
  const install = fs.mkdtempSync(path.join(os.tmpdir(), 'lol-'));
  fs.writeFileSync(path.join(root, 'RiotClientInstalls.json'), JSON.stringify({ rc_default: 'C:/Riot/RiotClientServices.exe' }));
  for (const [d, p] of [['league_of_legends.live', install], ['valorant.live', 'C:/nao/existe']]) {
    fs.mkdirSync(path.join(root, 'Metadata', d), { recursive: true });
    fs.writeFileSync(path.join(root, 'Metadata', d, `${d}.product_settings.yaml`), `product_install_full_path: "${p.replace(/\\/g, '/')}"\n`);
  }
  const games = scanRiot(root);
  assert.deepStrictEqual(games.map((g) => g.label), ['League of Legends']);
  assert.deepStrictEqual(games[0].launch.args, ['--launch-product=league_of_legends', '--launch-patchline=live']);
});
