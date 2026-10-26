import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button_editor.dart';
import 'connection.dart';
import 'models.dart';

class DeckScreen extends StatefulWidget {
  final Pairing pairing;
  final VoidCallback onUnpair;
  const DeckScreen({super.key, required this.pairing, required this.onUnpair});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> with WidgetsBindingObserver {
  late final conn = DeckConnection(widget.pairing);
  late final StreamSubscription<PressResult> _sub;
  final _flash = <String, bool>{}; // id -> ok?
  int page = 0;
  DeckConfig? draft; // non-null while editing
  bool saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = conn.results.stream.listen((r) {
      setState(() => _flash[r.id] = r.error == null);
      Timer(const Duration(milliseconds: 250), () => mounted ? setState(() => _flash.remove(r.id)) : null);
      if (r.error != null) _toast(r.error!);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) conn.reconnectNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub.cancel();
    conn.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    setState(() => saving = true);
    final err = await conn.saveConfig(draft!);
    if (!mounted) return;
    setState(() {
      saving = false;
      if (err == null) draft = null;
    });
    _toast(err == null ? 'Salvo no PC ✅' : 'Não salvou: $err');
  }

  Future<void> _editButton(DeckPage p, int i) async {
    final res = await Navigator.push<EditResult>(context, MaterialPageRoute(builder: (_) => ButtonEditor(button: p.buttons[i])));
    if (res == null) return;
    setState(() => res.button == null ? p.buttons.removeAt(i) : p.buttons[i] = res.button!);
  }

  Future<void> _addButton(DeckPage p) async {
    p.buttons.add(DeckButton.blank());
    setState(() {});
    await _editButton(p, p.buttons.length - 1);
  }

  Future<String?> _askName(String title, String initial) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _pageMenu(int i) async {
    final cfg = draft!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.edit), title: const Text('Renomear página'), onTap: () => Navigator.pop(ctx, 'rename')),
          if (i > 0) ListTile(leading: const Icon(Icons.arrow_back), title: const Text('Mover para a esquerda'), onTap: () => Navigator.pop(ctx, 'left')),
          if (cfg.pages.length > 1)
            ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Apagar página'), onTap: () => Navigator.pop(ctx, 'delete')),
        ]),
      ),
    );
    if (choice == 'rename') {
      final n = await _askName('Nome da página', cfg.pages[i].name);
      if (n != null && n.isNotEmpty) setState(() => cfg.pages[i].name = n);
    } else if (choice == 'left') {
      setState(() {
        cfg.pages.insert(i - 1, cfg.pages.removeAt(i));
        page = i - 1;
      });
    } else if (choice == 'delete') {
      setState(() {
        cfg.pages.removeAt(i);
        page = 0;
      });
    }
  }

  void _moveButton(DeckPage p, int from, int to) {
    if (to < 0 || to >= p.buttons.length) return;
    setState(() => p.buttons.insert(to, p.buttons.removeAt(from)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: conn,
      builder: (context, _) {
        final editing = draft != null;
        final cfg = draft ?? conn.config;
        final online = conn.state == LinkState.connected;
        return Scaffold(
          appBar: AppBar(
            title: Row(children: [
              Icon(Icons.circle, size: 12, color: online ? Colors.greenAccent : Colors.redAccent, semanticLabel: online ? 'conectado' : 'desconectado'),
              const SizedBox(width: 8),
              Text(editing ? 'Editando' : 'Stream Deck'),
            ]),
            actions: editing
                ? [
                    IconButton(tooltip: 'Descartar', icon: const Icon(Icons.close), onPressed: () => setState(() => draft = null)),
                    IconButton(
                      tooltip: 'Salvar no PC',
                      icon: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                      onPressed: saving ? null : _save,
                    ),
                  ]
                : [
                    if (conn.config != null)
                      IconButton(tooltip: 'Editar botões', icon: const Icon(Icons.edit), onPressed: () => setState(() => draft = conn.config!.copy())),
                    PopupMenuButton<String>(
                      onSelected: (v) => v == 'unpair' ? widget.onUnpair() : null,
                      itemBuilder: (_) => [const PopupMenuItem(value: 'unpair', child: Text('Parear com outro PC'))],
                    ),
                  ],
          ),
          body: cfg == null ? _status() : _deck(cfg, editing, online),
        );
      },
    );
  }

  Widget _status() {
    final (icon, text) = switch (conn.state) {
      LinkState.badToken => (Icons.key_off, 'O PC recusou a conexão (token mudou).\nLeia o QR code de novo.'),
      LinkState.searching => (Icons.wifi_find, 'Procurando o PC na rede…\nConfira se o agente está rodando e se o celular está no mesmo Wi-Fi.'),
      _ => (Icons.sync, 'Conectando em ${conn.pairing.host}…'),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          if (conn.state == LinkState.badToken) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: widget.onUnpair, child: const Text('Ler QR code')),
          ],
        ]),
      ),
    );
  }

  Widget _deck(DeckConfig cfg, bool editing, bool online) {
    page = page.clamp(0, cfg.pages.length - 1);
    final p = cfg.pages[page];
    return Column(children: [
      if (!online)
        MaterialBanner(
          content: Text(conn.state == LinkState.searching ? 'Sem conexão. Procurando o PC na rede…' : 'Reconectando…'),
          actions: const [SizedBox.shrink()],
        ),
      if (cfg.pages.length > 1 || editing)
        SizedBox(
          height: 56,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
            for (var i = 0; i < cfg.pages.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onLongPress: editing ? () => _pageMenu(i) : null,
                  child: ChoiceChip(label: Text(cfg.pages[i].name), selected: i == page, onSelected: (_) => setState(() => page = i)),
                ),
              ),
            if (editing)
              ActionChip(
                avatar: const Icon(Icons.add),
                label: const Text('Página'),
                onPressed: () async {
                  final n = await _askName('Nova página', 'Página ${cfg.pages.length + 1}');
                  if (n == null || n.isEmpty) return;
                  setState(() {
                    cfg.pages.add(DeckPage(name: n, buttons: []));
                    page = cfg.pages.length - 1;
                  });
                },
              ),
          ]),
        ),
      if (editing)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Expanded(child: Text('Toque num botão para editar. Segure uma página para renomear/apagar.', style: TextStyle(fontSize: 12))),
            IconButton(tooltip: 'Menos colunas', icon: const Icon(Icons.remove), onPressed: cfg.columns > 1 ? () => setState(() => cfg.columns--) : null),
            Text('${cfg.columns} col.'),
            IconButton(tooltip: 'Mais colunas', icon: const Icon(Icons.add), onPressed: cfg.columns < 8 ? () => setState(() => cfg.columns++) : null),
          ]),
        ),
      Expanded(
        child: GridView.count(
          crossAxisCount: cfg.columns,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (var i = 0; i < p.buttons.length; i++) _tile(p, i, editing, online),
            if (editing)
              OutlinedButton(
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => _addButton(p),
                child: const Icon(Icons.add, size: 32, semanticLabel: 'Adicionar botão'),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _tile(DeckPage p, int i, bool editing, bool online) {
    final b = p.buttons[i];
    final flash = _flash[b.id];
    final base = hexColor(b.color);
    final color = flash == null ? base : (flash ? Color.lerp(base, Colors.white, 0.4)! : Colors.red.shade700);
    final tile = Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: editing
            ? () => _editButton(p, i)
            : online
                ? () {
                    HapticFeedback.lightImpact();
                    conn.press(b.id);
                  }
                : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(b.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ),
    );
    if (!editing) return tile;
    return Stack(children: [
      Positioned.fill(child: tile),
      Positioned(
        left: 0,
        bottom: 0,
        child: IconButton(iconSize: 18, tooltip: 'Mover para trás', icon: const Icon(Icons.chevron_left), onPressed: () => _moveButton(p, i, i - 1)),
      ),
      Positioned(
        right: 0,
        bottom: 0,
        child: IconButton(iconSize: 18, tooltip: 'Mover para frente', icon: const Icon(Icons.chevron_right), onPressed: () => _moveButton(p, i, i + 1)),
      ),
    ]);
  }
}
