import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/models/pending_content_block.dart';

// Backward-compat-Aliase für den bestehenden News-Code. Neue Features sollen
// PendingContentBlock direkt verwenden.
typedef PendingNewsBlock = PendingContentBlock;
typedef PendingTextBlock = PendingContentTextBlock;
typedef PendingMediaBlock = PendingContentMediaBlock;

class NewsCreateFormState {
  final NewsCategory? category;
  final File? heroImage;
  final String title;
  final String introText;
  final String leadText;
  final List<PendingContentBlock> additionalBlocks;
  final bool publishLater;
  final DateTime? publishAt;

  const NewsCreateFormState({
    this.category,
    this.heroImage,
    this.title = '',
    this.introText = '',
    this.leadText = '',
    this.additionalBlocks = const [],
    this.publishLater = false,
    this.publishAt,
  });

  bool get isStep1Valid => category != null;
  bool get isStep2Valid =>
      title.trim().isNotEmpty && introText.trim().isNotEmpty;
  bool get isStep3Valid => leadText.trim().isNotEmpty;
  bool get isStep4Valid => !publishLater || publishAt != null;

  NewsCreateFormState copyWith({
    NewsCategory? category,
    Object? heroImage = _unset,
    String? title,
    String? introText,
    String? leadText,
    List<PendingContentBlock>? additionalBlocks,
    bool? publishLater,
    Object? publishAt = _unset,
  }) {
    return NewsCreateFormState(
      category: category ?? this.category,
      heroImage: identical(heroImage, _unset)
          ? this.heroImage
          : heroImage as File?,
      title: title ?? this.title,
      introText: introText ?? this.introText,
      leadText: leadText ?? this.leadText,
      additionalBlocks: additionalBlocks ?? this.additionalBlocks,
      publishLater: publishLater ?? this.publishLater,
      publishAt: identical(publishAt, _unset)
          ? this.publishAt
          : publishAt as DateTime?,
    );
  }
}

const Object _unset = Object();

class NewsCreateFormController extends StateNotifier<NewsCreateFormState> {
  NewsCreateFormController() : super(const NewsCreateFormState());

  void setCategory(NewsCategory category) =>
      state = state.copyWith(category: category);

  void setHeroImage(File? file) => state = state.copyWith(heroImage: file);

  void setTitle(String value) => state = state.copyWith(title: value);

  void setIntroText(String value) => state = state.copyWith(introText: value);

  void setLeadText(String value) => state = state.copyWith(leadText: value);

  void addTextBlock() {
    state = state.copyWith(
      additionalBlocks: [
        ...state.additionalBlocks,
        const PendingContentTextBlock(body: ''),
      ],
    );
  }

  void updateTextBlock(int index, String body) {
    final blocks = [...state.additionalBlocks];
    final current = blocks[index];
    if (current is! PendingContentTextBlock) return;
    blocks[index] = current.copyWith(body: body);
    state = state.copyWith(additionalBlocks: blocks);
  }

  void addMediaBlock({required File file, required bool isVideo}) {
    state = state.copyWith(
      additionalBlocks: [
        ...state.additionalBlocks,
        PendingContentMediaBlock(file: file, isVideo: isVideo),
      ],
    );
  }

  void removeBlock(int index) {
    final blocks = [...state.additionalBlocks]..removeAt(index);
    state = state.copyWith(additionalBlocks: blocks);
  }

  void setPublishLater(bool value) {
    state = state.copyWith(
      publishLater: value,
      publishAt: value ? state.publishAt : null,
    );
  }

  void setPublishAt(DateTime? value) =>
      state = state.copyWith(publishAt: value);

  void setPublishDate(DateTime date) {
    final base = state.publishAt ?? DateTime.now();
    state = state.copyWith(
      publishAt: DateTime(
        date.year,
        date.month,
        date.day,
        base.hour,
        base.minute,
      ),
    );
  }

  void setPublishHour(int hour) {
    final base = state.publishAt ?? DateTime.now();
    state = state.copyWith(
      publishAt: DateTime(base.year, base.month, base.day, hour, base.minute),
    );
  }

  void setPublishMinute(int minute) {
    final base = state.publishAt ?? DateTime.now();
    state = state.copyWith(
      publishAt: DateTime(base.year, base.month, base.day, base.hour, minute),
    );
  }

  void reset() => state = const NewsCreateFormState();
}

final newsCreateFormProvider =
    StateNotifierProvider.autoDispose<
      NewsCreateFormController,
      NewsCreateFormState
    >((ref) {
      return NewsCreateFormController();
    });
