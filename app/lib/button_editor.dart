import 'package:flutter/material.dart';

import 'models.dart';

const palette = ['#2a2a2a', '#4a6cf7', '#7c3aed', '#db2777', '#dc2626', '#ea580c', '#ca8a04', '#16a34a', '#0891b2'];

Color hexColor(String? hex) => Color(int.parse((hex ?? '#2a2a2a').substring(1), radix: 16) | 0xFF000000);

/// Result of the editor: the edited button, or null when the user deleted it.
class EditResult {
  final DeckButton? button;
  EditResult(this.button);
}

class ButtonEditor extends StatefulWidget {
  final DeckButton button;
  const ButtonEditor({super.key, required this.button});

  @override
  State<ButtonEditor> createState() => _ButtonEditorState();
}

class _ButtonEditorState extends State<ButtonEditor> {
  late final b = widget.button.copy();
  late final label = TextEditingController(text: b.label);
  late final keys = TextEditingController(text: b.keys ?? '');
  late final target = TextEditingController(text: b.target ?? '');
  late final name = TextEditingController(text: b.name ?? '');

  void _save() {
    if (label.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dê um texto ao botão')));
      return;
    }
    b
      ..label = label.text.trim()
      ..keys = keys.text.trim()
      ..target = target.text.trim()
      ..name = name.text.trim();
    if (b.type == 'obs') b.action ??= 'toggleStream';
    Navigator.pop(context, EditResult(b));
  }

  @override
  Widget build(BuildContext context) {
    final needsName = b.type == 'obs' && (b.action == 'scene' || b.action == 'toggleMute');
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
          const SizedBox(height: 8),
          const Text('Cor'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in palette)
              Semantics(
                label: 'cor $c',
                selected: (b.color ?? palette.first) == c,
                child: InkWell(
                  onTap: () => setState(() => b.color = c == palette.first ? null : c),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: hexColor(c),
                    child: (b.color ?? palette.first) == c ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hotkey', label: Text('Atalho'), icon: Icon(Icons.keyboard)),
              ButtonSegment(value: 'open', label: Text('Abrir'), icon: Icon(Icons.open_in_new)),
              ButtonSegment(value: 'obs', label: Text('OBS'), icon: Icon(Icons.videocam)),
            ],
            selected: {b.type},
            onSelectionChanged: (s) => setState(() => b.type = s.first),
          ),
          const SizedBox(height: 16),
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
            if (needsName)
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: b.action == 'scene' ? 'Nome da cena' : 'Nome da fonte de áudio',
                  helperText: 'Exatamente como aparece no OBS',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
