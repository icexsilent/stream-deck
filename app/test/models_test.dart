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
      ]
    });
  });
}
