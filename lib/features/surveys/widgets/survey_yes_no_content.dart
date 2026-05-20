import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/new_badge.dart';
import 'package:jup/shared/widgets/text.dart';

class SurveyYesNoContent extends StatelessWidget {
  final SurveyEntry surveyEntry;
  final SurveyStatus status;
  final bool hasVoted;
  final bool showResults;
  final bool isNew;
  final bool? optimisticVote;
  final int? userId;
  final VoidCallback? onVoteYes;
  final VoidCallback? onVoteNo;

  const SurveyYesNoContent({
    super.key,
    required this.surveyEntry,
    required this.status,
    required this.hasVoted,
    required this.showResults,
    required this.isNew,
    this.optimisticVote,
    this.userId,
    this.onVoteYes,
    this.onVoteNo,
  });

  @override
  Widget build(BuildContext context) {
    final userVotedYes = optimisticVote == true ||
        (surveyEntry.yesVoters?.contains(userId) ?? false);
    final userVotedNo = optimisticVote == false ||
        (surveyEntry.noVoters?.contains(userId) ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        if (surveyEntry.subTitle != null)
          BodyMedium(
            text: surveyEntry.subTitle!,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ).withPaddingTop(4),
        const SizedBox(height: 16),
        _buildVoteButtons(context, userVotedYes, userVotedNo),
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
            text: surveyEntry.title,
            isNew: isNew,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              size: 12,
              color: status == SurveyStatus.expired
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            BodySmall(
              text: surveyEntry.getTimeRemaining(),
              color: status == SurveyStatus.expired
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoteButtons(
    BuildContext context,
    bool userVotedYes,
    bool userVotedNo,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildVoteButton(
              context,
              assetPath: 'assets/icons/yes.svg',
              isSelected: hasVoted && userVotedYes,
              onTap: onVoteYes,
            ),
            const SizedBox(width: 16),
            _buildVoteButton(
              context,
              assetPath: 'assets/icons/no.svg',
              isSelected: hasVoted && userVotedNo,
              onTap: onVoteNo,
              useWhiteWhenSelected: true,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (showResults)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVoteCount(
                context,
                count: surveyEntry.yesVoteCount,
                isBold:
                    surveyEntry.yesVoteCount >= surveyEntry.noVoteCount,
              ),
              const SizedBox(width: 16),
              _buildVoteCount(
                context,
                count: surveyEntry.noVoteCount,
                isBold:
                    surveyEntry.noVoteCount > surveyEntry.yesVoteCount,
              ),
            ],
          ).withPaddingTop(4),
      ],
    );
  }

  Widget _buildVoteButton(
    BuildContext context, {
    required String assetPath,
    required bool isSelected,
    required VoidCallback? onTap,
    bool useWhiteWhenSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          isSelected ? BorderRadius.circular(16) : BorderRadius.circular(100),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: isSelected
              ? BorderRadius.circular(16)
              : BorderRadius.circular(100),
        ),
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: 45,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? (useWhiteWhenSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onPrimary)
                  : Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoteCount(
    BuildContext context, {
    required int count,
    required bool isBold,
  }) {
    return SizedBox(
      width: 56,
      child: Center(
        child: BodyMedium(
          text: '$count ${count == 1 ? 'Vote' : 'Votes'}',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
