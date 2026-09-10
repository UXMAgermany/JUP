import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet_scaffold.dart';

/// Generischer Bottom-Sheet für „1 Textfeld + Speichern".
///
/// Deckt die App-Standards für Edit-Sheets ab: Trim-on-Blur, Save disabled
/// wenn unverändert / leer, optionaler Hint-Text, single- oder multi-line.
/// Domain-Logik (welcher Controller/Provider mit dem Wert aufgerufen wird)
/// liefert der Aufrufer in `onSave`.
class TextEditSheet extends StatefulWidget {
  final String title;
  final String? hint;
  final String label;
  final String initialValue;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;

  /// Returns the trimmed value entered by the user; may return a non-null
  /// String to show as a Success-Snackbar after pop.
  final Future<String?> Function(String value) onSave;

  /// Wenn `true` (Default): Save bleibt disabled, solange `controller.text`
  /// (getrimmt) gleich `initialValue` ist.
  final bool requireChange;

  /// Wenn `true` (Default): Save bleibt disabled bei leerem Trim-Wert.
  final bool requireNonEmpty;

  const TextEditSheet({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    required this.onSave,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.requireChange = true,
    this.requireNonEmpty = true,
  });

  @override
  State<TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends State<TextEditSheet> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialValue;
    _controller = TextEditingController(text: widget.initialValue);
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _controller.text = _controller.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _canSave {
    final trimmed = _current.trim();
    if (widget.requireNonEmpty && trimmed.isEmpty) return false;
    if (widget.requireChange && trimmed == widget.initialValue) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return JupBottomSheetScaffold(
      title: widget.title,
      hint: widget.hint,
      canSave: _canSave,
      onSave: () => widget.onSave(_current.trim()),
      child: TextFormField(
        controller: _controller,
        focusNode: _focus,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        onChanged: (value) => setState(() => _current = value),
        decoration: InputDecoration(
          labelText: widget.label,
          alignLabelWithHint: widget.maxLines > 1,
        ),
      ),
    );
  }
}
