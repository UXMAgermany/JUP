import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/widgets/group_edit_description_sheet.dart';
import 'package:jup/features/groups/widgets/group_edit_image_sheet.dart';
import 'package:jup/features/groups/widgets/group_edit_name_sheet.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet.dart';
import 'package:jup/shared/widgets/settings_tile.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
@RoutePage()
class GroupEditPage extends ConsumerWidget {
  final String documentId;
  const GroupEditPage({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupDetailProvider(documentId));
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: const SubPageAppBar(titleText: 'Gruppeninformationen'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ConnectionErrorWidget(
            errorMessage: error.toString(),
            onRetry: () => ref.invalidate(groupDetailProvider(documentId)),
          ),
        ),
        data: (group) {
          final userDocumentId = auth.user?.documentId;
          final isJUPAdmin = auth.user?.isJUPAdmin ?? false;
          // Hard-Block für Deep-Links / veraltete Navigation auf den Edit-Screen.
          final canEdit = isJUPAdmin ||
              (userDocumentId != null && group.isAdmin(userDocumentId));

          if (!canEdit) {
            return _NoEditPermission(
              onBack: () => context.router.maybePop(),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              SettingsCard(
                tiles: [
                  SettingsTile(
                    label: 'Name',
                    onTap: () => showJupBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => GroupEditNameSheet(
                        documentId: documentId,
                        initialName: group.name,
                      ),
                    ),
                  ),
                  SettingsTile(
                    label: 'Bild',
                    onTap: () => showJupBottomSheet<void>(
                      context: context,
                      builder: (_) => GroupEditImageSheet(
                        documentId: documentId,
                        initialImageUrl: group.imageUrl,
                      ),
                    ),
                  ),
                  SettingsTile(
                    label: 'Beschreibung',
                    isLast: true,
                    onTap: () => showJupBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => GroupEditDescriptionSheet(
                        documentId: documentId,
                        initialDescription: group.description,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoEditPermission extends StatelessWidget {
  final VoidCallback onBack;
  const _NoEditPermission({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Du hast keine Berechtigung, diese Gruppe zu bearbeiten.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBack,
              child: const Text('Zurück'),
            ),
          ],
        ),
      ),
    );
  }
}
