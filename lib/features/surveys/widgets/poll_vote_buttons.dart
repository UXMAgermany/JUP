import 'package:flutter/material.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';

class PollVoteButtons extends StatelessWidget {
  final int yesVoteCount;
  final int noVoteCount;
  final int totalVotes;
  final bool? userVote; // true = yes, false = no, null = not voted
  final bool isDisabled;
  final bool isLoading;
  final VoidCallback? onYesTap;
  final VoidCallback? onNoTap;

  const PollVoteButtons({
    super.key,
    required this.yesVoteCount,
    required this.noVoteCount,
    required this.totalVotes,
    this.userVote,
    this.isDisabled = false,
    this.isLoading = false,
    this.onYesTap,
    this.onNoTap,
  });

  @override
  Widget build(BuildContext context) {
    final yesPercentage = totalVotes > 0
        ? (yesVoteCount / totalVotes) * 100
        : 0.0;
    final noPercentage = totalVotes > 0
        ? (noVoteCount / totalVotes) * 100
        : 0.0;

    final bool hasVoted = userVote != null;

    return Row(
      children: [
        // JUP (Yes) Button
        Expanded(
          child: _VoteButton(
            label: 'JUP',
            voteCount: yesVoteCount,
            percentage: yesPercentage,
            isSelected: userVote == true,
            isDisabled: isDisabled || isLoading,
            isLoading: isLoading && userVote == true,
            hasVoted: hasVoted,
            onTap: onYesTap,
          ),
        ),
        const SizedBox(width: 16),
        // NÖ (No) Button
        Expanded(
          child: _VoteButton(
            label: 'NÖ',
            voteCount: noVoteCount,
            percentage: noPercentage,
            isSelected: userVote == false,
            isDisabled: isDisabled || isLoading,
            isLoading: isLoading && userVote == false,
            hasVoted: hasVoted,
            onTap: onNoTap,
          ),
        ),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final int voteCount;
  final double percentage;
  final bool isSelected;
  final bool isDisabled;
  final bool isLoading;
  final bool hasVoted;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.label,
    required this.voteCount,
    required this.percentage,
    required this.isSelected,
    required this.isDisabled,
    required this.isLoading,
    required this.hasVoted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Loading indicator or label
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              TitleLarge(
                text: label,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
            const SizedBox(height: 16),
            // Progress bar
            if (hasVoted) ...[
              Stack(
                children: [
                  // Background
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress
                  FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ).withPaddingBottom(8),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BodySmall(
                    text: '${percentage.toStringAsFixed(1)}%',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BodySmall(
                        text: '$voteCount',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ).withPaddingRight(4),
                      Icon(
                        Icons.people,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            // Selected indicator
            if (isSelected)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ).withPaddingRight(4),
                  LabelSmall(
                    text: 'Deine Wahl',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ).withPaddingTop(8),
          ],
        ),
      ),
    );
  }
}
