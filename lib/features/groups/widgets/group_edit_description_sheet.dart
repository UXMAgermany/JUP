import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/shared/widgets/text_edit_sheet.dart';

class GroupEditDescriptionSheet extends ConsumerWidget {
  final String documentId;
  final String initialDescription;

  const GroupEditDescriptionSheet({
    super.key,
    required this.documentId,
    required this.initialDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextEditSheet(
      title: 'Beschreibung ändern',
      label: 'Beschreibung',
      initialValue: initialDescription,
      maxLength: 700,
      maxLines: 8,
      onSave: (value) async {
        await ref
            .read(groupsControllerProvider)
            .updateGroup(documentId: documentId, description: value);
        await refreshGroupProviders(ref, documentId);
        return null;
      },
    );
  }
}
