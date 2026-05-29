import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/surveys/controllers/survey_create_form_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_controller.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/services/api_client.dart';

/// Submit-State-Notifier für den Survey-Create-Wizard. Lädt optional ein
/// Hero-Bild hoch, mappt den FormState auf [SurveyCreateInput] und ruft
/// den CMS-Controller. Nach Erfolg wird die Surveys-Liste invalidiert,
/// damit der neue Eintrag sofort sichtbar ist.
class SurveyCreateNotifier extends StateNotifier<AsyncValue<SurveyEntry?>> {
  SurveyCreateNotifier(this._controller, this._client, this._ref)
    : super(const AsyncValue.data(null));

  final SurveysController _controller;
  final StrapiClient _client;
  final Ref _ref;

  Future<SurveyEntry?> submit(SurveyCreateFormState form) async {
    assert(form.type != null, 'submit called before type was selected');
    assert(form.expiresAt != null, 'submit called before expiresAt was set');
    state = const AsyncValue.loading();
    try {
      int? heroMediaId;
      if (form.heroImage != null) {
        heroMediaId = await _client.uploadFile(form.heroImage!.path);
      }

      final input = SurveyCreateInput(
        title: form.title.trim(),
        subTitle: form.subTitle.trim().isEmpty ? null : form.subTitle.trim(),
        imageMediaId: heroMediaId,
        type: form.type!,
        expiresAt: form.expiresAt!,
        publishAt: form.publishLater ? form.publishAt : null,
        maxVotes: form.type == SurveyType.yesNo ? 1 : form.maxVotes,
        allowCustomOptions: form.allowCustomOptions ?? false,
        optionTexts: form.options,
      );

      final entry = await _controller.createSurvey(input);
      state = AsyncValue.data(entry);
      await _ref.read(surveysListProvider.notifier).refresh();
      return entry;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final surveyCreateProvider =
    StateNotifierProvider<SurveyCreateNotifier, AsyncValue<SurveyEntry?>>((
      ref,
    ) {
      return SurveyCreateNotifier(
        ref.watch(surveysControllerProvider),
        ref.watch(strapiClientProvider),
        ref,
      );
    });
