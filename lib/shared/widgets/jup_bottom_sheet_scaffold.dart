import 'package:flutter/material.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/error_handler.dart';
import 'package:jup/shared/widgets/text.dart';

/// Wrapper für Bottom-Sheets mit dem App-Standard-Chrome:
/// Drag-Handle • Title + „Abbrechen" • Content-Slot • inline-Error • Save-Button.
///
/// Übernimmt zentral: `_saving`-Lifecycle, inline-Error aus geworfenen
/// Exceptions, optional Success-Snackbar nach pop(). Domain-Logik bleibt im
/// jeweiligen Sheet — der Scaffold ruft `onSave` und reagiert auf Erfolg
/// (String? → Snackbar + pop) oder Fehler (Exception → inline-Error).
///
/// Familie A (TextEditSheet) konfiguriert nur Title/Label/initialValue.
/// Familie B (Image-Upload, 2-Felder-Password, Forgot-Password) liefert
/// eigenes `child`-Widget.
class JupBottomSheetScaffold extends StatefulWidget {
  final String title;

  /// Optionaler Hint-Text unter dem Header (z.B. Passwort-Hinweis,
  /// Nickname-Erklärung).
  final String? hint;

  /// Eigentlicher Sheet-Inhalt (Formfelder, Image-Picker o.ä.).
  final Widget child;

  /// Wird beim Tap auf „Speichern" aufgerufen.
  ///
  /// Rückgabewert:
  /// - `String?` non-null → Success-Snackbar mit diesem Text nach pop()
  /// - `null` → nur pop(), keine Snackbar
  ///
  /// Wirft die Closure, fängt der Scaffold die Exception und zeigt sie als
  /// inline-Error über dem Save-Button. `AppException.message` wird bevorzugt.
  final Future<String?> Function() onSave;

  /// Ob der Save-Button überhaupt aktivierbar sein darf (z.B. „Form ist
  /// valide und Wert hat sich geändert"). Der Scaffold kombiniert das mit
  /// seinem internen `!_saving`-Check.
  final bool canSave;

  final String saveLabel;
  final String cancelLabel;

  const JupBottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    required this.canSave,
    this.hint,
    this.saveLabel = 'Speichern',
    this.cancelLabel = 'Abbrechen',
  });

  @override
  State<JupBottomSheetScaffold> createState() => _JupBottomSheetScaffoldState();
}

class _JupBottomSheetScaffoldState extends State<JupBottomSheetScaffold> {
  bool _saving = false;
  String? _inlineError;

  Future<void> _handleSave() async {
    if (_saving || !widget.canSave) return;
    setState(() {
      _saving = true;
      _inlineError = null;
    });
    try {
      final successMessage = await widget.onSave();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (successMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.showAppSnackbar(successMessage);
        });
      }
    } catch (e) {
      if (!mounted) return;
      // AppException trägt eine bereits user-freundliche Message — direkt
      // anzeigen, sonst durch den zentralen ErrorHandler filtern lassen.
      final msg = e is AppException ? e.message : ErrorHandler.parseError(e);
      setState(() {
        _saving = false;
        _inlineError = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Icon(
                Icons.remove_rounded,
                size: 32,
                color: colors.outline,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: TitleMedium(text: widget.title)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  child: LabelLarge(
                    text: widget.cancelLabel,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            if (widget.hint != null) ...[
              const SizedBox(height: 16),
              TitleSmall(
                text: widget.hint!,
                color: colors.onSurfaceVariant,
              ),
            ],
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: _saving,
              child: Opacity(
                opacity: _saving ? 0.6 : 1,
                child: widget.child,
              ),
            ),
            const SizedBox(height: 16),
            if (_inlineError != null) ...[
              ErrorText(text: _inlineError!),
              const SizedBox(height: 8),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
              ),
              onPressed:
                  (_saving || !widget.canSave) ? null : _handleSave,
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Text(widget.saveLabel),
            ),
          ],
        ),
      ),
    );
  }
}
