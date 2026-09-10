import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/shared/widgets/text_edit_sheet.dart';

class GroupEditNameSheet extends ConsumerWidget {
  final String documentId;
  final String initialName;

  const GroupEditNameSheet({
    super.key,
    required this.documentId,
    required this.initialName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextEditSheet(
      title: 'Namen ändern',
      label: 'Gruppenname',
      initialValue: initialName,
      maxLength: 60,
      onSave: (value) async {
        await ref
            .read(groupsControllerProvider)
            .updateGroup(documentId: documentId, name: value);
        await refreshGroupProviders(ref, documentId);
        return null;
      },
    );
  }
}
