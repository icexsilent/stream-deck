import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'connection.dart';
import 'home_widget_sync.dart';
import 'theme.dart';

/// Configurações (⋮ menu). With [firstRun] it doubles as the welcome screen: choices apply on "Começar".
class SettingsScreen extends StatefulWidget {
  final DeckConnection conn;
  final bool firstRun;
  const SettingsScreen({super.key, required this.conn, this.firstRun = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool games = !widget.firstRun && widget.conn.config!.gamesTab;
  late bool obs = !widget.firstRun && widget.conn.config!.obsPage;
  late bool widgets = !widget.firstRun && widget.conn.config!.widgetsPage;
  bool busy = false;
  String? homePage;

  @override
  void initState() {
    super.initState();
    homeWidgetPage().then((p) => mounted ? setState(() => homePage = p) : null);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
          ],
        ),
      ) ==
      true;

  Future<void> _apply({bool? games, bool? obs, bool? widgets, bool close = false}) async {
    final g = games ?? this.games, o = obs ?? this.obs, w = widgets ?? this.widgets;
    if (!widget.firstRun && this.obs && !o && !await _confirm('Desligar a Página OBS?', 'A página OBS e os botões dela serão apagados.', 'Desligar')) return;
    if (!widget.firstRun && this.widgets && !w && !await _confirm('Desligar a Página Widgets?', 'A página Widgets e os botões dela serão apagados.', 'Desligar')) return;
    setState(() => busy = true);
    final err = await widget.conn.setFeatures(games: g, obs: o, widgets: w);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (err == null) {
        this.games = g;
        this.obs = o;
        this.widgets = w;
      }
    });
    if (err != null) return _toast('Não salvou: $err');
    if (close) Navigator.pop(context);
  }

  Future<void> _applyPreset() async {
    if (!await _confirm('Usar o Preset do Criador?', 'Isso troca TODOS os seus botões e páginas pelos do criador.', 'Usar preset')) return;
    setState(() => busy = true);
    final err = await widget.conn.applyCreatorPreset();
    if (!mounted) return;
    setState(() => busy = false);
    if (err != null) return _toast('Não aplicou: $err');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.conn.config?.creatorPreset;
    final first = widget.firstRun;
    return PopScope(
      canPop: !first, // the welcome screen is answered with "Começar"
      child: Scaffold(
        appBar: AppBar(title: Text(first ? 'Bem-vindo 👋' : 'Configurações'), automaticallyImplyLeading: !first),
        body: AbsorbPointer(
          absorbing: busy,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(
              first ? 'Escolha o que você quer além da página Principal. Dá para mudar depois em ⋮ → Configurações.' : 'Vale para o celular e para o PC.',
              style: const TextStyle(color: Tokens.muted),
            ),
            const SizedBox(height: 16),
            _option(
              title: '🎮 Aba Jogos',
              subtitle: 'Todos os jogos instalados no PC (Steam, Epic, Riot, Xbox). Tocar abre o jogo.',
              value: games,
              onChanged: (v) => first ? setState(() => games = v) : _apply(games: v),
            ),
            const SizedBox(height: 8),
            _option(
              title: '🎬 Página OBS',
              subtitle: 'Botões para live, gravação, cena e microfone do OBS.',
              value: obs,
              onChanged: (v) => first ? setState(() => obs = v) : _apply(obs: v),
            ),
            const SizedBox(height: 8),
            _option(
              title: '📊 Página Widgets',
              subtitle: 'Teclas ao vivo: relógio, CPU, RAM, GPU, música, volume, cronômetro, contador e clima.',
              value: widgets,
              onChanged: (v) => first ? setState(() => widgets = v) : _apply(widgets: v),
            ),
            if (preset != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Tokens.panel, borderRadius: BorderRadius.circular(Tokens.rPanel), border: Border.all(color: Tokens.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('⭐ ${preset.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'As configurações do criador na versão ${preset.version} (${preset.updatedAt}): ${preset.pages} páginas, ${preset.buttons} botões.',
                    style: const TextStyle(color: Tokens.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _applyPreset, child: const Text('Usar o Preset do Criador')),
                ]),
              ),
            ],
            if (!first && widget.conn.config != null) ...[
              const SizedBox(height: 24),
              const Text('Widget da tela inicial', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Mostra até 6 botões da página escolhida. Para pôr na tela: segure um espaço vazio da tela inicial → Widgets → Stream Deck.',
                  style: TextStyle(color: Tokens.muted, fontSize: 13)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: widget.conn.config!.pages.any((p) => p.name == homePage) ? homePage : widget.conn.config!.pages.first.name,
                decoration: const InputDecoration(labelText: 'Página do widget'),
                items: [for (final p in widget.conn.config!.pages) DropdownMenuItem(value: p.name, child: Text(p.auto ? '🎮 ${p.name}' : p.name))],
                onChanged: (v) {
                  setState(() => homePage = v);
                  setHomeWidgetPage(v!, widget.conn.config!, widget.conn.pairing);
                  _toast('Widget atualizado');
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_to_home_screen),
                label: const Text('Adicionar à tela inicial'),
                onPressed: () async {
                  // Android 8+ launchers show their own "add widget" prompt; older ones need the manual way above.
                  if (await HomeWidget.isRequestPinWidgetSupported() == true) {
                    await HomeWidget.requestPinWidget(androidName: 'DeckWidgetProvider');
                  } else {
                    _toast('Este celular não deixa o app adicionar sozinho: segure a tela inicial → Widgets → Stream Deck.');
                  }
                },
              ),
            ],
            if (first) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: () => _apply(close: true), child: const Text('Começar')),
            ],
            if (busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
          ]),
        ),
      ),
    );
  }

  Widget _option({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Tokens.rPanel), border: Border.all(color: Tokens.border)),
        child: SwitchListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(color: Tokens.muted, fontSize: 13)),
          value: value,
          onChanged: onChanged,
        ),
      );
}
