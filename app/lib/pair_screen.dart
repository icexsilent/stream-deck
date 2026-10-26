import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'models.dart';

class PairScreen extends StatefulWidget {
  final void Function(Pairing) onPaired;
  const PairScreen({super.key, required this.onPaired});

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  bool _done = false;

  void _accept(String? text) {
    final p = Pairing.parse(text ?? '');
    if (p == null || _done) return;
    _done = true;
    widget.onPaired(p);
  }

  Future<void> _typeLink() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Colar link do PC'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'http://192.168.x.x:3000/?t=...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Conectar')),
        ],
      ),
    );
    if (text == null || !mounted) return;
    if (Pairing.parse(text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link inválido. Copie o link inteiro que o PC mostra, com o ?t=')));
      return;
    }
    _accept(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parear com o PC')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '1. No PC, abra o atalho "Stream Deck - Parear" (ou http://localhost:3000/pair).\n'
              '2. Aponte a câmera para o QR code.\n\n'
              'O celular precisa estar no mesmo Wi-Fi do PC.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(onDetect: (cap) {
                for (final b in cap.barcodes) {
                  _accept(b.rawValue);
                }
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(onPressed: _typeLink, icon: const Icon(Icons.link), label: const Text('Colar link em vez de ler o QR')),
          ),
        ],
      ),
    );
  }
}
