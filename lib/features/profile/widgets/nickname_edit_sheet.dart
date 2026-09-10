import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/widgets/text_edit_sheet.dart';

class NicknameEditSheet extends ConsumerWidget {
  const NicknameEditSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    return TextEditSheet(
      title: 'Benutzernamen ändern',
      hint:
          'Dein Benutzername erscheint in allen von diesem Account erstellten Inhalten.',
      label: 'Benutzername',
      initialValue: user.nickname,
      onSave: (value) async {
        final updated =
            await ref.read(authProvider.notifier).updateNickname(value);
        if (updated == null) {
          throw AppException('Das hat nicht geklappt.');
        }
        return 'Alles klar, ${updated.nickname}.';
      },
    );
  }
}
