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
  final VoidCallback? onLongPress;
  final LiveValue? live; // widget keys only
  const DeckTile({super.key, required this.button, required this.iconUrl, this.flash, this.selected = false, this.onTap, this.onLongPress, this.live});

  @override
  State<DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends State<DeckTile> {
  bool _down = false;

  // Live key: name on top, big value in the middle, detail below, bar along the bottom edge.
  Widget _widgetFace(DeckButton b) {
    final v = widget.live;
    final alert = v?.alert ?? false;
    return Stack(fit: StackFit.expand, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Tokens.muted)),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(v?.text ?? '…',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.1, color: alert ? Tokens.danger : Colors.white, fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ),
            ),
          ),
          if (v?.sub != null)
            Text(v!.sub!, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Tokens.muted)),
        ]),
      ),
      if (v?.progress != null)
        Align(
          alignment: Alignment.bottomCenter,
          child: LinearProgressIndicator(value: v!.progress!.clamp(0, 1), minHeight: 4, backgroundColor: Colors.white10, color: alert ? Tokens.danger : Tokens.accent),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.button;
    // Program icons (and 32px game exe icons) sit centered; stretched edge to edge they look wrong or blurry.
    final smallIcon = b.icon != null && (b.icon!.startsWith('app-') || (b.icon!.startsWith('game-') && b.icon!.endsWith('.png')));
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
        onLongPress: widget.onLongPress,
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
            child: b.type == 'widget' ? _widgetFace(b) : Stack(fit: StackFit.expand, children: [
              if (b.icon != null)
                Padding(
                  padding: smallIcon ? const EdgeInsets.fromLTRB(20, 12, 20, 36) : EdgeInsets.zero,
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
