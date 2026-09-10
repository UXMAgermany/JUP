const List<String> _monthsDe = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
];

/// Formats a date as e.g. "22. Juli 2026" without needing intl locale data.
String formatDateDe(DateTime d) => '${d.day}. ${_monthsDe[d.month - 1]} ${d.year}';
