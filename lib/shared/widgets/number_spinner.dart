import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Segmentierter Spinner für ganze Zahlen. Folgt dem App-eigenen
/// Figma-Design (Node `61710:43095`): 160×42 px Outline-Container mit
/// drei zusammenhängenden Segmenten — Minus-Button, zentrierte Zahl,
/// Plus-Button. Das Mittel-Segment ist intern ein `TextField`, visuell
/// aber als reine Schrift maskiert, sodass User größere Werte direkt
/// eintippen können statt nur via +/−.
///
/// Disabled-Status für den Minus-Button wenn `value == min`. Ungültige
/// Eingaben (leer, < min, nicht-numerisch) werden bei
/// `onEditingComplete` / `onSubmitted` / `onTapOutside` auf `min`
/// geklemmt.
class NumberSpinner extends StatefulWidget {
  /// Aktueller Wert.
  final int value;

  /// Wird mit dem neuen Wert aufgerufen, sobald der User
  /// inkrementiert, dekrementiert oder einen validen Wert tippt.
  final ValueChanged<int> onChanged;

  /// Untergrenze. Der Minus-Button ist disabled bei `value == min`,
  /// invalide Eingaben werden auf [min] geklemmt. Default 1.
  final int min;

  /// Tooltip für den Minus-Button.
  final String decrementTooltip;

  /// Tooltip für den Plus-Button.
  final String incrementTooltip;

  /// Optionaler Builder für das Semantics-Label (VoiceOver). Bekommt
  /// den aktuellen Wert; Default: `'Anzahl: $value'`.
  final String Function(int value)? semanticsLabelBuilder;

  const NumberSpinner({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.decrementTooltip = 'Eins weniger',
    this.incrementTooltip = 'Eins mehr',
    this.semanticsLabelBuilder,
  });

  @override
  State<NumberSpinner> createState() => _NumberSpinnerState();
}

class _NumberSpinnerState extends State<NumberSpinner> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant NumberSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = int.tryParse(_ctrl.text);
    if (current != widget.value) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commitParsedValue() {
    final parsed = int.tryParse(_ctrl.text);
    final next = (parsed == null || parsed < widget.min) ? widget.min : parsed;
    if (next != widget.value) {
      widget.onChanged(next);
    }
    if (_ctrl.text != next.toString()) {
      _ctrl.text = next.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label =
        widget.semanticsLabelBuilder?.call(widget.value) ??
            'Anzahl: ${widget.value}';
    return Semantics(
      label: label,
      child: Container(
        // 160 = 1 (Border) + 48 (Minus) + 62 (Zahl) + 48 (Plus) + 1 (Border).
        // Höhe analog: 40 px Content + 2 × 1 px Border.
        height: 42,
        width: 160,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          // Inner-Radius minimal kleiner als Outer, damit die Segment-
          // Backgrounds nicht über den äußeren Border kleben.
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              _SpinnerSegment(
                icon: Icons.remove,
                tooltip: widget.decrementTooltip,
                side: _SegmentSide.left,
                onTap: widget.value > widget.min
                    ? () => widget.onChanged(widget.value - 1)
                    : null,
              ),
              SizedBox(
                width: 62,
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= widget.min) {
                      widget.onChanged(parsed);
                    }
                  },
                  onEditingComplete: _commitParsedValue,
                  onSubmitted: (_) => _commitParsedValue(),
                  onTapOutside: (_) => _commitParsedValue(),
                ),
              ),
              _SpinnerSegment(
                icon: Icons.add,
                tooltip: widget.incrementTooltip,
                side: _SegmentSide.right,
                onTap: () => widget.onChanged(widget.value + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SegmentSide { left, right }

/// Linkes oder rechtes Segment des [NumberSpinner]. 48 px breit, mit
/// `surfaceContainer`-Background und einer internen Trennlinie zur Mitte
/// (rechter Border bei [_SegmentSide.left], linker Border bei
/// [_SegmentSide.right]). [onTap] null → disabled-Look mit gedämpfter
/// Icon-Farbe.
class _SpinnerSegment extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final _SegmentSide side;
  final VoidCallback? onTap;

  const _SpinnerSegment({
    required this.icon,
    required this.tooltip,
    required this.side,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    final iconColor = disabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
        : scheme.onSurfaceVariant;
    final divider = BorderSide(color: scheme.outline);

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          right: side == _SegmentSide.left ? divider : BorderSide.none,
          left: side == _SegmentSide.right ? divider : BorderSide.none,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: Icon(icon, size: 24, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
