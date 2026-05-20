import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/surveys/controllers/custom_option_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/custom_option_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/widgets/text.dart';

class CustomOptionSheet extends ConsumerStatefulWidget {
  final String surveyDocumentId;
  final bool isJUPAdmin;

  const CustomOptionSheet({
    super.key,
    required this.surveyDocumentId,
    this.isJUPAdmin = false,
  });

  static Future<void> show(
    BuildContext context,
    String surveyDocumentId, {
    bool isJUPAdmin = false,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CustomOptionSheet(
        surveyDocumentId: surveyDocumentId,
        isJUPAdmin: isJUPAdmin,
      ),
    );
  }

  @override
  ConsumerState<CustomOptionSheet> createState() => _CustomOptionSheetState();
}

class _CustomOptionSheetState extends ConsumerState<CustomOptionSheet> {
  final _textController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(myCustomOptionsProvider(widget.surveyDocumentId));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitOption() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 40) {
      setState(() => _error = 'Maximal 40 Zeichen erlaubt.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final controller = ref.read(surveysControllerProvider);
      final customOption =
          await controller.submitCustomOption(widget.surveyDocumentId, text);
      _textController.clear();
      ref.invalidate(myCustomOptionsProvider(widget.surveyDocumentId));

      if (customOption.status == CustomOptionStatus.approved && mounted) {
        ref.read(surveysListProvider.notifier).refresh();
        Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      setState(() => _error =
          e is AppException ? e.message : 'Ein Fehler ist aufgetreten.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myOptionsAsync =
        ref.watch(myCustomOptionsProvider(widget.surveyDocumentId));

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Icon(
                Icons.remove_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TitleMedium(text: 'Antwort einreichen'),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: LabelLarge(
                  text: 'Abbrechen',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Content
          myOptionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: BodyMedium(text: 'Fehler beim Laden')),
            ),
            data: (options) => _buildContent(context, options),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<CustomOption> options) {
    final rejected =
        options.where((o) => o.status == CustomOptionStatus.rejected).toList();
    final pending =
        options.where((o) => o.status == CustomOptionStatus.pending).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status section
        if (rejected.isNotEmpty || pending.isNotEmpty) ...[
          LabelLargeEmphasized(text: 'Status deiner Antworten'),
          const SizedBox(height: 8),
        ],

        // Rejected options
        if (rejected.isNotEmpty) ...[
          LabelLarge(
            text: 'Abgelehnt',
          ),
          const SizedBox(height: 4),
          ...rejected.map((option) => _buildOptionTile(context, option)),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: BodySmall(
              text:
                  'Melde dich beim JUZ, um zu verstehen, was du das nächste Mal besser machen kannst!',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // Pending options
        if (pending.isNotEmpty) ...[
          LabelLarge(
            text: 'In Prüfung',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          ...pending.map((option) => _buildOptionTile(context, option)),
          const SizedBox(height: 12),
        ],

        // Divider
        if (rejected.isNotEmpty || pending.isNotEmpty) const Divider(),

        // New answer section
        const SizedBox(height: 8),
        LabelLargeEmphasized(text: 'Neue Antwort'),
        const SizedBox(height: 4),
        TitleSmall(
          text: widget.isJUPAdmin
              ? 'Deine Antwort wird sofort veröffentlicht.'
              : 'Deine Antwort wird vor der Veröffentlichung von uns geprüft.',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _textController,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Deine Antwort (max. 40 Zeichen)',
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          BodySmall(
            text: _error!,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
        ],
        Center(
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submitOption,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Absenden'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOptionTile(BuildContext context, CustomOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: BodyMedium(text: option.text),
      ),
    );
  }
}
