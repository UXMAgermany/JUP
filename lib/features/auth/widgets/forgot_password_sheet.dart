import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet_scaffold.dart';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  String _email = '';

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        _emailController.text = _emailController.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSave => _email.trim().isNotEmpty;

  Future<String?> _save() async {
    final email = _email.trim();
    if (!_emailRegex.hasMatch(email)) {
      throw AppException('Das ist keine gültige Email Adresse.');
    }
    try {
      await ref.read(authProvider.notifier).forgotPassword(email);
      return 'Hilfe ist auf dem Weg.';
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('no acc')) {
        throw AppException('Kein Account mit dieser E-Mail Adresse.');
      }
      if (raw.contains('Connection closed')) {
        throw AppException(
          "Hoppla, hier stimmt was nicht mit der Verbindung. Versuch's nochmal.",
        );
      }
      if (raw.contains('Formatexception')) {
        throw AppException('Ein unbekannter Fehler ist aufgetreten.');
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return JupBottomSheetScaffold(
      title: 'Passwort vergessen',
      hint: 'Keine Sorge, passiert den Besten.',
      saveLabel: 'Senden',
      canSave: _canSave,
      onSave: _save,
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        onChanged: (value) => setState(() => _email = value),
        decoration: const InputDecoration(labelText: 'E-Mail-Adresse'),
      ),
    );
  }
}
