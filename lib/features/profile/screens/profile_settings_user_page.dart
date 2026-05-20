import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/models/user_model.dart';
import 'package:jup/features/files/controllers/file_provider.dart';
import 'package:jup/features/profile/widgets/nickname_edit_sheet.dart';
import 'package:jup/features/profile/widgets/password_edit_sheet.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/services/error_handler.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

List<String> newAvatarSuccessMessages = [
  "Schick!",
  "Oh wie süß.",
  "Fresh!",
  "Wow, richtig cool!",
  "Sieht super aus!",
  "Mega nice!",
  "Stylish!",
  "Neuer Avatar, neues Glück!",
];

@RoutePage()
class ProfileSettingsUserPage extends ConsumerStatefulWidget {
  const ProfileSettingsUserPage({super.key});

  @override
  ConsumerState<ProfileSettingsUserPage> createState() =>
      _ProfileSettingsUserPageState();
}

class _ProfileSettingsUserPageState
    extends ConsumerState<ProfileSettingsUserPage> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final User? user = authState.user;

    tapNickname() {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        builder: (_) => const NicknameEditSheet(),
      );
    }

    tapPassword() {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        builder: (_) => const PasswordEditSheet(),
      );
    }

    String randomFeedback() {
      final random = Random();
      int index = random.nextInt(newAvatarSuccessMessages.length);
      return newAvatarSuccessMessages[index];
    }

    Future<void> onChangeAvatar(newAvatarPath) async {
      final authNotifier = ref.watch(authProvider.notifier);
      _error = null;

      try {
        User? updatedUser = await authNotifier.updateAvatar(newAvatarPath);
        if (context.mounted && updatedUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(randomFeedback())));
          });
        }
      } catch (e) {
        setState(() {
          _error = ErrorHandler.parseError(e);
        });
      }
    }

    return Scaffold(
      appBar: SubPageAppBar(titleText: "Profil\u00ADinformationen"),
      body: SafeArea(
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Center(
                    child: ClipOval(
                      child: AvatarHelper.buildAvatar(
                        localAvatarId: user?.localAvatarId,
                        cmsAvatarUrl: user?.avatarPath,
                        brightness: Theme.of(context).brightness,
                        size: 120,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TitleMedium(text: "Wähle einen Avatar aus."),
                  SizedBox(height: 16),
                  // Avatar Selection (Local + CMS)
                  SizedBox(
                    height: 48,
                    child: Builder(
                      builder: (context) {
                        final cmsAvatars =
                            ref.watch(avatarsProvider).valueOrNull ?? [];

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AvatarHelper.availableAvatarIds.length +
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
                                  user?.localAvatarId == avatarId;

                              return GestureDetector(
                                onTap: () => onChangeAvatar('local:$avatarId'),
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
                                      brightness: Theme.of(context).brightness,
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
                              final isSelected = user?.avatarPath != null &&
                                  user!.avatarPath!.contains(file.path);

                              return GestureDetector(
                                onTap: () => onChangeAvatar(file.path),
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
                                      errorWidget: (context, url, error) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ).withPaddingX(16);
                      },
                    ),
                  ),

                  if (_error != null)
                    ErrorText(text: _error.toString())
                        .withPadding(16, 16, 16, 0),
                ],
              ),
            ).withPaddingY(16),
            Container(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: tapNickname,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BodyLarge(text: "Benutzername"),
                        BodyMedium(text: user!.nickname, softWrap: true),
                      ],
                    ).withPadding(12, 8, 12, 8),
                  ),
                  Divider(height: 1).withPaddingY(8),
                  GestureDetector(
                    onTap: tapPassword,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BodyLarge(text: "Passwort"),
                        BodyMedium(text: "********"),
                      ],
                    ).withPadding(12, 8, 12, 8),
                  ),
                ],
              ).withPaddingX(16),
            ),
          ],
        ),
      ),
    );
  }
}
