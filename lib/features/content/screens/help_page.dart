import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/content/controllers/help_provider.dart';
import 'package:jup/features/content/models/faq_model.dart';
import 'package:jup/features/content/models/help_model.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/url_helper.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final int _tabIndex = tabIndexOf(NavigationElement.help);
  bool _isRegistered = false;
  final Map<String, ExpansibleController> _expansionControllers = {};
  final Map<String, bool> _expansionStates = {};
  late final TabController _tabController;
  late Future<List<Faq>> _faqFuture;
  List<ExpansibleController> _faqExpansionControllers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final faqController = ref.read(faqControllerProvider);
    _faqFuture = faqController.fetchFaq().then((faqs) {
      _faqExpansionControllers = List.generate(
        faqs.length,
        (index) => ExpansibleController(),
      );
      return faqs;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(_tabIndex, _scrollController);
        _isRegistered = true;
      }
    });
  }

  @override
  void dispose() {
    if (_isRegistered) {
      try {
        ref
            .read(scrollControllerProvider.notifier)
            .unregisterController(_tabIndex);
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    // Dispose all expansion controllers
    for (var controller in _expansionControllers.values) {
      controller.dispose();
    }
    for (var controller in _faqExpansionControllers) {
      controller.dispose();
    }
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    // Remove spaces and format for tel: URL
    final cleanNumber = phoneNumber.replaceAll(' ', '');
    final url = 'tel:$cleanNumber';
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Anruf konnte nicht getätigt werden.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Fehler beim Anrufen: ${e.toString()}')),
      );
    }
  }

  Future<void> openWhatsApp(String phoneNumber) async {
    // Remove spaces and format for international use
    final cleanNumber = phoneNumber.replaceAll(' ', '');
    final url = 'https://wa.me/$cleanNumber';
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp konnte nicht geöffnet werden. Ist es installiert?',
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Fehler beim Öffnen von WhatsApp: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> openWebsite(String url) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Website konnte nicht geöffnet werden.'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Fehler beim Öffnen der Website: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> openMaps(String address) async {
    // URL encode the address for use in maps URL
    final encodedAddress = Uri.encodeComponent(address);
    // Use Google Maps URL format which works on both iOS and Android
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Karte konnte nicht geöffnet werden.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Fehler beim Öffnen der Karte: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> sendEmail(String email) async {
    final url = 'mailto:$email';
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('E-Mail App konnte nicht geöffnet werden.'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Fehler beim Öffnen der E-Mail App: ${e.toString()}'),
        ),
      );
    }
  }

  Widget _buildTextWithClickablePhoneNumbers(String text) {
    // RegExp to match phone numbers (e.g., +49 151 12345678, 0151 12345678, etc.)
    final phoneRegex = RegExp(
      r'(\+?\d{1,4}[\s\-]?\(?\d{1,4}\)?[\s\-]?\d{1,4}[\s\-]?\d{1,9})',
    );
    final matches = phoneRegex.allMatches(text);

    if (matches.isEmpty) {
      return BodyMedium(text: text, softWrap: true);
    }

    List<TextSpan> spans = [];
    int currentPosition = 0;

    for (final match in matches) {
      // Add text before the phone number
      if (match.start > currentPosition) {
        spans.add(TextSpan(text: text.substring(currentPosition, match.start)));
      }

      // Add clickable phone number
      final phoneNumber = match.group(0)!;
      spans.add(
        TextSpan(
          text: phoneNumber,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => makePhoneCall(phoneNumber),
        ),
      );

      currentPosition = match.end;
    }

    // Add remaining text after last phone number
    if (currentPosition < text.length) {
      spans.add(TextSpan(text: text.substring(currentPosition)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }

  Widget buildHelpEntryCard(HelpEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleMedium(text: entry.title),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildTextWithClickablePhoneNumbers(entry.text),
                ),
                ...entry.phones.map(
                  (phoneEntry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        phoneEntry.toWhatsApp
                            ? SvgPicture.asset(
                                'assets/icons/whatsapp.svg',
                                height: 12,
                                width: 12,
                              )
                            : Icon(Icons.phone, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: InkWell(
                            onTap: () => phoneEntry.toWhatsApp
                                ? openWhatsApp(phoneEntry.number)
                                : makePhoneCall(phoneEntry.number),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  if (phoneEntry.label != null) ...[
                                    TextSpan(text: '${phoneEntry.label}: '),
                                  ],
                                  TextSpan(
                                    text: phoneEntry.number,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (entry.location != null && entry.location!.isNotEmpty)
                  InkWell(
                    onTap: () => openMaps(entry.location!),
                    child: Row(
                      children: [
                        Icon(Icons.place, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.location!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (entry.website != null && entry.website!.isNotEmpty)
                  InkWell(
                    onTap: () => openWebsite(entry.website!),
                    child: Row(
                      children: [
                        Icon(Icons.language, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: BodyMedium(
                            text: UrlHelper.formatUrlForDisplay(entry.website!),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (entry.email != null && entry.email!.isNotEmpty)
                  InkWell(
                    onTap: () => sendEmail(entry.email!),
                    child: Row(
                      children: [
                        Icon(Icons.email, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: BodyMedium(
                            text: entry.email!,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).withPaddingBottom(8);
  }

  Map<String, (List<HelpEntry>, int)> groupByCategory(List<HelpEntry> entries) {
    Map<String, (List<HelpEntry>, int)> grouped = {};
    for (var entry in entries) {
      // Default to "Sonstiges" if category is null or empty
      String categoryName = (entry.category == null || entry.category!.isEmpty)
          ? 'Sonstiges'
          : entry.category!;
      if (grouped.containsKey(categoryName)) {
        grouped[categoryName]!.$1.add(entry);
      } else {
        // Use first entry's order as category order, default to 999
        grouped[categoryName] = ([entry], entry.order ?? 999);
      }
    }

    // Sort entries within each category by order
    for (var category in grouped.keys) {
      grouped[category]!.$1.sort((a, b) {
        final orderA = a.order ?? 999;
        final orderB = b.order ?? 999;
        return orderA.compareTo(orderB);
      });
    }

    return grouped;
  }

  Widget buildEntriesList(
    List<HelpEntry> entries,
    String title,
    ScrollController scrollController,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BodyMedium(
                    text: 'Keine Einträge vorhanden..',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(helpEntriesProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut laden'),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -34,
              bottom: 50,
              child: Image.asset(
                'assets/banners/sad_star.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    }

    // Group entries by category
    final groupedEntries = groupByCategory(entries);

    // Sort categories by order, keep "Sonstiges" at the end
    final sortedCategories = groupedEntries.keys.toList()
      ..sort((a, b) {
        if (a == 'Sonstiges') return 1;
        if (b == 'Sonstiges') return -1;
        return groupedEntries[a]!.$2.compareTo(groupedEntries[b]!.$2);
      });

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0),
      itemCount: sortedCategories.length,
      separatorBuilder: (context, index) {
        // Hide divider if current or next tile is expanded
        final currentCategory = sortedCategories[index];
        final nextCategory = index + 1 < sortedCategories.length
            ? sortedCategories[index + 1]
            : null;

        final currentExpanded = _expansionStates[currentCategory] ?? false;
        final nextExpanded = nextCategory != null
            ? (_expansionStates[nextCategory] ?? false)
            : false;

        if (currentExpanded || nextExpanded) {
          return const SizedBox.shrink();
        }

        return Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        );
      },
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryEntries = groupedEntries[category]!.$1;

        return ExpansionTile(
          key: PageStorageKey<String>(category),
          controller: _expansionControllers.putIfAbsent(
            category,
            () => ExpansibleController(),
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          collapsedBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerLowest,
          title: BodyLarge(text: category),
          onExpansionChanged: (isExpanded) {
            setState(() {
              _expansionStates[category] = isExpanded;
              if (isExpanded) {
                // Collapse all other tiles
                for (var entry in _expansionControllers.entries) {
                  if (entry.key != category && entry.value.isExpanded) {
                    entry.value.collapse();
                    _expansionStates[entry.key] = false;
                  }
                }
              }
            });
          },
          children: categoryEntries
              .map(
                (entry) => Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                  ),
                  child: buildHelpEntryCard(entry),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildFaqTab() {
    return FutureBuilder<List<Faq>>(
      future: _faqFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        final faqs = snapshot.data!;
        if (faqs.isEmpty) {
          return const Center(child: Text('Keine FAQs vorhanden.'));
        }

        return ListView(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: faqs.asMap().entries.map((entry) {
                  int index = entry.key;
                  Faq faq = entry.value;
                  bool isLast = index == faqs.length - 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExpansionTile(
                        key: ValueKey<int>(index),
                        controller: _faqExpansionControllers.isNotEmpty
                            ? _faqExpansionControllers[index]
                            : null,
                        onExpansionChanged: (expanded) {
                          if (expanded) {
                            for (int i = 0;
                                i < _faqExpansionControllers.length;
                                i++) {
                              if (i != index &&
                                  _faqExpansionControllers[i].isExpanded) {
                                _faqExpansionControllers[i].collapse();
                              }
                            }
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        title: BodyLarge(text: faq.question),
                        children: [
                          BodyMedium(text: faq.answer).withPaddingX(16),
                        ],
                      ),
                      if (!isLast) Divider(height: 1).withPaddingY(8),
                    ],
                  );
                }).toList(),
              ).withPaddingX(16),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final helpEntriesAsync = ref.watch(helpEntriesProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Angebote'),
            Tab(text: 'FAQs'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
              children: [
                // Tab 0: Angebote
                helpEntriesAsync.when(
                  data: (entries) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(helpEntriesProvider);
                        await ref.read(helpEntriesProvider.future);
                      },
                      child: buildEntriesList(entries, 'Hilfen', _scrollController),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: ConnectionErrorWidget(
                      errorMessage: error.toString(),
                      onRetry: () => ref.invalidate(helpEntriesProvider),
                    ),
                  ),
                ),
              // Tab 1: FAQs
              _buildFaqTab(),
            ],
          ),
        ),
      ],
    );
  }
}
