import 'package:flutter/foundation.dart';

/// Review status assigned by the CMS. A new group starts as `pending` until
/// the JUZ-Admin approves it in the Strapi admin; rejection happens as a
/// hard-delete with an email to the creator (no `rejected` state).
enum GroupReviewStatus { pending, approved }

extension GroupReviewStatusExt on GroupReviewStatus {
  static GroupReviewStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return GroupReviewStatus.approved;
      case 'pending':
      default:
        return GroupReviewStatus.pending;
    }
  }
}

/// Slim user summary embedded in a [Group]. `firstname`/`lastname` are only
/// populated by the backend when the requester is a group admin (or JUP
/// admin) — for everyone else those fields stay null. The app uses that
/// presence as the "show realname" signal so privacy is enforced server-side.
class GroupUserSummary {
  final int id;
  final String documentId;
  final String nickname;
  final String? firstname;
  final String? lastname;
  final String? localAvatarId;
  final String? avatarPath;

  const GroupUserSummary({
    required this.id,
    required this.documentId,
    required this.nickname,
    this.firstname,
    this.lastname,
    this.localAvatarId,
    this.avatarPath,
  });

  /// `Vorname Nachname`, or null if neither was sent (= requester not admin).
  String? get realName {
    final parts = [
      (firstname ?? '').trim(),
      (lastname ?? '').trim(),
    ].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  factory GroupUserSummary.fromJson(
    Map<String, dynamic> json,
    String baseUrl,
  ) {
    String? localAvatarId;
    String? avatarPath;
    final avatarData = json['avatarPath'];
    if (avatarData is String && avatarData.isNotEmpty) {
      if (avatarData.startsWith('local:')) {
        localAvatarId = avatarData.substring(6);
      } else {
        avatarPath =
            avatarData.startsWith('http') ? avatarData : baseUrl + avatarData;
      }
    } else if (json['localAvatarId'] is String) {
      localAvatarId = json['localAvatarId'] as String;
    }

    return GroupUserSummary(
      id: json['id'] as int,
      documentId: json['documentId'] as String,
      nickname: (json['username'] as String?) ?? '',
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      localAvatarId: localAvatarId,
      avatarPath: avatarPath,
    );
  }
}

class Group {
  final int id;
  final String documentId;
  final String name;
  final String description;
  final String? imageUrl;
  final GroupReviewStatus reviewStatus;

  /// CMS-kuratierte Gruppe: nicht in „Alle Gruppen" sichtbar, Beitritt nur
  /// über Strapi. Verwaltung (Edit/Promote/Demote/Remove/Delete) funktioniert
  /// für Gruppen-Admins wie in normalen Gruppen.
  final bool isHidden;
  final GroupUserSummary? creator;
  final List<GroupUserSummary> admins;

  /// Includes the admins — server returns the full member set, admins are a
  /// subset. Convenient because card UIs show "X Mitglieder" without
  /// computing a union.
  final List<GroupUserSummary> members;

  /// Only non-empty when the requester is an admin of this group (or JUP
  /// admin). Backend strips this list entirely otherwise, so a non-empty
  /// list implies admin rights.
  final List<GroupUserSummary> pendingRequests;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.documentId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.reviewStatus,
    this.isHidden = false,
    this.creator,
    this.admins = const [],
    this.members = const [],
    this.pendingRequests = const [],
    required this.createdAt,
  });

  int get memberCount => members.length;

  bool isAdmin(String userDocumentId) =>
      admins.any((a) => a.documentId == userDocumentId);

  bool isMember(String userDocumentId) =>
      members.any((m) => m.documentId == userDocumentId);

  bool hasPendingRequest(String userDocumentId) =>
      pendingRequests.any((r) => r.documentId == userDocumentId);

  bool get isSingleAdmin => admins.length == 1;

  /// Delete-Konsistenzregel: nur löschbar wenn JUZ-Admin oder Admin mit
  /// genau einem Admin (sich selbst).
  bool canBeDeletedBy(String userDocumentId, {required bool isJUPAdmin}) {
    if (isJUPAdmin) return true;
    return isAdmin(userDocumentId) && isSingleAdmin;
  }

  /// Verlassen-Konsistenzregel: Mitglied + (kein Admin ODER ≥ 2 Admins).
  bool canBeLeftBy(String userDocumentId) {
    if (!isMember(userDocumentId)) return false;
    if (!isAdmin(userDocumentId)) return true;
    return admins.length > 1;
  }

  factory Group.fromJson(Map<String, dynamic> json, String baseUrl) {
    try {
      String? imageUrl;
      final image = json['image'];
      if (image is Map && image['url'] is String) {
        final url = image['url'] as String;
        imageUrl = url.startsWith('http') ? url : baseUrl + url;
      }

      List<GroupUserSummary> parseUsers(dynamic raw) {
        if (raw is! List) return const [];
        final result = <GroupUserSummary>[];
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            try {
              result.add(GroupUserSummary.fromJson(item, baseUrl));
            } catch (e) {
              debugPrint('Failed to parse group user: $e');
            }
          }
        }
        return result;
      }

      GroupUserSummary? parseCreator(dynamic raw) {
        if (raw is Map<String, dynamic>) {
          try {
            return GroupUserSummary.fromJson(raw, baseUrl);
          } catch (e) {
            debugPrint('Failed to parse group creator: $e');
          }
        }
        return null;
      }

      return Group(
        id: json['id'] as int,
        documentId: json['documentId'] as String,
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        imageUrl: imageUrl,
        reviewStatus:
            GroupReviewStatusExt.fromString(json['reviewStatus'] as String?),
        isHidden: (json['isHidden'] as bool?) ?? false,
        creator: parseCreator(json['creator']),
        admins: parseUsers(json['admins']),
        members: parseUsers(json['members']),
        pendingRequests: parseUsers(json['pendingRequests']),
        createdAt:
            DateTime.parse(json['createdAt'] as String),
      );
    } catch (e) {
      throw ArgumentError('Failed to parse Group: $e');
    }
  }
}
