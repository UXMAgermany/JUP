import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/group_create_form_provider.dart';
import 'package:jup/features/groups/controllers/group_create_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/media_picker.dart';
import 'package:jup/shared/widgets/create_page_app_bar.dart';
import 'package:jup/shared/widgets/hero_image_upload_tile.dart';
import 'package:jup/shared/widgets/media_source_sheet.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class GroupCreatePage extends ConsumerStatefulWidget {
  const GroupCreatePage({super.key});

  @override
  ConsumerState<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends ConsumerState<GroupCreatePage> {
  final _mediaPicker = MediaPicker();
  bool _success = false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = ref.read(groupCreateFormProvider);
    final group = await ref.read(groupCreateProvider.notifier).submit(form);
    if (!mounted) return;

    if (group != null) {
      setState(() => _success = true);
      return;
    }
    final error = ref.read(groupCreateProvider).error;
    final message = error is AppException
        ? error.message
        : 'Gruppe konnte nicht erstellt werden.';
    context.showAppSnackbar(message);
  }

  Future<File?> _pickHeroImage(ImageSource source) async {
    try {
      return await _mediaPicker.pickImage(
        source,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      );
    } on AppException catch (e) {
      if (!mounted) return null;
      context.showAppSnackbar(e.message);
      return null;
    }
  }

  Future<void> _onPickImage(GroupCreateFormController controller) async {
    final source = await askImageSource(context);
    if (source == null) return;
    final file = await _pickHeroImage(source);
    if (file != null) controller.setHeroImage(file);
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccessView(context);

    // Defensive client-side check — backend is the source of truth.
    final canCreate = ref.watch(canUserCreateGroupProvider);
    if (!canCreate) {
      final user = ref.watch(authProvider).user;
      final hasPermission =
          (user?.isJUPAdmin ?? false) || (user?.canCreateGroup ?? false);
      return hasPermission
          ? _buildAlreadyAdminView(context)
          : _buildNoPermissionView(context);
    }

    final state = ref.watch(groupCreateFormProvider);
    final controller = ref.read(groupCreateFormProvider.notifier);
    final submitting = ref.watch(groupCreateProvider).isLoading;
    final canSubmit = state.isReadyToSubmit && !submitting;

    return Stack(
      children: [
        Scaffold(
          // MainPage-Scaffold (Eltern) handelt den Keyboard-Inset bereits.
          // Ohne diesen Flag würde dieses verschachtelte Scaffold den Inset
          // ein zweites Mal abziehen (MediaQuery wird in main_page.dart via
          // removePadding mit Aussen-Context weitergereicht und leakt die
          // unkonsumierten viewInsets in den Sub-Tree) — Folge: Body wird
          // doppelt geschrumpft, Footer-Button hüpft beim Öffnen der Tastatur.
          resizeToAvoidBottomInset: false,
          appBar: CreatePageAppBar(
            title: 'Gruppe erstellen',
            onClose: submitting ? null : () => Navigator.of(context).pop(),
          ),
          body: AbsorbPointer(
            absorbing: submitting,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BodyMedium(
                            text:
                                'Erstellst du eine Gruppe, bist du automatisch Admin und kannst für die Gruppe News schreiben, Umfragen erstellen und Events veröffentlichen.',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 24),
                          _NameSection(
                            name: state.name,
                            onChanged: controller.setName,
                          ),
                          const SizedBox(height: 24),
                          _ImageSection(
                            heroImage: state.heroImage,
                            onPick: () => _onPickImage(controller),
                            onRemove: () => controller.setHeroImage(null),
                          ),
                          const SizedBox(height: 24),
                          _DescriptionSection(
                            description: state.description,
                            onChanged: controller.setDescription,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Center(
                        child: FilledButton(
                          onPressed: canSubmit ? _submit : null,
                          child: const Text('Weiter'),
                        ),
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

  Widget _buildAlreadyAdminView(BuildContext context) {
    return Scaffold(
      appBar: CreatePageAppBar(
        title: 'Gruppe erstellen',
        onClose: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const TitleLargeEmphasized(
                text: 'Du bist bereits Gruppen-Admin',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const BodyMedium(
                text:
                    'Du kannst nur eine Gruppe gleichzeitig gründen. Verlasse zuerst deine bestehende Gruppe (oder lösche sie), um eine neue zu gründen.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPermissionView(BuildContext context) {
    return Scaffold(
      appBar: CreatePageAppBar(
        title: 'Gruppe erstellen',
        onClose: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const TitleLargeEmphasized(
                text: 'Keine Berechtigung',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const BodyMedium(
                text:
                    'Du hast aktuell keine Berechtigung, Gruppen zu erstellen. Wende dich an dein JUZ, wenn du eine Gruppe gründen möchtest.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Schließen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceBright,
      appBar: CreatePageAppBar(
        title: 'Gruppe erstellen',
        onClose: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyMedium(
                text:
                    'Deine Gruppe wurde erstellt und wird jetzt überprüft. Du erhältst eine E-Mail, sobald die Gruppe freigegeben oder abgelehnt wurde.',
              ),
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TitleMediumEmphasized(text: text),
    );
  }
}

class _NameSection extends StatelessWidget {
  final String name;
  final ValueChanged<String> onChanged;

  const _NameSection({required this.name, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Gib deiner Gruppe einen Namen.'),
        TextFormField(
          initialValue: name,
          onChanged: onChanged,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Gruppenname',
            border: OutlineInputBorder(),
            hintText: 'z.B. Jugendfeuerwehr Süderbrarup',
          ),
        ),
      ],
    );
  }
}

class _ImageSection extends StatelessWidget {
  final File? heroImage;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImageSection({
    required this.heroImage,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Wähle ein Bild für die Gruppe aus (optional).'),
        HeroImageUploadTile(
          file: heroImage,
          onPick: onPick,
          onRemove: onRemove,
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;
  final ValueChanged<String> onChanged;

  const _DescriptionSection({
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Beschreibe deine Gruppe.'),
        TextFormField(
          initialValue: description,
          onChanged: onChanged,
          maxLength: 700,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Beschreibungstext (max. 700 Zeichen)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
