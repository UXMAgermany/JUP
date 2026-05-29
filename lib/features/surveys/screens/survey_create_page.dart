import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jup/features/surveys/controllers/survey_create_form_provider.dart';
import 'package:jup/features/surveys/controllers/survey_create_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/features/surveys/screens/survey_create/step1_type.dart';
import 'package:jup/features/surveys/screens/survey_create/step2_mode.dart';
import 'package:jup/features/surveys/screens/survey_create/step_form.dart';
import 'package:jup/features/surveys/screens/survey_create/step_schedule.dart';
import 'package:jup/features/surveys/screens/survey_create/step_success.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/media_picker.dart';
import 'package:jup/shared/widgets/media_source_sheet.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class SurveyCreatePage extends ConsumerStatefulWidget {
  const SurveyCreatePage({super.key});

  @override
  ConsumerState<SurveyCreatePage> createState() => _SurveyCreatePageState();
}

/// Enum für die einzelnen Wizard-Schritte. Die Sequenz wird typabhängig
/// zusammengesetzt — siehe [_stepSequence].
enum _SurveyStep { type, mode, form, schedule }

class _SurveyCreatePageState extends ConsumerState<SurveyCreatePage> {
  int _currentIndex = 0;
  final _mediaPicker = MediaPicker();

  /// `true` nachdem submit erfolgreich war — Wizard wird durch Success-
  /// Screen ersetzt.
  bool _success = false;

  /// Snapshot der Submission-Daten für den Success-Screen (Provider wird
  /// nach Close ggf. via autoDispose verworfen).
  SurveyType? _submittedType;
  bool _submittedAllowCustomOptions = false;
  DateTime? _submittedScheduledAt;

  /// Liefert die Reihenfolge der Steps abhängig vom aktuell gewählten Typ.
  /// Bei `multiple` wird der Modus-Step zwischen Typ und Form eingeschoben;
  /// bei den anderen Typen entfällt er.
  List<_SurveyStep> _stepSequence(SurveyCreateFormState state) {
    if (state.type == SurveyType.multiple) {
      return const [
        _SurveyStep.type,
        _SurveyStep.mode,
        _SurveyStep.form,
        _SurveyStep.schedule,
      ];
    }
    return const [
      _SurveyStep.type,
      _SurveyStep.form,
      _SurveyStep.schedule,
    ];
  }

  bool _isStepValid(_SurveyStep step, SurveyCreateFormState state) {
    switch (step) {
      case _SurveyStep.type:
        return state.isStep1Valid;
      case _SurveyStep.mode:
        return state.isStep2Valid;
      case _SurveyStep.form:
        return state.isFormStepValid;
      case _SurveyStep.schedule:
        return state.isScheduleStepValid;
    }
  }

  /// AppBar-Subtitle reflektiert den Typ und ggf. den Modus (analog
  /// Figma — siehe Screens 61311:61959/62708/63702/63202/62500). Solange
  /// noch kein Typ gewählt ist, wird kein Subtitle angezeigt.
  String? _subtitleFor(SurveyCreateFormState state) {
    final type = state.type;
    if (type == null) return null;
    switch (type) {
      case SurveyType.yesNo:
        return 'JUP!/NÖ!-Umfrage';
      case SurveyType.election:
        return 'Wahl';
      case SurveyType.multiple:
        final mode = state.allowCustomOptions;
        if (mode == null) return null;
        return mode ? 'Freitext-Optionen' : 'Festgelegte Optionen';
    }
  }

