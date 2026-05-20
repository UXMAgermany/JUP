import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Helper class for avatar-related functionality
/// Handles both local SVG avatars and CMS-uploaded avatars
class AvatarHelper {
  /// Available local avatar IDs (01-16)
  static const List<String> availableAvatarIds = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
  ];

  /// Default fallback avatar path
  static const String fallbackAvatarPath = 'assets/avatars/simple_avatar.svg';

  /// Get the correct SVG path for a local avatar based on theme
  ///
  /// [id] - Avatar ID (e.g., "01", "02")
  /// [brightness] - Current theme brightness
  static String getLocalAvatarPath(String id, Brightness brightness) {
    final suffix = brightness == Brightness.dark ? 'light' : 'dark';
    return 'assets/avatars/${id}_$suffix.svg';
  }

  /// Build avatar widget with proper handling for local SVGs and CMS avatars
  ///
  /// [localAvatarId] - ID of local SVG avatar (e.g., "01")
  /// [cmsAvatarUrl] - Full URL to CMS-uploaded avatar
  /// [brightness] - Current theme brightness for SVG selection
  /// [size] - Size of the avatar (width and height)
  static Widget buildAvatar({
    String? localAvatarId,
    String? cmsAvatarUrl,
    required Brightness brightness,
    double size = 120,
  }) {
    // Priority 1: Local SVG avatar
    if (localAvatarId != null && localAvatarId.isNotEmpty) {
      final path = getLocalAvatarPath(localAvatarId, brightness);
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    // Priority 2: CMS avatar
    if (cmsAvatarUrl != null && cmsAvatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cmsAvatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => SizedBox(width: size, height: size),
        errorWidget: (context, url, error) {
          // Fallback to default avatar on network error
          return SvgPicture.asset(
            fallbackAvatarPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      );
    }

    // Priority 3: Fallback avatar
    return SvgPicture.asset(
      fallbackAvatarPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  /// Parse backend avatar string into localAvatarId and cmsAvatarUrl
  ///
  /// Backend sends either:
  /// - "local:01" for local avatars
  /// - Full URL for CMS avatars
  ///
  /// Returns a map with 'localAvatarId' and 'cmsAvatarUrl' keys
  static Map<String, String?> parseAvatarString(String? avatarString) {
    if (avatarString == null || avatarString.isEmpty) {
      return {'localAvatarId': null, 'cmsAvatarUrl': null};
    }

    if (avatarString.startsWith('local:')) {
      // Extract local avatar ID
      final id = avatarString.substring(6); // Remove "local:" prefix
      return {'localAvatarId': id, 'cmsAvatarUrl': null};
    }

    // It's a CMS avatar URL
    return {'localAvatarId': null, 'cmsAvatarUrl': avatarString};
  }

  /// Format avatar data for backend API
  ///
  /// Converts localAvatarId or cmsAvatarUrl into the format backend expects
  static String? formatAvatarForBackend({
    String? localAvatarId,
    String? cmsAvatarUrl,
  }) {
    if (localAvatarId != null && localAvatarId.isNotEmpty) {
      return 'local:$localAvatarId';
    }

    if (cmsAvatarUrl != null && cmsAvatarUrl.isNotEmpty) {
      return cmsAvatarUrl;
    }

    return null;
  }
}
