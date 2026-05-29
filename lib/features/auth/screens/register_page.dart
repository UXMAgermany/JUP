import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/widgets/checkbox_form_field.dart';
import 'package:jup/features/files/controllers/file_provider.dart';
import 'package:jup/features/files/models/file_model.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/widgets/main_app_bar.dart';
import 'package:jup/router/widgets/main_app_drawer.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _nicknameFocus = FocusNode();
  final _firstnameFocus = FocusNode();
  final _lastnameFocus = FocusNode();

  DateTime? _birthday;

  String? _registerError;

  StrapiFile? _avatar;
  String? _localAvatarId;
  bool _acceptedCodex = false;
  bool _acceptedTracking = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Add focus listeners to trim on blur
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        _emailCtrl.text = _emailCtrl.text.trim();
      }
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) {
        _passwordCtrl.text = _passwordCtrl.text.trim();
      }
    });
    _nicknameFocus.addListener(() {
      if (!_nicknameFocus.hasFocus) {
        _nicknameCtrl.text = _nicknameCtrl.text.trim();
      }
    });
    _firstnameFocus.addListener(() {
      if (!_firstnameFocus.hasFocus) {
        _firstnameCtrl.text = _firstnameCtrl.text.trim();
      }
    });
    _lastnameFocus.addListener(() {
      if (!_lastnameFocus.hasFocus) {
        _lastnameCtrl.text = _lastnameCtrl.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nicknameFocus.dispose();
    _firstnameFocus.dispose();
    _lastnameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);
    final avatarList = ref.watch(avatarsProvider);

    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.router.replaceAll([const MainRoute()]);
      });
    }

    Future<void> onSubmit() async {
      bool formValid = _formKey.currentState!.validate();
      setState(() {
        _registerError = null;
      });

      if (formValid && _acceptedCodex) {
        try {
          String? avatarPath;
          if (_localAvatarId != null) {
            avatarPath = 'local:$_localAvatarId';
          } else if (_avatar != null) {
            avatarPath = _avatar!.path;
          }

          await authNotifier.register(
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim(),
            _nicknameCtrl.text.trim(),
            _firstnameCtrl.text.trim(),
            _lastnameCtrl.text.trim(),
            _birthday!,
            avatarPath,
            _acceptedTracking,
          );

          if (context.mounted) {
            context.router.replaceAll([const RegisterSuccessRoute()]);
          }
        } catch (e) {
          String errorText = e.toString();
          if (errorText.contains("Email or Username are already taken")) {
            setState(() {
              _registerError =
                  "Dein Benutzername oder deine E-Mail ist bereits vergeben. Versuche es mit einem anderen Benutzernamen, wenn du dich noch nicht registriert hast.";
            });
          } else if (errorText.contains("Forbidden")) {
            setState(() {
              _registerError = "Forbidden(403)";
            });
          } else {
            _registerError = "Da ist was schief gelaufen: $errorText";
          }
        }
      }
    }

    DateTime now = DateTime.now();

    // Check if user is 16 or older based on selected birthday
    bool isUserOver16() {
      if (_birthday == null) return false;

      final age = now.year - _birthday!.year;
      final hasHadBirthdayThisYear = now.month > _birthday!.month ||
          (now.month == _birthday!.month && now.day >= _birthday!.day);

      final actualAge = hasHadBirthdayThisYear ? age : age - 1;
      return actualAge >= 16;
    }

    return Scaffold(
      appBar: const MainAppBar(
        activeTab: NavigationElement.profile,
        titleOverride: "Erstelle deinen Account",
      ),
      drawer: const MainAppDrawer(),
      body: SafeArea(
        child: ListView(
          children: [
            TitleSmall(
              text:
                  "Datenschutz:\nDeine Daten bleiben bei uns. In der App wird später nur dein Benutzername sichtbar.",
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: <Widget>[
                  TextFormField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
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
                  ),
                  TextFormField(
                    controller: _passwordCtrl,
                    focusNode: _passwordFocus,
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
                    validator: (String? value) {
                      if (value == null) {
                        return 'Was vergessen?';
                      } else if (value.length < 8) {
                        return 'Das sind keine 8 Zeichen.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nicknameCtrl,
                    focusNode: _nicknameFocus,
                    decoration: const InputDecoration(
                      labelText: 'Benutzername',
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Was vergessen?';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _firstnameCtrl,
                    focusNode: _firstnameFocus,
                    decoration: const InputDecoration(
                      labelText: 'Vorname (wie im Ausweis)',
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Was vergessen?';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _lastnameCtrl,
                    focusNode: _lastnameFocus,
                    decoration: const InputDecoration(
                      labelText: 'Nachname (wie im Ausweis)',
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Was vergessen?';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Geburtstag (wie im Ausweis)',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _birthday != null
                          ? DateFormatHelper.formatDate(_birthday)
                          : '',
                    ),
                    validator: (value) {
                      if (_birthday == null) {
                        return 'Was vergessen?';
                      }

                      // Calculate age
                      final age = now.year - _birthday!.year;
                      final hasHadBirthdayThisYear =
                          now.month > _birthday!.month ||
                              (now.month == _birthday!.month &&
                                  now.day >= _birthday!.day);
                      final actualAge = hasHadBirthdayThisYear ? age : age - 1;

                      if (actualAge < 12) {
                        return 'Du musst mindestens 12 Jahre alt sein.';
                      }
                      if (actualAge > 18) {
                        return 'Du darfst höchstens 18 Jahre alt sein, um die App zu nutzen.';
                      }
                      return null;
                    },
                    onTap: () async {
                      FocusScope.of(
                        context,
                      ).requestFocus(FocusNode()); // prevent keyboard
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(
                          now.year - 15,
                          now.month,
                          now.day,
                        ),
                        firstDate: DateTime(now.year - 18, now.month, now.day),
                        lastDate: DateTime(now.year - 12, now.month, now.day),
                      );
                      if (picked != null) {
                        setState(() {
                          _birthday = picked;
                        });
                      }
                    },
                  ),
                  Center(
                    child: Column(
                      children: [
                        TitleSmall(
                          text:
                              "Wähle einen Avatar aus, wenn du willst. Du kannst ihn später wieder ändern.",
                        ),
                        Center(
                          child: ClipOval(
                            child: AvatarHelper.buildAvatar(
                              localAvatarId: _localAvatarId,
                              cmsAvatarUrl: _avatar?.url,
                              brightness: Theme.of(context).brightness,
                              size: 100,
                            ),
                          ),
                        ).withPaddingTop(16),
                        Divider(height: 1).withPaddingY(16),
                        SizedBox(
                          height: 48,
                          child: Builder(
                            builder: (context) {
                              final cmsAvatars = avatarList.value ?? [];

                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    AvatarHelper.availableAvatarIds.length +
                                        cmsAvatars.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  // Local avatars come first
                                  if (index <
                                      AvatarHelper.availableAvatarIds.length) {
                                    final avatarId =
                                        AvatarHelper.availableAvatarIds[index];
                                    final isSelected =
                                        _localAvatarId == avatarId;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _localAvatarId = avatarId;
                                          _avatar = null;
                                        });
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: ClipOval(
                                          child: AvatarHelper.buildAvatar(
                                            localAvatarId: avatarId,
                                            cmsAvatarUrl: null,
                                            brightness: Theme.of(
                                              context,
                                            ).brightness,
                                            size: 48,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    // CMS avatars come after local avatars
                                    final cmsIndex = index -
                                        AvatarHelper.availableAvatarIds.length;
                                    final file = cmsAvatars[cmsIndex];
                                    final isSelected = _avatar?.id == file.id;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _avatar = file;
                                          _localAvatarId = null;
                                        });
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  width: 3,
                                                )
                                              : null,
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: file.url,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const SizedBox(
                                              width: 48,
                                              height: 48,
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ).withPaddingY(16),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'Bevor du die App nutzen kannst, musst du dich im Jugendzentum verifizieren. ',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextSpan(
                          text: 'Warum?',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.router.push(VerificationRoute());
                            },
                        ),
                      ],
                    ),
                  ),
                  CheckboxFormField(
                    title: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pflichtfeld: Ich habe den ',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          TextSpan(
                            text: 'Verhaltenskodex',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.router.push(CodeOfConductRoute());
                              },
                          ),
                          TextSpan(
                            text: ' gelesen und stimme diesem zu.',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    value: _acceptedCodex,
                    onChanged: (bool? value) => setState(() {
                      _acceptedCodex = value == true;
                    }),
                    validator: (bool? value) {
                      if (value == null || value == false) {
                        return 'Das musst du lesen und akzeptieren.';
                      }
                      return null;
                    },
                  ),
                  if (isUserOver16())
                    CheckboxFormField(
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'Optional: Ich möchte zur Verbesserung von JUP pseudonymisierte Nutzungsdaten teilen. ',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            TextSpan(
                              text: 'Mehr erfahren',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
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
                          ],
                        ),
                      ),
                      value: _acceptedTracking,
                      onChanged: (bool? value) => setState(() {
                        _acceptedTracking = value == true;
                      }),
                    ),
                ],
              ),
            ),
            Center(
              child: Column(
                children: [
                  authState.isLoading
                      ? const CircularProgressIndicator()
                      : FilledButton(
                          onPressed: _acceptedCodex ? onSubmit : null,
                          child: const Text('Registrieren'),
                        ),
                  if (_registerError != null)
                    ErrorText(text: _registerError!).withPaddingTop(8),
                  TitleSmall(
                    text: "Du hast schon einen Account?",
                  ).withPaddingTop(24),
                  TextButton(
                    onPressed: () {
                      context.router.push(LoginRoute());
                    },
                    child: const Text('Einloggen'),
                  ),
                ],
              ),
            ),
          ],
        ).withPaddingX(16),
      ),
    );
  }
}
