import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/content/controllers/faq_controller.dart';
import 'package:jup/features/content/controllers/help_controller.dart';
import 'package:jup/features/content/controllers/markdown_texts_controller.dart';
import 'package:jup/features/content/models/faq_model.dart';
import 'package:jup/features/content/models/help_model.dart';
import 'package:jup/features/content/models/markdown_model.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the HelpController
final helpControllerProvider = Provider<HelpController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return HelpController(client);
});

/// Provider for fetching all help entries
final helpEntriesProvider = FutureProvider<List<HelpEntry>>((ref) async {
  final controller = ref.watch(helpControllerProvider);
  return await controller.fetchHelpEntries();
});

/// Provider for the FaqController
final faqControllerProvider = Provider<FaqController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return FaqController(client);
});

/// Provider for fetching all FAQ entries
final faqEntriesProvider = FutureProvider<List<Faq>>((ref) async {
  final controller = ref.watch(faqControllerProvider);
  return await controller.fetchFaq();
});

/// Provider for the MarkdownTextsController
final markdownTextsControllerProvider =
    Provider<MarkdownTextsController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return MarkdownTextsController(client);
});

/// Provider for fetching the codex
final codexProvider = FutureProvider<Markdown>((ref) async {
  final controller = ref.watch(markdownTextsControllerProvider);
  return await controller.fetchCodex();
});

/// Provider for fetching the privacy policy
final privacyPolicyProvider = FutureProvider<Markdown>((ref) async {
  final controller = ref.watch(markdownTextsControllerProvider);
  return await controller.fetchPrivacyPolicy();
});

/// Provider for fetching the imprint
final imprintProvider = FutureProvider<Markdown>((ref) async {
  final controller = ref.watch(markdownTextsControllerProvider);
  return await controller.fetchImprint();
});

/// Provider for fetching the terms and conditions
final termsProvider = FutureProvider<Markdown>((ref) async {
  final controller = ref.watch(markdownTextsControllerProvider);
  return await controller.fetchTermsAndConditions();
});
