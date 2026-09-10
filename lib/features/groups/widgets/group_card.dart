import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/shared/widgets/text.dart';

/// Bestimmt, was in der Action-Row der Card erscheint: links der
/// "Beitreten"-Button (nur join/loggedOut), rechts entweder "In Prüfung"
/// (pending) oder die Mitgliederzahl (alle anderen Fälle).
enum GroupCardAction { join, pending, requestSent, member, admin, loggedOut }

class GroupCard extends StatelessWidget {
  final Group group;
  final GroupCardAction action;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.action,
    this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final memberCount = group.memberCount;
    final pendingCount = group.pendingRequests.length;
    final showPendingBadge =
        action == GroupCardAction.admin && pendingCount > 0;

    return Semantics(
      button: onTap != null,
      label: _semanticsLabel(memberCount),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildImage(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: TitleMedium(
                              text: group.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group.isHidden) ...[
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (showPendingBadge) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Badge(
                                label: Text(
                                  pendingCount > 99 ? '99+' : '$pendingCount',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      BodyMedium(
                        text: group.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildLeftSlot(context),
                          _buildRightSlot(context, memberCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final placeholderPath =
        'assets/banners/placeholder_groups_${isDarkMode ? 'dark' : 'light'}.svg';
    final placeholder = ClipRect(
      child: Transform.scale(
        scale: 1.2,
        child: SvgPicture.asset(placeholderPath, fit: BoxFit.cover),
      ),
    );
    if (group.imageUrl == null) {
      return placeholder;
    }
    // CachedNetworkImage cached fehlgeschlagene Loads selbst — wir
    // verlassen uns darauf und vermeiden einen lokalen Fail-State,
    // der setState in errorWidget triggern müsste.
    return CachedNetworkImage(
      imageUrl: group.imageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => placeholder,
      maxHeightDiskCache: 675,
      maxWidthDiskCache: 1200,
      memCacheHeight: 675,
      memCacheWidth: 1200,
    );
  }

  Widget _buildLeftSlot(BuildContext context) {
    switch (action) {
      case GroupCardAction.join:
      case GroupCardAction.loggedOut:
        return OutlinedButton.icon(
          onPressed: onActionTap,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Gruppe beitreten'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            visualDensity: VisualDensity.compact,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            side: BorderSide.none,
          ),
        );
      case GroupCardAction.pending:
      case GroupCardAction.requestSent:
      case GroupCardAction.member:
      case GroupCardAction.admin:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRightSlot(BuildContext context, int memberCount) {
    final colors = Theme.of(context).colorScheme;
    if (action == GroupCardAction.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BodySmall(text: 'In Prüfung', color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Icon(Icons.hourglass_empty, size: 12, color: colors.onSurfaceVariant),
        ],
      );
    }
    if (action == GroupCardAction.requestSent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BodySmall(text: 'Anfrage gesendet', color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Icon(Icons.hourglass_empty, size: 12, color: colors.onSurfaceVariant),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BodySmall(
          text: '$memberCount ${memberCount == 1 ? 'Mitglied' : 'Mitglieder'}',
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Icon(Icons.tag_faces, size: 12, color: colors.onSurfaceVariant),
      ],
    );
  }

  String _semanticsLabel(int memberCount) {
    final hiddenSuffix = group.isHidden ? ', versteckte Gruppe' : '';
    if (action == GroupCardAction.pending) {
      return '${group.name}, in Prüfung$hiddenSuffix';
    }
    final base =
        '${group.name}, $memberCount ${memberCount == 1 ? 'Mitglied' : 'Mitglieder'}, ${_semanticsActionLabel(action)}';
    final pendingCount = group.pendingRequests.length;
    if (action == GroupCardAction.admin && pendingCount > 0) {
      return '$base, $pendingCount ${pendingCount == 1 ? 'neue Beitrittsanfrage' : 'neue Beitrittsanfragen'}$hiddenSuffix';
    }
    return '$base$hiddenSuffix';
  }

  String _semanticsActionLabel(GroupCardAction action) {
    switch (action) {
      case GroupCardAction.join:
      case GroupCardAction.loggedOut:
        return 'beitreten möglich';
      case GroupCardAction.requestSent:
        return 'Anfrage gesendet';
      case GroupCardAction.pending:
        return 'in Prüfung';
      case GroupCardAction.member:
        return 'du bist Mitglied';
      case GroupCardAction.admin:
        return 'du bist Admin';
    }
  }
}
