import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jup/features/news/controllers/news_create_form_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/news/screens/news_create/step1_category.dart';
import 'package:jup/features/news/screens/news_create/step2_basic_info.dart';
import 'package:jup/features/news/screens/news_create/step3_content.dart';
import 'package:jup/features/news/screens/news_create/step4_publish.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/media_picker.dart';
import 'package:jup/shared/widgets/media_source_sheet.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class NewsCreatePage extends ConsumerStatefulWidget {
  const NewsCreatePage({super.key});

  @override
  ConsumerState<NewsCreatePage> createState() => _NewsCreatePageState();
}

class _NewsCreatePageState extends ConsumerState<NewsCreatePage> {
  static const _stepCount = 4;

  final _pageController = PageController();
  final _mediaPicker = MediaPicker();
  int _currentStep = 0;
  bool _success = false;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = step);
    _pageController.jumpToPage(step);
  }

  Future<void> _onPrimaryPressed() async {
    if (_currentStep < _stepCount - 1) {
      _goToStep(_currentStep + 1);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    final form = ref.read(newsCreateFormProvider);
    final entry = await ref.read(newsCreateProvider.notifier).submit(form);
    if (!mounted) return;

    if (entry != null) {
      setState(() {
        _success = true;
        _scheduledAt = form.publishLater ? form.publishAt : null;
      });
      return;
    }

    final error = ref.read(newsCreateProvider).error;
    final message = error is AppException
        ? error.message
        : 'News konnte nicht erstellt werden.';
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<File?> _pickImageWithFeedback(
    ImageSource source, {
    CropAspectRatio? aspectRatio,
  }) async {
    try {
      return await _mediaPicker.pickImage(source, aspectRatio: aspectRatio);
    } on AppException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return null;
    }
  }

  Future<File?> _pickVideoWithFeedback(ImageSource source) async {
    try {
      return await _mediaPicker.pickVideo(source);
    } on AppException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return null;
    }
  }

  Future<({File file, bool isVideo})?> _pickBlockMedia() async {
    final choice = await askMediaChoice(context);
    if (choice == null) return null;

    switch (choice) {
      case MediaChoice.imageGallery:
        final f = await _pickImageWithFeedback(
          ImageSource.gallery,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
        );
        return f == null ? null : (file: f, isVideo: false);
      case MediaChoice.imageCamera:
        final f = await _pickImageWithFeedback(
          ImageSource.camera,
          aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
        );
        return f == null ? null : (file: f, isVideo: false);
      case MediaChoice.videoGallery:
        final f = await _pickVideoWithFeedback(ImageSource.gallery);
        return f == null ? null : (file: f, isVideo: true);
      case MediaChoice.videoCamera:
        final f = await _pickVideoWithFeedback(ImageSource.camera);
        return f == null ? null : (file: f, isVideo: true);
    }
  }

  bool _isCurrentStepValid(NewsCreateFormState s) {
    switch (_currentStep) {
      case 0:
        return s.isStep1Valid;
      case 1:
        return s.isStep2Valid;
      case 2:
        return s.isStep3Valid;
      case 3:
        return s.isStep4Valid;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccessView(context);

    final state = ref.watch(newsCreateFormProvider);
    final controller = ref.read(newsCreateFormProvider.notifier);
    final submitting = ref.watch(newsCreateProvider).isLoading;
    final isLast = _currentStep == _stepCount - 1;
    final canAdvance = _isCurrentStepValid(state) && !submitting;

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
            title: const HeadlineSmallEmphasized(text: 'News erstellen'),
          ),
          body: AbsorbPointer(
            absorbing: submitting,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _currentStep = i),
                      children: [
                        NewsCreateStep1Category(
                          selected: state.category,
                          onSelect: controller.setCategory,
                        ),
                        NewsCreateStep2BasicInfo(
                          state: state,
                          onTitleChanged: controller.setTitle,
                          onIntroChanged: controller.setIntroText,
                          onPickHero: () async {
                            final source = await askImageSource(context);
                            if (source == null) return;
                            final file = await _pickImageWithFeedback(
                              source,
                              aspectRatio: const CropAspectRatio(
                                ratioX: 16,
                                ratioY: 9,
                              ),
                            );
                            if (file != null) controller.setHeroImage(file);
                          },
                          onRemoveHero: () => controller.setHeroImage(null),
                        ),
                        NewsCreateStep3Content(
                          state: state,
                          onLeadChanged: controller.setLeadText,
                          onUpdateText: controller.updateTextBlock,
                          onAddText: controller.addTextBlock,
                          onAddMedia: () async {
                            final picked = await _pickBlockMedia();
                            if (picked == null) return;
                            controller.addMediaBlock(
                              file: picked.file,
                              isVideo: picked.isVideo,
                            );
                          },
                          onRemoveBlock: controller.removeBlock,
                        ),
                        NewsCreateStep4Publish(
                          state: state,
                          onToggle: controller.setPublishLater,
                          onPickDate: () =>
                              _pickDate(context, controller, state),
                          onPickHour: controller.setPublishHour,
                          onPickMinute: controller.setPublishMinute,
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentStep > 0) ...[
                            OutlinedButton(
                              onPressed: submitting
                                  ? null
                                  : () => _goToStep(_currentStep - 1),
                              child: const Text('Zurück'),
                            ),
                            const SizedBox(width: 12),
                          ],
                          FilledButton(
                            onPressed: canAdvance ? _onPrimaryPressed : null,
                            child: Text(isLast ? 'Veröffentlichen' : 'Weiter'),
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

  Future<void> _pickDate(
    BuildContext context,
    NewsCreateFormController controller,
    NewsCreateFormState state,
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

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledAt = _scheduledAt;
    final message = scheduledAt != null
        ? 'Deine News wird am ${_formatScheduled(scheduledAt)} Uhr veröffentlicht.\n'
            'Falls du sie nachträglich ändern oder löschen möchtest, nutze das CMS.'
        : 'Deine News wurde veröffentlicht.\n'
            'Falls du sie nachträglich ändern oder löschen möchtest, nutze das CMS.';

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
        title: const HeadlineSmallEmphasized(text: 'News erstellen'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BodyMedium(text: message),
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 160,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Schließen'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScheduled(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} um '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}
