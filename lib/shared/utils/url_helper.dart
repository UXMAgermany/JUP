class UrlHelper {
  /// Formats a URL for display by removing common prefixes
  /// to keep it short and clean.
  ///
  /// Removes:
  /// - https://
  /// - http://
  /// - www.
  ///
  /// Example:
  /// - `https://www.profamilia.de` → `profamilia.de`
  /// - `http://example.com` → `example.com`
  /// - `www.schleswig-holstein.de/polizei` → `schleswig-holstein.de/polizei`
  static String formatUrlForDisplay(String url) {
    if (url.isEmpty) return url;

    String formatted = url.trim();

    // Remove https:// prefix
    if (formatted.startsWith('https://')) {
      formatted = formatted.substring(8);
    }
    // Remove http:// prefix
    else if (formatted.startsWith('http://')) {
      formatted = formatted.substring(7);
    }

    // Remove www. prefix
    if (formatted.startsWith('www.')) {
      formatted = formatted.substring(4);
    }

    return formatted;
  }
}
