import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/services/error_handler.dart';
import 'package:jup/shared/widgets/text.dart';

class PasswordEditSheet extends ConsumerStatefulWidget {
  const PasswordEditSheet({super.key});

  @override
  ConsumerState<PasswordEditSheet> createState() => _PasswordEditSheetState();
}

class _PasswordEditSheetState extends ConsumerState<PasswordEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _currentPwController;
  late TextEditingController _newPwController;
  final _currentPwFocus = FocusNode();
  final _newPwFocus = FocusNode();

  late String _currentPassword;
  late String _newPassword;

  late String? _currentPwError;
  late String? _error;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();

    _currentPassword = '';
    _newPassword = '';
    _error = null;
    _currentPwError = null;
    _currentPwController = TextEditingController(text: '');
    _newPwController = TextEditingController(text: '');

    // Trim current password on focus loss
    _currentPwFocus.addListener(() {
      if (!_currentPwFocus.hasFocus) {
        _currentPwController.text = _currentPwController.text.trim();
      }
    });

    // Trim new password on focus loss
    _newPwFocus.addListener(() {
      if (!_newPwFocus.hasFocus) {
        _newPwController.text = _newPwController.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _currentPwFocus.dispose();
    _newPwFocus.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  TitleMedium(text: "Passwort ändern"),
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
                text: "Dein Passwort sollte min. 8 Zeichen lang sein.",
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 16),
              TextFormField(
                obscureText: _obscureCurrentPassword,
                controller: _currentPwController,
                focusNode: _currentPwFocus,
                onChanged: (value) => setState(() => _currentPassword = value),
                decoration: InputDecoration(
                  labelText: 'Altes Passwort',
                  errorText: _currentPwError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Was vergessen?';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                obscureText: _obscureNewPassword,
                controller: _newPwController,
                focusNode: _newPwFocus,
                onChanged: (value) => setState(() => _newPassword = value),
                decoration: InputDecoration(
                  labelText: 'Neues Passwort (mind. 8 Zeichen)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Was vergessen?';
                  }
                  if (value.length < 8) {
                    return 'Das Passwort ist zu kurz. es muss mindestens 8 Zeichen haben.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    if (_error != null)
                      ErrorText(text: _error!).withPaddingBottom(8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed:
                          _currentPassword.isEmpty || _newPassword.isEmpty
                              ? null
                              : _onChangePassword,
                      child: const Text('Speichern'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onChangePassword() async {
    bool formValid = _formKey.currentState!.validate();
    if (!formValid) {
      return;
    }

    final authNotifier = ref.watch(authProvider.notifier);
    try {
      await authNotifier.changePassword(_currentPassword, _newPassword);
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Passwort aktualisiert.")));
          Navigator.pop(context);
        });
      }
    } catch (e) {
      // Special handling for wrong current password
      if (e.toString().contains("The provided current password is invalid")) {
        setState(() {
          _currentPwError = ErrorHandler.parseError(e);
        });
        return;
      }

      // Special handling for same password
      if (e.toString().contains("must be different")) {
        setState(() {
          _error = "Dein neues Passwort muss sich vom alten unterscheiden";
        });
        return;
      }

      setState(() {
        _error = ErrorHandler.parseError(e);
      });
    }
  }
}
