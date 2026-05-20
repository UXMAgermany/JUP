import 'package:flutter/material.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/widgets/text.dart';

class SurveyOptionItem extends StatelessWidget {
  final SurveyOption option;
  final int totalVotes;
  final bool isSelected;
  final bool isDisabled;
  final bool showResults;
  final VoidCallback? onTap;

  const SurveyOptionItem({
    super.key,
    required this.option,
    required this.totalVotes,
    this.isSelected = false,
    this.isDisabled = false,
    this.showResults = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = option.getPercentage(totalVotes);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Option text and vote count
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: BodyMedium(
                    text: option.text,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (showResults)
                  BodySmall(
                    text: '${option.voteCount}',
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        // Progress bar
        if (showResults)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 4,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    ),
    );
  }
}