  Future<File?> _pickImageWithFeedback(ImageSource source) async {
    try {
      return await _mediaPicker.pickImage(
        source,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
      );
    } on AppException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    }
  }

  Future<void> _onPickHero(SurveyCreateFormController controller) async {
    final source = await askImageSource(context);
    if (source == null) return;
    final file = await _pickImageWithFeedback(source);
    if (file != null) controller.setHeroImage(file);
  }

  Future<void> _pickExpiresAt(
    SurveyCreateFormController controller,
    SurveyCreateFormState state,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: state.expiresAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null) return;
    controller.setExpiresAt(date);
  }

  Future<void> _pickPublishDate(
    SurveyCreateFormController controller,
    SurveyCreateFormState state,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: state.publishAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;
    controller.setPublishDate(date);
  }

  Widget _buildStep(_SurveyStep step, SurveyCreateFormState state,
      SurveyCreateFormController controller) {
    switch (step) {
      case _SurveyStep.type:
        return SurveyCreateStep1Type(
          selected: state.type,
          onSelect: (t) {
            controller.setType(t);
            // Index zurücksetzen, falls vorher schon weiter — z.B. wenn
            // User Modus-Step gesehen hatte und jetzt zu yesNo wechselt.
            setState(() => _currentIndex = 0);
          },
        );
      case _SurveyStep.mode:
        return SurveyCreateStep2Mode(
          allowCustomOptions: state.allowCustomOptions,
          onSelect: controller.setAllowCustomOptions,
        );
      case _SurveyStep.form:
        return SurveyCreateStepForm(
          state: state,
          onTitleChanged: controller.setTitle,
          onSubTitleChanged: controller.setSubTitle,
          onPickHero: () => _onPickHero(controller),
          onRemoveHero: () => controller.setHeroImage(null),
          onOptionChanged: controller.setOption,
          onAddOption: controller.addOption,
          onRemoveOption: controller.removeOption,
          onMaxVotesChanged: controller.setMaxVotes,
        );
      case _SurveyStep.schedule:
        return SurveyCreateStepSchedule(
          state: state,
          onPickExpiresAt: () => _pickExpiresAt(controller, state),
          onTogglePublishLater: controller.setPublishLater,
          onPickPublishDate: () => _pickPublishDate(controller, state),
          onPickPublishHour: controller.setPublishHour,
          onPickPublishMinute: controller.setPublishMinute,
        );
    }
  }

  void _onPrimaryPressed(
    _SurveyStep currentStep,
    List<_SurveyStep> sequence,
    SurveyCreateFormState state,
  ) {
    if (currentStep == _SurveyStep.schedule) {
      _submit(state);
      return;
    }
    _goToNext(sequence);
  }

  void _goToNext(List<_SurveyStep> sequence) {
    FocusScope.of(context).unfocus();
    if (_currentIndex >= sequence.length - 1) return;
    setState(() => _currentIndex += 1);
  }

  void _goToPrevious() {
    FocusScope.of(context).unfocus();
    if (_currentIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentIndex -= 1);
  }

  Future<void> _submit(SurveyCreateFormState form) async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    final entry = await ref.read(surveyCreateProvider.notifier).submit(form);
    if (!mounted) return;

    if (entry != null) {
      setState(() {
        _success = true;
        _submittedType = form.type;
        _submittedAllowCustomOptions = form.allowCustomOptions ?? false;
        _submittedScheduledAt = form.publishLater ? form.publishAt : null;
      });
      return;
    }

    final error = ref.read(surveyCreateProvider).error;
    final message = error is AppException
        ? error.message
        : 'Umfrage konnte nicht erstellt werden.';
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccessView(context);

    final state = ref.watch(surveyCreateFormProvider);
    final controller = ref.read(surveyCreateFormProvider.notifier);
    final submitting = ref.watch(surveyCreateProvider).isLoading;
    final theme = Theme.of(context);

    final sequence = _stepSequence(state);
    // Falls Typ-Wechsel den Index ungültig macht (z.B. Sequenz wurde
    // kürzer), klampfen.
    final safeIndex = _currentIndex.clamp(0, sequence.length - 1);
    final currentStep = sequence[safeIndex];
    final canAdvance = _isStepValid(currentStep, state) && !submitting;
    final subtitle = _subtitleFor(state);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            toolbarHeight: 104,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: submitting ? null : () => Navigator.of(context).pop(),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HeadlineSmallEmphasized(text: 'Umfrage erstellen'),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          body: AbsorbPointer(
            absorbing: submitting,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  Expanded(
                    child: _buildStep(currentStep, state, controller),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: submitting ? null : _goToPrevious,
                            child: const Text('Zurück'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: canAdvance
                                ? () => _onPrimaryPressed(
                                      currentStep,
                                      sequence,
                                      state,
                                    )
                                : null,
                            child: Text(
                              currentStep == _SurveyStep.schedule
                                  ? 'Veröffentlichen'
                                  : 'Weiter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (submitting)
          const Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Color(0x44000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);
    final type = _submittedType;
    if (type == null) {
      // Should not happen — _success wird nur gesetzt wenn submit
      // erfolgreich war (mit gültigem type). Fallback: einfach
      // schließen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceBright,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: theme.colorScheme.surfaceBright,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HeadlineSmallEmphasized(text: 'Umfrage erstellen'),
            Text(
              _successSubtitle(type, _submittedAllowCustomOptions),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SurveyCreateStepSuccess(
        type: type,
        allowCustomOptions: _submittedAllowCustomOptions,
        scheduledAt: _submittedScheduledAt,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _successSubtitle(SurveyType type, bool allowCustomOptions) {
    switch (type) {
      case SurveyType.yesNo:
        return 'JUP!/NÖ!-Umfrage';
      case SurveyType.election:
        return 'Wahl';
      case SurveyType.multiple:
        return allowCustomOptions
            ? 'Freitext-Optionen'
            : 'Festgelegte Optionen';
    }
  }
}
