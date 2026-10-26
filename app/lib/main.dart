import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'connection.dart';
import 'deck_screen.dart';
import 'home_widget_sync.dart';
import 'models.dart';
import 'pair_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(onHomeWidgetTap);
  runApp(StreamDeckApp(saved: await DeckConnection.loadSaved()));
}

class StreamDeckApp extends StatefulWidget {
  final Pairing? saved;
  const StreamDeckApp({super.key, this.saved});

  @override
  State<StreamDeckApp> createState() => _StreamDeckAppState();
}

class _StreamDeckAppState extends State<StreamDeckApp> {
  late Pairing? pairing = widget.saved;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Deck',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: pairing == null
          ? PairScreen(onPaired: (p) async {
              await DeckConnection.save(p);
              setState(() => pairing = p);
            })
          : DeckScreen(
              key: ValueKey(pairing.toString()),
              pairing: pairing!,
              onUnpair: () async {
                await DeckConnection.forget();
                await HomeWidget.saveWidgetData('count', 0); // the home screen widget goes back to "abra o app"
                await HomeWidget.updateWidget(androidName: 'DeckWidgetProvider');
                setState(() => pairing = null);
              },
            ),
    );
  }
}
