import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/widgets/forgot_password_sheet.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/default_app_bar.dart';
import 'package:jup/shared/widgets/pop_ups.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/services/error_handler.dart';

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String? _loginError;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Trim email on focus loss
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        emailCtrl.text = emailCtrl.text.trim();
      }
    });
    // Trim password on focus loss
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) {
        passwordCtrl.text = passwordCtrl.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.router.replaceAll([const ProfileRoute()]);
      });
    }

    Future<void> onLogin() async {
      bool formValid = _formKey.currentState!.validate();
      setState(() {
        _loginError = null;
      });

      if (formValid) {
        try {
          await authNotifier.login(emailCtrl.text, passwordCtrl.text);
        } catch (e) {
          final errorMessage = ErrorHandler.parseError(e);

          // Special handling for "Not confirmed" to show detailed dialog
          if (e.toString().contains("Not confirmed")) {
            setState(() {
              _loginError = errorMessage;
              showTextPopUpDialog(
                title: "Dein Account ist noch nicht verifiziert",
                description:
                    "Bevor du die App nutzen kannst musst du dich im Jugendzentrum verifizieren.\n\nWarum ist das so?\n\nDiese App richtet sich gezielt an Jugendliche aus der Region Süderbrarup. Ähnlich wie im Jugendzentrum soll die App ein geschützer Raum sein, zu dem nicht jeder Zugang hat. Deswegen musst du dich nach deiner Anmeldung einmalig mit deinem Ausweisdokument im Jugendzentrum verizifieren.",
                actions: [
                  Builder(
                    builder: (dialogContext) => TextButton(
                      child: const Text('Schließen'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.router.replaceAll([const MainRoute()]);
                      },
                    ),
                  ),
                ],
              );
            });
          } else {
            setState(() {
              _loginError = errorMessage;
            });
          }
        }
      }
    }

    return Scaffold(
      appBar: DefaultAppBar(titleText: "Einloggen", centerTitle: false),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TitleSmall(
                              text: "Dein Zugang zu allem, was Spaß macht.",
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'E-Mail-Adresse',
                              ),
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
                              controller: emailCtrl,
                              focusNode: _emailFocus,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Passwort (mind. 8 Zeichen)',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              controller: passwordCtrl,
                              focusNode: _passwordFocus,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Was vergessen?';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: Column(
                                children: [
                                  authState.isLoading
                                      ? const CircularProgressIndicator()
                                      : SizedBox(
                                          width: double.infinity,
                                          child: FilledButton(
                                            onPressed: onLogin,
                                            child: const Text('Einloggen'),
                                          ),
                                        ),
                                  if (_loginError != null)
                                    ErrorText(
                                      text: _loginError!,
                                    ).withPaddingTop(16),
                                  TextButton(
                                    onPressed: () {
                                      showModalBottomSheet<void>(
                                        context: context,
                                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                                        builder: (_) =>
                                            const ForgotPasswordSheet(),
                                      );
                                    },
                                    child: TitleSmall(
                                      text: 'Passwort vergessen?',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(), // Push register section to bottom
                      Column(
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text('Du hast noch keinen Account?'),
                                TextButton(
                                  onPressed: () {
                                    context.router.push(const RegisterRoute());
                                  },
                                  child: Text('Registrieren'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: RichText(
                              // textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Es gelten die ',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  TextSpan(
                                    text: 'Nutzungsbedingungen',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.router.push(TermsRoute());
                                      },
                                  ),
                                  TextSpan(
                                    text:
                                        '. Informationen zur Verarbeitung deiner Daten findest du in unserer ',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  TextSpan(
                                    text: 'Datenschutzerklärung',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.router.push(PrivacyRoute());
                                      },
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ).withPaddingX(16),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
