import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

/// One deck key: cover art fills it, the label sits on a dark scrim; shrinks while pressed like a real key.
class DeckTile extends StatefulWidget {
  final DeckButton button;
  final String Function(String file) iconUrl;
  final bool? flash; // true = ok, false = error, null = idle
  final bool selected;
  final VoidCallback? onTap;
  const DeckTile({super.key, required this.button, required this.iconUrl, this.flash, this.selected = false, this.onTap});

  @override
  State<DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends State<DeckTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.button;
    // Exe icons extracted on the PC are 32px; stretching them to cover looks blurry, so they sit centered instead.
    final smallIcon = b.icon != null && b.icon!.startsWith('game-') && b.icon!.endsWith('.png');
    final hasCover = b.icon != null && !smallIcon;
    final label = Text(
      b.label,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: b.icon == null ? 16 : 12, height: 1.15),
    );
    return Semantics(
      button: true,
      label: b.label,
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.93 : 1,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: hexColor(b.color),
              borderRadius: BorderRadius.circular(Tokens.rKey),
              border: widget.flash == false
                  ? Border.all(color: Tokens.danger, width: 2)
                  : widget.selected
                      ? Border.all(color: Tokens.accent, width: 2)
                      : null,
            ),
            foregroundDecoration: widget.flash == true || _down ? BoxDecoration(color: Colors.white.withValues(alpha: 0.18)) : null,
            child: Stack(fit: StackFit.expand, children: [
              if (b.icon != null)
                Padding(
                  padding: EdgeInsets.all(smallIcon ? 22 : 0),
                  child: Image.network(
                    widget.iconUrl(b.icon!),
                    fit: smallIcon ? BoxFit.contain : BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                )
              else if (b.type == 'game')
                Center(child: Text(b.label.trim().isEmpty ? '?' : b.label.trim()[0], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Tokens.muted))),
              if (b.icon == null && b.type != 'game')
                Center(child: Padding(padding: const EdgeInsets.all(8), child: label))
              else
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                    decoration: hasCover || b.type == 'game'
                        ? const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC000000)]))
                        : null,
                    child: label,
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
