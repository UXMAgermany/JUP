import 'package:flutter/material.dart';
import 'package:jup/shared/utils/env_config.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:url_launcher/url_launcher.dart';

enum ReportReason {
  childSafety,
  inappropriateContent,
  harassment,
  spam,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.childSafety:
        return 'Kinderschutz-Bedenken';
      case ReportReason.inappropriateContent:
        return 'Unangemessener Inhalt';
      case ReportReason.harassment:
        return 'Belästigung oder Mobbing';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.other:
        return 'Sonstiges';
    }
  }

  String get emailSubject {
    switch (this) {
      case ReportReason.childSafety:
        return '[DRINGEND] Kinderschutz-Meldung';
      case ReportReason.inappropriateContent:
        return 'Meldung: Unangemessener Inhalt';
      case ReportReason.harassment:
        return 'Meldung: Belästigung/Mobbing';
      case ReportReason.spam:
        return 'Meldung: Spam';
      case ReportReason.other:
        return 'Inhaltsmeldung';
    }
  }
}

enum ReportContentType {
  comment,
  short,
  event,
  survey,
  general,
}

extension ReportContentTypeExtension on ReportContentType {
  String get label {
    switch (this) {
      case ReportContentType.comment:
        return 'Kommentar';
      case ReportContentType.short:
        return 'Short';
      case ReportContentType.event:
        return 'Event';
      case ReportContentType.survey:
        return 'Umfrage';
      case ReportContentType.general:
        return 'Allgemein';
    }
  }
}

class ReportBottomSheet extends StatefulWidget {
  final ReportContentType contentType;
  final String? contentId;
  final String? contentPreview;

  const ReportBottomSheet({
    super.key,
    required this.contentType,
    this.contentId,
    this.contentPreview,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportContentType contentType,
    String? contentId,
    String? contentPreview,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (context) => ReportBottomSheet(
        contentType: contentType,
        contentId: contentId,
        contentPreview: contentPreview,
      ),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  ReportReason? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  String get _supportEmail => EnvConfig.supportEmail;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    final subject = Uri.encodeComponent(_selectedReason!.emailSubject);
    final body = Uri.encodeComponent(_buildEmailBody());

    final Uri emailUri =
        Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vielen Dank für deine Meldung.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('E-Mail-App konnte nicht geöffnet werden.'),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _buildEmailBody() {
    final buffer = StringBuffer();

    buffer.writeln('=== Meldung ===');
    buffer.writeln();
    buffer.writeln('Grund: ${_selectedReason!.label}');
    buffer.writeln('Inhaltstyp: ${widget.contentType.label}');

    if (widget.contentId != null) {
      buffer.writeln('Inhalts-ID: ${widget.contentId}');
    }

    if (widget.contentPreview != null && widget.contentPreview!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Inhalt:');
      buffer.writeln('"${widget.contentPreview}"');
    }

    if (_detailsController.text.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Zusätzliche Details:');
      buffer.writeln(_detailsController.text);
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Gesendet über JUP! App');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TitleLarge(text: 'Inhalt melden'),
                const SizedBox(height: 8),
                BodyMedium(
                  text: 'Wähle einen Grund für deine Meldung:',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),

                // Report reasons
                ...ReportReason.values
                    .map((reason) => _buildReasonTile(reason)),

                const SizedBox(height: 16),

                // Additional details
                TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Zusätzliche Details (optional)',
                    hintText: 'Beschreibe das Problem...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Child safety notice
                if (_selectedReason == ReportReason.childSafety)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BodySmall(
                            text:
                                'Kinderschutz-Meldungen werden priorisiert behandelt. '
                                'Bei akuter Gefahr wende dich bitte direkt an die Polizei (110).',
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedReason == null || _isSubmitting
                        ? null
                        : _submitReport,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Meldung absenden'),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonTile(ReportReason reason) {
    final isSelected = _selectedReason == reason;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedReason = reason),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                _getReasonIcon(reason),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BodyMedium(
                  text: reason.label,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getReasonIcon(ReportReason reason) {
    switch (reason) {
      case ReportReason.childSafety:
        return Icons.shield_outlined;
      case ReportReason.inappropriateContent:
        return Icons.block;
      case ReportReason.harassment:
        return Icons.person_off_outlined;
      case ReportReason.spam:
        return Icons.report_outlined;
      case ReportReason.other:
        return Icons.more_horiz;
    }
  }
}
