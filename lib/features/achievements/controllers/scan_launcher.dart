import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';

/// Message shown when a logged-out user hits a gated achievements action.
const String kAchievementsLoginMessage =
    'Melde dich an und entdecke alle unsere Inhalte!';

/// Opens the QR scanner when authenticated, otherwise shows the login prompt.
/// Shared by the drawer FAB and the achievements screen headers.
void openScannerOrLogin(BuildContext context, WidgetRef ref) {
  if (ref.read(authProvider).isAuthenticated) {
    context.router.push(const QrScannerRoute());
  } else {
    LoginRequiredDialog.show(context, message: kAchievementsLoginMessage);
  }
}
