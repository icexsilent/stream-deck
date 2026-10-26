import 'package:flutter/material.dart';

import 'connection.dart';
import 'deck_screen.dart';
import 'models.dart';
import 'pair_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
                setState(() => pairing = null);
              },
            ),
    );
  }
}
