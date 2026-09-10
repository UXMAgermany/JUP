import 'package:flutter/material.dart';
import 'package:jup/shared/utils/view_count_formatter.dart';
import 'package:jup/shared/widgets/text.dart';

/// Admin-only viewCount line shown below the survey subtitle.
class SurveyViewCount extends StatelessWidget {
  final int viewCount;

  const SurveyViewCount({super.key, required this.viewCount});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.visibility,
          size: 14,
          color: color,
          semanticLabel: '',
        ),
        const SizedBox(width: 4),
        BodySmall(text: formatViewCount(viewCount), color: color),
      ],
    );
  }
}
