import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet_scaffold.dart';

class PasswordEditSheet extends ConsumerStatefulWidget {
  const PasswordEditSheet({super.key});

  @override
  ConsumerState<PasswordEditSheet> createState() => _PasswordEditSheetState();
}

class _PasswordEditSheetState extends ConsumerState<PasswordEditSheet> {
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _currentPwFocus = FocusNode();
  final _newPwFocus = FocusNode();

  String _currentPassword = '';
  String _newPassword = '';
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _currentPwFocus.addListener(() {
      if (!_currentPwFocus.hasFocus) {
        _currentPwController.text = _currentPwController.text.trim();
      }
    });
    _newPwFocus.addListener(() {
      if (!_newPwFocus.hasFocus) {
        _newPwController.text = _newPwController.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _currentPwFocus.dispose();
    _newPwFocus.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _currentPassword.isNotEmpty && _newPassword.length >= 8;
  }

  Future<String?> _save() async {
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(_currentPassword, _newPassword);
      return 'Passwort aktualisiert.';
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('The provided current password is invalid')) {
        throw AppException('Dein aktuelles Passwort stimmt nicht.');
      }
      if (raw.contains('must be different')) {
        throw AppException(
          'Dein neues Passwort muss sich vom alten unterscheiden.',
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return JupBottomSheetScaffold(
      title: 'Passwort ändern',
      hint: 'Dein Passwort sollte min. 8 Zeichen lang sein.',
      canSave: _canSave,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            obscureText: _obscureCurrent,
            controller: _currentPwController,
            focusNode: _currentPwFocus,
            onChanged: (value) => setState(() => _currentPassword = value),
            decoration: InputDecoration(
              labelText: 'Altes Passwort',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: _obscureNew,
            controller: _newPwController,
            focusNode: _newPwFocus,
            onChanged: (value) => setState(() => _newPassword = value),
            decoration: InputDecoration(
              labelText: 'Neues Passwort (mind. 8 Zeichen)',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
