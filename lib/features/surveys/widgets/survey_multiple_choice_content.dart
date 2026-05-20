import 'package:flutter/material.dart';
import 'package:jup/features/surveys/models/custom_option_model.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/features/surveys/widgets/survey_option_item.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/new_badge.dart';
import 'package:jup/shared/widgets/text.dart';

class SurveyMultipleChoiceContent extends StatefulWidget {
  final SurveyEntry surveyEntry;
  final SurveyStatus status;
  final bool hasVoted;
  final bool showResults;
  final bool isNew;
  final bool isAdminBlocked;
  final bool isJUPAdmin;
  final int? userId;
  final String? optimisticVote;
  final Set<String> optimisticElectionVotes;
  final Set<String> optimisticallyHandledPendingDocIds;
  final VoidCallback? Function(SurveyOption option) onOptionTap;
  final VoidCallback? onCustomOptionTap;
  final VoidCallback? Function(CustomOption option)? onCustomOptionVoteTap;
  final void Function(CustomOption option)? onApproveCustomOption;
  final void Function(CustomOption option)? onRejectCustomOption;

  const SurveyMultipleChoiceContent({
    super.key,
    required this.surveyEntry,
    required this.status,
    required this.hasVoted,
    required this.showResults,
    required this.isNew,
    required this.isAdminBlocked,
    required this.onOptionTap,
    this.onCustomOptionTap,
    this.onCustomOptionVoteTap,
    this.onApproveCustomOption,
    this.onRejectCustomOption,
    this.isJUPAdmin = false,
    this.userId,
    this.optimisticVote,
    this.optimisticElectionVotes = const {},
    this.optimisticallyHandledPendingDocIds = const {},
  });

  @override
  State<SurveyMultipleChoiceContent> createState() =>
      _SurveyMultipleChoiceContentState();
}

class _SurveyMultipleChoiceContentState
    extends State<SurveyMultipleChoiceContent> {
  bool _optionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        if (widget.surveyEntry.subTitle != null)
          BodyMedium(
            text: widget.surveyEntry.subTitle!,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ).withPaddingTop(4),
        const SizedBox(height: 16),
        if (widget.surveyEntry.type == SurveyType.election &&
            widget.status == SurveyStatus.active)
          _buildElectionHints(context),
        if (widget.surveyEntry.options != null) _buildOptions(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InlineNewBadgeTitle(
            text: widget.surveyEntry.title,
            isNew: widget.isNew,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              size: 12,
              color: widget.status == SurveyStatus.expired
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            BodySmall(
              text: widget.surveyEntry.getTimeRemaining(),
              color: widget.status == SurveyStatus.expired
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElectionHints(BuildContext context) {
    if (widget.hasVoted) {
      return Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              BodySmall(
                text: 'Du hast abgestimmt',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    final serverVotes =
        widget.surveyEntry.options?.where((o) => o.currentUserVoted).length ??
            0;
    final remaining = widget.surveyEntry.maxVotes -
        serverVotes -
        widget.optimisticElectionVotes.length;
    if (remaining <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        BodySmall(
          text: widget.surveyEntry.maxVotes > 1
              ? 'Du kannst noch $remaining ${remaining == 1 ? 'Stimme' : 'Stimmen'} abgeben'
              : 'Gib deine Stimme ab',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOptions(BuildContext context) {
    final options = widget.surveyEntry.options!;
    final customOptions = widget.surveyEntry.approvedCustomOptions;
    final isElection = widget.surveyEntry.type == SurveyType.election;
    final totalOptionCount = options.length + customOptions.length;
    final showCollapse =
        totalOptionCount > 5 && widget.surveyEntry.type == SurveyType.multiple;

    // Build combined list of option widgets
    final allOptionWidgets = <Widget>[
      ...options.map((option) {
        final isSelected = isElection
            ? widget.optimisticElectionVotes.contains(option.text) ||
                option.currentUserVoted
            : widget.optimisticVote == option.text ||
                (widget.userId != null && option.hasUserVoted(widget.userId!));

        return SurveyOptionItem(
          option: option,
          totalVotes: widget.surveyEntry.totalVotes,
          isSelected: isSelected,
          isDisabled: widget.isAdminBlocked,
          showResults: widget.showResults,
          onTap: widget.onOptionTap(option),
        ).withPaddingBottom(8);
      }),
      ...customOptions.map((customOption) {
        final isSelected =
            widget.userId != null && customOption.hasUserVoted(widget.userId!);

        return SurveyOptionItem(
          option: SurveyOption(
            text: customOption.text,
            voterIds: customOption.voterIds,
          ),
          totalVotes: widget.surveyEntry.totalVotes,
          isSelected: isSelected,
          showResults: widget.showResults,
          onTap: widget.onCustomOptionVoteTap?.call(customOption),
        ).withPaddingBottom(8);
      }),
    ];

    final displayedWidgets = (!showCollapse || _optionsExpanded)
        ? allOptionWidgets
        : allOptionWidgets.take(5).toList();

    final visiblePending = widget.pendingOptionsToShow;

    return Column(
      children: [
        ...displayedWidgets,
        if (showCollapse)
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _optionsExpanded = !_optionsExpanded),
              icon: Icon(
                _optionsExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: LabelLarge(
                text: _optionsExpanded
                    ? 'Weniger Optionen anzeigen'
                    : 'Alle Optionen anzeigen',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        // Admin-only: pending custom options to review
        if (widget.isJUPAdmin &&
            visiblePending.isNotEmpty &&
            widget.status != SurveyStatus.expired) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: LabelLargeEmphasized(text: 'Zu prüfen'),
          ),
          const SizedBox(height: 8),
          ...visiblePending.map((option) => _buildPendingItem(context, option)),
        ],
        // "Antwort einreichen" button
        if (widget.surveyEntry.allowCustomOptions &&
            widget.status != SurveyStatus.expired)
          Center(
            child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: OutlinedButton(
                  onPressed: widget.onCustomOptionTap,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                  child: const Text('Antwort einreichen'),
                )),
          ),
      ],
    );
  }

  Widget _buildPendingItem(BuildContext context, CustomOption option) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outline, width: 1),
              ),
              child: BodyMedium(
                text: option.text,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PendingActionButton(
            icon: Icons.close,
            onPressed: widget.onRejectCustomOption == null
                ? null
                : () => widget.onRejectCustomOption!(option),
          ),
          const SizedBox(width: 8),
          _PendingActionButton(
            icon: Icons.check,
            onPressed: widget.onApproveCustomOption == null
                ? null
                : () => widget.onApproveCustomOption!(option),
          ),
        ],
      ),
    );
  }
}

extension on SurveyMultipleChoiceContent {
  List<CustomOption> get pendingOptionsToShow => surveyEntry
      .pendingCustomOptions
      .where((o) => !optimisticallyHandledPendingDocIds.contains(o.documentId))
      .toList();
}

class _PendingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _PendingActionButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(icon, color: colors.onPrimary, size: 20),
        ),
      ),
    );
  }
}
