import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

/// Result of the editor: the edited button, or null when the user deleted it.
class EditResult {
  final DeckButton? button;
  EditResult(this.button);
}

const _types = {
  'hotkey': 'Atalho de teclado',
  'open': 'Abrir programa, arquivo ou site',
  'game': 'Abrir jogo',
  'obs': 'OBS',
  'page': 'Ir para outra página',
  'widget': 'Widget ao vivo',
};

class ButtonEditor extends StatefulWidget {
  final DeckButton button;
  final List<GameInfo> games;
  final List<String> pageNames;
  final String Function(String file) iconUrl;
  const ButtonEditor({super.key, required this.button, required this.games, required this.pageNames, required this.iconUrl});

  @override
  State<ButtonEditor> createState() => _ButtonEditorState();
}

class _ButtonEditorState extends State<ButtonEditor> {
  late final b = widget.button.copy();
  late final label = TextEditingController(text: b.label);
  late final keys = TextEditingController(text: b.keys ?? '');
  late final target = TextEditingController(text: b.target ?? '');
  late final name = TextEditingController(text: b.name ?? '');
  late final minutes = TextEditingController(text: '${b.minutes ?? 5}');
  late final city = TextEditingController(text: b.city ?? '');

  void _save() {
    if (label.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dê um texto ao botão')));
      return;
    }
    b
      ..label = label.text.trim()
      ..keys = keys.text.trim()
      ..target = target.text.trim()
      ..name = name.text.trim()
      ..minutes = int.tryParse(minutes.text) ?? 5
      ..city = city.text.trim();
    if (b.type == 'obs') b.action ??= 'toggleStream';
    Navigator.pop(context, EditResult(b));
  }

  void _pickGame(String? id) {
    final g = widget.games.where((x) => x.id == id).firstOrNull;
    setState(() {
      b.game = id;
      if (g == null) return;
      if (label.text.trim().isEmpty || label.text == 'Novo') label.text = g.label;
      b.icon ??= g.icon;
    });
  }

  @override
  Widget build(BuildContext context) {
    final needsName = b.type == 'obs' && (b.action == 'scene' || b.action == 'toggleMute');
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar botão'),
        actions: [
          IconButton(tooltip: 'Apagar botão', icon: const Icon(Icons.delete_outline), onPressed: () => Navigator.pop(context, EditResult(null))),
          IconButton(tooltip: 'Salvar', icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: label, maxLength: 40, decoration: const InputDecoration(labelText: 'Texto (pode usar emoji)')),
          const Text('Imagem', style: TextStyle(color: Tokens.muted)),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Tokens.key, borderRadius: BorderRadius.circular(Tokens.rKey), border: Border.all(color: Tokens.border)),
              child: b.icon == null ? null : Image.network(widget.iconUrl(b.icon!), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: b.icon == null
                  ? const Text('Para pôr uma imagem, use o editor no PC (atalho "Stream Deck").', style: TextStyle(color: Tokens.muted, fontSize: 13))
                  : Align(alignment: Alignment.centerLeft, child: OutlinedButton(onPressed: () => setState(() => b.icon = null), child: const Text('Remover imagem'))),
            ),
          ]),
          gap,
          const Text('Cor de fundo', style: TextStyle(color: Tokens.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in palette)
              Semantics(
                label: c == palette.first ? 'cor padrão' : 'cor $c',
                selected: (b.color ?? palette.first) == c,
                button: true,
                child: InkWell(
                  onTap: () => setState(() => b.color = c == palette.first ? null : c),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hexColor(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: (b.color ?? palette.first) == c ? Tokens.text : Colors.transparent, width: 2),
                    ),
                  ),
                ),
              ),
          ]),
          gap,
          DropdownButtonFormField<String>(
            initialValue: b.type,
            decoration: const InputDecoration(labelText: 'Ação'),
            items: [for (final e in _types.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() {
              b.type = v!;
              if (b.type == 'widget') b.widget ??= 'clock';
            }),
          ),
          gap,
          if (b.type == 'hotkey')
            TextField(
              controller: keys,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Teclas',
                hintText: 'ctrl+shift+m',
                helperMaxLines: 4,
                helperText: 'Junte com +. Teclas: ctrl shift alt win, a-z, 0-9, f1-f24, enter esc space tab, '
                    'up down left right, volumeup volumedown mute, playpause next prev printscreen',
              ),
            ),
          if (b.type == 'open')
            TextField(
              controller: target,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Programa, arquivo ou site',
                hintText: 'calc.exe',
                helperMaxLines: 2,
                helperText: r'Ex.: notepad.exe, C:\Jogos\jogo.exe, https://youtube.com',
              ),
            ),
          if (b.type == 'game')
            widget.games.isEmpty
                ? const Text('Nenhum jogo detectado no PC. No editor do PC, clique em "Procurar jogos".', style: TextStyle(color: Tokens.muted))
                : DropdownButtonFormField<String>(
                    initialValue: widget.games.any((g) => g.id == b.game) ? b.game : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Jogo'),
                    items: [for (final g in widget.games) DropdownMenuItem(value: g.id, child: Text('${g.label} (${g.source})', overflow: TextOverflow.ellipsis))],
                    onChanged: _pickGame,
                  ),
          if (b.type == 'widget') ...[
            DropdownButtonFormField<String>(
              initialValue: widgetKinds.containsKey(b.widget) ? b.widget : 'clock',
              decoration: InputDecoration(labelText: 'Widget', helperText: widgetKinds[b.widget ?? 'clock']!.$2, helperMaxLines: 2),
              items: [for (final e in widgetKinds.entries) DropdownMenuItem(value: e.key, child: Text(e.value.$1))],
              onChanged: (v) => setState(() {
                final wasDefault = label.text == 'Novo' || widgetKinds.values.any((k) => k.$1 == label.text);
                b.widget = v;
                if (wasDefault) label.text = widgetKinds[v]!.$1;
              }),
            ),
            if (b.widget == 'timer') ...[
              const SizedBox(height: 16),
              TextField(controller: minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutos')),
            ],
            if (b.widget == 'weather') ...[
              const SizedBox(height: 16),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'Cidade', hintText: 'São Paulo')),
            ],
          ],
          if (b.type == 'page')
            DropdownButtonFormField<String>(
              initialValue: widget.pageNames.contains(b.page) ? b.page : null,
              decoration: const InputDecoration(labelText: 'Página'),
              items: [for (final n in widget.pageNames) DropdownMenuItem(value: n, child: Text(n))],
              onChanged: (v) => setState(() => b.page = v),
            ),
          if (b.type == 'obs') ...[
            DropdownButtonFormField<String>(
              initialValue: b.action ?? 'toggleStream',
              decoration: const InputDecoration(labelText: 'Ação no OBS'),
              items: const [
                DropdownMenuItem(value: 'toggleStream', child: Text('Ligar/desligar live')),
                DropdownMenuItem(value: 'toggleRecord', child: Text('Ligar/desligar gravação')),
                DropdownMenuItem(value: 'scene', child: Text('Trocar de cena')),
                DropdownMenuItem(value: 'toggleMute', child: Text('Mutar/desmutar fonte de áudio')),
              ],
              onChanged: (v) => setState(() => b.action = v),
            ),
            if (needsName) ...[
              gap,
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: b.action == 'scene' ? 'Nome da cena' : 'Nome da fonte de áudio',
                  helperText: 'Exatamente como aparece no OBS',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
