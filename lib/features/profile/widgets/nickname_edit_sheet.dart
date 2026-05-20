import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/models/user_model.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/shared/services/error_handler.dart';

class NicknameEditSheet extends ConsumerStatefulWidget {
  const NicknameEditSheet({super.key});

  @override
  ConsumerState<NicknameEditSheet> createState() => _NicknameEditSheetState();
}

class _NicknameEditSheetState extends ConsumerState<NicknameEditSheet> {
  late TextEditingController _controller;
  final _nicknameFocus = FocusNode();
  late String _initialNickname;
  String _nickname = '';
  late String? _error;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);

    final user = authState.user;
    _initialNickname = user!.nickname;
    _nickname = user.nickname;
    _error = null;
    _controller = TextEditingController(text: user.nickname);

    // Trim nickname on focus loss
    _nicknameFocus.addListener(() {
      if (!_nicknameFocus.hasFocus) {
        _controller.text = _controller.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _nicknameFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(
              child: Icon(
                Icons.remove_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TitleMedium(text: "Benutzernamen ändern"),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: LabelLarge(
                    text: 'Abbrechen',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TitleSmall(
              text:
                  "Dein Benutzername erscheint in allen von diesem Account erstellten Inhalten.",
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              focusNode: _nicknameFocus,
              onChanged: (value) => setState(() => _nickname = value),
              decoration: const InputDecoration(labelText: 'Benutzername'),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Was vergessen?';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            if (_error != null) ErrorText(text: _error!).withPaddingBottom(8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed:
                  _nickname == _initialNickname ? null : _onChangeNickname,
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onChangeNickname() async {
    if (_nickname.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Was vergessen?")));
      }
      return;
    }
    final authNotifier = ref.watch(authProvider.notifier);
    try {
      User? updatedUser = await authNotifier.updateNickname(_nickname);
      if (context.mounted && updatedUser != null) {
        String newName = updatedUser.nickname;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Alles klar, $newName. ")));
          Navigator.pop(context);
        });
      } else {
        setState(() {
          _error = "Das hat nicht geklappt.";
        });
      }
    } catch (e) {
      setState(() {
        _error = ErrorHandler.parseError(e);
      });
    }
  }
}
