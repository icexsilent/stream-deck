import 'dart:math';

/// Mirrors agent/buttons.json. The agent validates everything on save, so these classes only carry data.
class DeckButton {
  String id;
  String label;
  String type; // hotkey | open | obs
  String? color; // #rrggbb
  String? keys; // hotkey
  String? target; // open
  String? action; // obs: scene | toggleMute | toggleStream | toggleRecord
  String? name; // obs scene/input name

  DeckButton({required this.id, required this.label, required this.type, this.color, this.keys, this.target, this.action, this.name});

  factory DeckButton.blank() => DeckButton(id: 'b${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}', label: 'Novo', type: 'hotkey', keys: 'ctrl+c');

  factory DeckButton.fromJson(Map<String, dynamic> j) => DeckButton(
        id: j['id'],
        label: j['label'],
        type: j['type'],
        color: j['color'],
        keys: j['keys'],
        target: j['target'],
        action: j['action'],
        name: j['name'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type,
        if (color != null) 'color': color,
        if (type == 'hotkey') 'keys': keys,
        if (type == 'open') 'target': target,
        if (type == 'obs') 'action': action,
        if (type == 'obs' && (action == 'scene' || action == 'toggleMute')) 'name': name,
      };

  DeckButton copy() => DeckButton.fromJson(toJson());
}

class DeckPage {
  String name;
  List<DeckButton> buttons;
  DeckPage({required this.name, required this.buttons});

  factory DeckPage.fromJson(Map<String, dynamic> j) =>
      DeckPage(name: j['name'], buttons: [for (final b in j['buttons']) DeckButton.fromJson(b)]);

  Map<String, dynamic> toJson() => {'name': name, 'buttons': [for (final b in buttons) b.toJson()]};
}

class DeckConfig {
  int columns;
  List<DeckPage> pages;
  DeckConfig({required this.columns, required this.pages});

  factory DeckConfig.fromJson(Map<String, dynamic> j) =>
      DeckConfig(columns: j['columns'] ?? 3, pages: [for (final p in j['pages']) DeckPage.fromJson(p)]);

  Map<String, dynamic> toJson() => {'columns': columns, 'pages': [for (final p in pages) p.toJson()]};

  DeckConfig copy() => DeckConfig.fromJson(toJson());
}

/// What the QR code carries: the same link that opens the deck in a browser, http://IP:PORT/?t=TOKEN.
class Pairing {
  final String host;
  final int port;
  final String token;
  const Pairing(this.host, this.port, this.token);

  static Pairing? parse(String text) {
    final uri = Uri.tryParse(text.trim());
    final token = uri?.queryParameters['t'];
    if (uri == null || uri.scheme != 'http' || uri.host.isEmpty || token == null || token.isEmpty) return null;
    return Pairing(uri.host, uri.hasPort ? uri.port : 3000, token);
  }

  Pairing withHost(String h) => Pairing(h, port, token);

  @override
  String toString() => 'http://$host:$port/?t=$token';
}
