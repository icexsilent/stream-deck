import 'package:flutter/material.dart';

import 'connection.dart';
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
  bool busy = false;

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

  Future<void> _apply({bool? games, bool? obs, bool close = false}) async {
    final g = games ?? this.games, o = obs ?? this.obs;
    if (!widget.firstRun && this.obs && !o && !await _confirm('Desligar a Página OBS?', 'A página OBS e os botões dela serão apagados.', 'Desligar')) return;
    setState(() => busy = true);
    final err = await widget.conn.setFeatures(games: g, obs: o);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (err == null) {
        this.games = g;
        this.obs = o;
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
