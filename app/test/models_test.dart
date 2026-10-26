import 'package:flutter_test/flutter_test.dart';
import 'package:stream_deck/models.dart';

void main() {
  test('Pairing lê o link do QR code', () {
    final p = Pairing.parse('http://192.168.15.10:3000/?t=abc123')!;
    expect([p.host, p.port, p.token], ['192.168.15.10', 3000, 'abc123']);
    expect(Pairing.parse(p.toString())!.token, 'abc123');
    expect(Pairing.parse('http://10.0.0.2/?t=x')!.port, 3000);
  });

  test('Pairing rejeita links sem token ou de outro tipo', () {
    expect(Pairing.parse('http://192.168.0.2:3000/'), isNull);
    expect(Pairing.parse('https://exemplo.com/?t=x'), isNull);
    expect(Pairing.parse('qualquer coisa'), isNull);
  });

  test('DeckButton só envia os campos do tipo escolhido', () {
    final b = DeckButton(id: 'a', label: 'A', type: 'hotkey', keys: 'f1', target: 'sobra.exe');
    expect(b.toJson(), {'id': 'a', 'label': 'A', 'type': 'hotkey', 'keys': 'f1'});
    b
      ..type = 'obs'
      ..action = 'scene'
      ..name = 'Jogo';
    expect(b.toJson(), {'id': 'a', 'label': 'A', 'type': 'obs', 'action': 'scene', 'name': 'Jogo'});
  });

  test('DeckConfig vai e volta igual ao JSON do agente', () {
    final json = {
      'columns': 4,
      'pages': [
        {'name': 'P', 'buttons': [{'id': 'x', 'label': 'X', 'type': 'open', 'target': 'calc.exe', 'color': '#ff0000'}]}
      ]
    };
    expect(DeckConfig.fromJson(json).toJson(), {
      'columns': 4,
      'pages': [
        {'name': 'P', 'buttons': [{'id': 'x', 'label': 'X', 'type': 'open', 'color': '#ff0000', 'target': 'calc.exe'}]}
      ],
      'hiddenGames': [],
    });
  });

  test('salvar não leva a página Jogos e mantém jogos ocultos', () {
    final c = DeckConfig.fromJson({
      'columns': 3,
      'hiddenGames': ['steam-1'],
      'games': [{'id': 'steam-730', 'label': 'CS2', 'source': 'Steam', 'icon': 'game-steam-730.jpg'}],
      'pages': [
        {'name': 'P', 'buttons': [{'id': 'a', 'label': 'CS2', 'type': 'game', 'game': 'steam-730', 'icon': 'game-steam-730.jpg'}]},
        {'name': 'Jogos', 'auto': true, 'buttons': [{'id': 'auto-steam-730', 'label': 'CS2', 'type': 'game', 'game': 'steam-730'}]},
      ],
    });
    final json = c.copy().toJson();
    expect((json['pages'] as List).length, 1);
    expect(json['hiddenGames'], ['steam-1']);
    expect((json['pages'] as List).first['buttons'].first, {'id': 'a', 'label': 'CS2', 'type': 'game', 'icon': 'game-steam-730.jpg', 'game': 'steam-730'});
    expect(c.games.single.label, 'CS2');
  });

  test('página OBS mantém a marca ao salvar e Configurações chegam do PC', () {
    final c = DeckConfig.fromJson({
      'columns': 3,
      'features': {'games': true, 'obs': true},
      'setupDone': false,
      'creatorPreset': {'name': 'Preset do Criador', 'version': '1.3.0', 'updatedAt': '2026-10-26', 'pages': 2, 'buttons': 12},
      'pages': [
        {'name': 'OBS', 'template': 'obs', 'buttons': []},
      ],
    });
    expect([c.gamesTab, c.obsPage, c.setupDone, c.creatorPreset!.buttons], [true, true, false, 12]);
    expect((c.copy().toJson()['pages'] as List).first['template'], 'obs');
  });

  test('botão widget leva só os campos do tipo e valor ao vivo é lido', () {
    final b = DeckButton(id: 't', label: 'Timer', type: 'widget', widget: 'timer', minutes: 10, city: 'sobra');
    expect(b.toJson(), {'id': 't', 'label': 'Timer', 'type': 'widget', 'widget': 'timer', 'minutes': 10});
    final v = LiveValue.fromJson({'text': '42%', 'sub': 'CPU', 'progress': 0.42, 'alert': false});
    expect([v.text, v.sub, v.progress, v.alert], ['42%', 'CPU', 0.42, false]);
    expect(DeckConfig.fromJson({'pages': [{'name': 'P', 'buttons': []}], 'features': {'widgets': true}}).widgetsPage, true);
  });
}
