import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

/// Zweite Meta-Zeile auf News-/Event-/Survey-Karten, die anzeigt, dass der
/// Beitrag einer Gruppe zugeordnet ist. Bei `null` rendert das Widget nichts —
/// Caller kann es bedenkenlos in jeden Card-Body hängen.
class GroupScopeMeta extends StatelessWidget {
  final String? groupName;

  const GroupScopeMeta({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final name = groupName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'Aus der Gruppe $name',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: BodySmall(text: name, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
