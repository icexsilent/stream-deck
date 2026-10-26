import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button_editor.dart';
import 'connection.dart';
import 'deck_tile.dart';
import 'home_widget_sync.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'theme.dart';

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
  DeckConfig? draft; // non-null while editing; holds only the user's pages
  bool saving = false;
  bool _welcomeShown = false;
  DeckConfig? _synced; // last config written to the home screen widget

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    conn.addListener(_maybeWelcome);
    _sub = conn.results.stream.listen((r) {
      setState(() => _flash[r.id] = r.error == null);
      Timer(const Duration(milliseconds: 250), () => mounted ? setState(() => _flash.remove(r.id)) : null);
      if (r.error != null) _toast(r.error!);
    });
  }

  // A brand-new install asks once which extras to turn on.
  void _maybeWelcome() {
    final c = conn.config;
    if (c != null && !identical(c, _synced)) {
      _synced = c;
      syncHomeWidget(c, conn.pairing);
    }
    if (c == null || c.setupDone || _welcomeShown) return;
    _welcomeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(conn: conn, firstRun: true)));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) conn.reconnectNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    conn.removeListener(_maybeWelcome);
    _sub.cancel();
    conn.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  void _startEditing() {
    final c = conn.config!.copy()..pages.removeWhere((p) => p.auto);
    setState(() {
      draft = c;
      page = page.clamp(0, c.pages.length - 1);
    });
  }

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

  void _press(DeckButton b, DeckConfig cfg) {
    HapticFeedback.lightImpact();
    if (b.type == 'page') {
      final to = cfg.pages.indexWhere((p) => p.name == b.page);
      if (to >= 0) setState(() => page = to);
      return;
    }
    conn.press(b.id);
  }

  Future<void> _editButton(DeckPage p, int i) async {
    final cfg = conn.config!;
    final res = await Navigator.push<EditResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ButtonEditor(
          button: p.buttons[i],
          games: cfg.games,
          plugins: cfg.plugins,
          pageNames: [for (final x in draft!.pages) x.name, if (cfg.pages.any((x) => x.auto)) 'Jogos'],
          iconUrl: conn.iconUrl,
        ),
      ),
    );
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
        content: TextField(controller: ctrl, autofocus: true, maxLength: 30),
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
            titleSpacing: 16,
            title: editing
                ? const Text('Editando')
                : Semantics(
                    label: online ? 'Conectado ao PC' : 'Desconectado',
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: online ? Tokens.ok : Tokens.danger, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      const Text('Stream Deck', style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
            actions: editing
                ? [
                    IconButton(tooltip: 'Descartar', icon: const Icon(Icons.close), onPressed: () => setState(() => draft = null)),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton(
                        onPressed: saving ? null : _save,
                        child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
                      ),
                    ),
                  ]
                : [
                    if (conn.config != null) IconButton(tooltip: 'Editar botões', icon: const Icon(Icons.edit_outlined), onPressed: _startEditing),
                    PopupMenuButton<String>(
                      tooltip: 'Mais opções',
                      onSelected: (v) => switch (v) {
                        'settings' => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(conn: conn))),
                        'rescan' => conn.rescan(),
                        _ => widget.onUnpair(),
                      },
                      itemBuilder: (_) => [
                        if (conn.config != null) const PopupMenuItem(value: 'settings', child: Text('Configurações')),
                        if (conn.config?.gamesTab == true) const PopupMenuItem(value: 'rescan', child: Text('Procurar jogos no PC')),
                        const PopupMenuItem(value: 'unpair', child: Text('Parear com outro PC')),
                      ],
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
      LinkState.badToken => (Icons.key_off, 'O PC recusou a conexão (o código mudou).\nLeia o QR code de novo.'),
      LinkState.searching => (Icons.wifi_find, 'Procurando o PC na rede…\nConfira se o agente está rodando e se o celular está no mesmo Wi-Fi.'),
      _ => (Icons.sync, 'Conectando em ${conn.pairing.host}…'),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: Tokens.muted),
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
        Container(
          width: double.infinity,
          color: Tokens.danger.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(conn.state == LinkState.searching ? 'Sem conexão. Procurando o PC na rede…' : 'Reconectando…', style: const TextStyle(fontSize: 13)),
        ),
      if (cfg.pages.length > 1 || editing)
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), children: [
            for (var i = 0; i < cfg.pages.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onLongPress: editing ? () => _pageMenu(i) : null,
                  child: ChoiceChip(
                    label: Text(cfg.pages[i].auto ? '🎮 ${cfg.pages[i].name}' : cfg.pages[i].name),
                    selected: i == page,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => page = i),
                  ),
                ),
              ),
            if (editing)
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
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
            const Expanded(child: Text('Toque num botão para editar. Segure uma página para renomear ou apagar.', style: TextStyle(fontSize: 12, color: Tokens.muted))),
            IconButton(tooltip: 'Menos colunas', icon: const Icon(Icons.remove), onPressed: cfg.columns > 1 ? () => setState(() => cfg.columns--) : null),
            Text('${cfg.columns} col.'),
            IconButton(tooltip: 'Mais colunas', icon: const Icon(Icons.add), onPressed: cfg.columns < 8 ? () => setState(() => cfg.columns++) : null),
          ]),
        ),
      Expanded(
        child: p.buttons.isEmpty && !editing
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    p.auto ? (conn.config!.scanning ? 'Procurando jogos no PC…' : 'Nenhum jogo encontrado no PC.') : 'Página vazia. Toque em ✏️ para criar botões.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Tokens.muted),
                  ),
                ),
              )
            : GridView.count(
                crossAxisCount: cfg.columns,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var i = 0; i < p.buttons.length; i++) _tile(p, i, cfg, editing, online),
                  if (editing)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.rKey)),
                        side: const BorderSide(color: Tokens.border, width: 2),
                      ),
                      onPressed: () => _addButton(p),
                      child: const Icon(Icons.add, size: 32, color: Tokens.muted, semanticLabel: 'Adicionar botão'),
                    ),
                ],
              ),
      ),
    ]);
  }

  Widget _tile(DeckPage p, int i, DeckConfig cfg, bool editing, bool online) {
    final b = p.buttons[i];
    Widget tileWith(LiveValue? live) => DeckTile(
          button: b,
          iconUrl: conn.iconUrl,
          flash: _flash[b.id],
          live: live,
          onTap: editing ? () => _editButton(p, i) : (online || b.type == 'page' ? () => _press(b, cfg) : null),
          // Long press zeroes counters and timers, and skips to the next song.
          onLongPress: !editing && online && b.type == 'widget'
              ? () {
                  HapticFeedback.mediumImpact();
                  conn.press(b.id, long: true);
                }
              : null,
        );
    final tile = b.type == 'widget' ? ValueListenableBuilder(valueListenable: conn.live, builder: (_, live, _) => tileWith(live[b.id])) : tileWith(null);
    if (!editing) return tile;
    Widget arrow(IconData icon, String tip, int to) => Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: IconButton(visualDensity: VisualDensity.compact, iconSize: 18, tooltip: tip, icon: Icon(icon), onPressed: () => _moveButton(p, i, to)),
        );
    return Stack(children: [
      Positioned.fill(child: tile),
      Positioned(left: 2, top: 2, child: arrow(Icons.chevron_left, 'Mover para trás', i - 1)),
      Positioned(right: 2, top: 2, child: arrow(Icons.chevron_right, 'Mover para frente', i + 1)),
    ]);
  }
}
