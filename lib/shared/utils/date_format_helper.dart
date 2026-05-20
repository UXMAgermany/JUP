class DateFormatHelper {
  /// Formats a DateTime as "YYY-MM-DD"
  static String formatToStrapiDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$year-$month-$day';
  }

  /// Formats a DateTime as "DD.MM.YYYY"
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day.$month.$year';
  }

  /// Formats a DateTime as "DD.MM.YYYY | HH:MM"
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.$year | $hour:$minute';
  }

  /// Formats to "noch X Tage" until the given date
  static String daysUntil(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = date.toLocal().difference(now).inDays;
    if (difference < 0) {
      return 'beendet vor ${difference.abs()} Tagen';
    } else if (difference == 0) {
      return 'beendet heute';
    } else if (difference == 1) {
      return 'noch 1 Tag';
    } else {
      return 'noch $difference Tage';
    }
  }
}
