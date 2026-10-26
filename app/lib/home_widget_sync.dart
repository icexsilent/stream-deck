import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import 'models.dart';

const _provider = 'DeckWidgetProvider';
const slotCount = 6;

/// Which page the home screen widget shows; null means the first page.
Future<String?> homeWidgetPage() => HomeWidget.getWidgetData<String>('page_choice');

Future<void> setHomeWidgetPage(String page, DeckConfig cfg, Pairing pairing) async {
  await HomeWidget.saveWidgetData('page_choice', page);
  await syncHomeWidget(cfg, pairing);
}

/// Writes the chosen page's first buttons for the native widget (DeckWidgetProvider.kt) and redraws it.
/// The pairing goes along so taps can reach the PC while the app is closed.
Future<void> syncHomeWidget(DeckConfig cfg, Pairing pairing) async {
  final choice = await homeWidgetPage();
  final page = cfg.pages.where((p) => p.name == choice).firstOrNull ?? cfg.pages.first;
  // Page-switch buttons only make sense inside the app.
  final buttons = page.buttons.where((b) => b.type != 'page').take(slotCount).toList();
  await HomeWidget.saveWidgetData('pairing', pairing.toString());
  await HomeWidget.saveWidgetData('page', page.name);
  await HomeWidget.saveWidgetData('count', buttons.length);
  for (var i = 0; i < buttons.length; i++) {
    await HomeWidget.saveWidgetData('label_$i', buttons[i].label);
    await HomeWidget.saveWidgetData('id_$i', buttons[i].id);
  }
  await HomeWidget.updateWidget(androidName: _provider);
}

/// Runs in a background isolate when a widget button is tapped: one short WebSocket round trip to the PC.
@pragma('vm:entry-point')
Future<void> onHomeWidgetTap(Uri? uri) async {
  final id = uri?.queryParameters['id'];
  final pairing = Pairing.parse(await HomeWidget.getWidgetData<String>('pairing') ?? '');
  if (id == null || pairing == null) return;
  WebSocket? ws;
  try {
    ws = await WebSocket.connect('ws://${pairing.host}:${pairing.port}/?t=${Uri.encodeQueryComponent(pairing.token)}').timeout(const Duration(seconds: 4));
    ws.add(jsonEncode({'type': 'press', 'id': id}));
    // The agent answers ok/error for this id; waiting for it makes sure the press left the phone before closing.
    await ws.firstWhere((m) {
      final msg = jsonDecode(m as String);
      return (msg['type'] == 'ok' || msg['type'] == 'error') && msg['id'] == id;
    }).timeout(const Duration(seconds: 4));
  } catch (_) {
    // PC off or another network: nothing to show from the background.
  } finally {
    await ws?.close();
  }
}
