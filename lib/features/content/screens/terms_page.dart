import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/content/controllers/help_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/theme/markdown_config.dart';
import 'package:jup/shared/widgets/async_state_builder.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:markdown_widget/widget/markdown_block.dart';

@RoutePage()
class TermsPage extends ConsumerWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsProvider);

    return Scaffold(
      appBar: SubPageAppBar(titleText: "Nutzungs-\u00ADbedingungen"),
      body: AsyncStateBuilder(
        value: termsAsync,
        onRetry: () => ref.invalidate(termsProvider),
        data: (markdown) => ListView(
          children: [
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: MarkdownBlock(
                data: markdown.text,
                config: getMarkdownConfig(context),
              ).withPadding(16, 16, 16, 16),
            ),
          ],
        ),
      ),
    );
  }
}
