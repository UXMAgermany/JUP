import 'package:flutter/material.dart';

/// Tappable `InputDecorator`, der ein optionales [DateTime] anzeigt und beim
/// Antippen [onTap] auslöst. Inkludiert Semantics(button:true, ...) für
/// Voiceover/TalkBack.
class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  String _format(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dt = value;
    return Semantics(
      label: dt == null
          ? '$label auswählen'
          : '$label: ${_format(dt)}, antippen zum Ändern',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          isEmpty: dt == null,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(dt == null ? '' : _format(dt)),
        ),
      ),
    );
  }
}
