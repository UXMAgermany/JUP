import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  final _emailFocus = FocusNode();

  late String _email;

  late String? _error;

  @override
  void initState() {
    super.initState();

    _email = '';
    _error = null;
    _emailController = TextEditingController(text: '');

    // Trim email on focus loss
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
                  TitleMedium(text: "Passwort vergessen"),
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
                text: "Keine Sorge, passiert den Besten.",
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                onChanged: (value) => setState(() => _email = value),
                decoration: InputDecoration(labelText: 'E-Mail-Adresse'),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Was vergessen?';
                  }

                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'Das ist keine gültige Email Adresse.';
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
                      onPressed: _email.isEmpty ? null : _onChangePassword,
                      child: const Text('Senden'),
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
      await authNotifier.forgotPassword(_email);
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Hilfe ist auf dem Weg.")));
          Navigator.pop(context);
        });
      }
    } catch (e) {
      String errorString = e.toString();
      if (errorString.contains("no acc")) {
        setState(() {
          _error = "Kein Account mit dieser E-Mail Adresse.";
        });
        return;
      } else if (errorString.contains("Connection closed")) {
        setState(() {
          _error =
              "Hoppla, hier stimmt was nicht mit der Verbindung. Versuch's nochmal.";
        });
      } else if (errorString.contains("Formatexception")) {
        setState(() {
          _error = "Ein unbekannter Fehler ist aufgetreten.";
        });
      } else {
        debugPrint(errorString);
        setState(() {
          _error = errorString;
        });
      }
    }
  }
}
