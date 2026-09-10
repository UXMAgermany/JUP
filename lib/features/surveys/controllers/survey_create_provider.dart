import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/surveys/controllers/survey_create_form_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/services/api_client.dart';

/// Submit-State-Notifier für den Survey-Create-Wizard.
///
/// Schickt einen einzigen Multipart-Request an `POST /api/surveys/atomic`:
/// das `data`-JSON enthält Titel, Typ, Optionen etc., das optionale Hero-Bild
/// hängt als `heroImage`-File. Das CMS lädt das Bild hoch und erstellt die
/// Umfrage in einer Aktion — schlägt der Create-Schritt fehl, wird das
/// hochgeladene Bild wieder entfernt, sodass keine Orphan-Files entstehen.
class SurveyCreateNotifier extends StateNotifier<AsyncValue<SurveyEntry?>> {
  SurveyCreateNotifier(this._client, this._ref)
    : super(const AsyncValue.data(null));

  final StrapiClient _client;
  final Ref _ref;

  Future<SurveyEntry?> submit(SurveyCreateFormState form) async {
    assert(form.type != null, 'submit called before type was selected');
    assert(form.expiresAt != null, 'submit called before expiresAt was set');
    state = const AsyncValue.loading();
    try {
      final type = form.type!;
      final expiresAt = form.expiresAt!;
      final data = <String, dynamic>{
        'title': form.title.trim(),
        'type': switch (type) {
          SurveyType.yesNo => 'yes-no',
          SurveyType.election => 'election',
          SurveyType.multiple => 'multiple',
        },
        'expiresAt':
            '${expiresAt.year.toString().padLeft(4, '0')}-'
            '${expiresAt.month.toString().padLeft(2, '0')}-'
            '${expiresAt.day.toString().padLeft(2, '0')}',
        'maxVotes': type == SurveyType.yesNo ? 1 : form.maxVotes,
        'allowCustomOptions':
            type == SurveyType.multiple && (form.allowCustomOptions ?? false),
      };

      final subTitle = form.subTitle.trim();
      if (subTitle.isNotEmpty) {
        data['subTitle'] = subTitle;
      }
      if (form.publishLater && form.publishAt != null) {
        data['publishAt'] = form.publishAt!.toUtc().toIso8601String();
      }
      if (form.scopeGroupDocumentId != null) {
        data['group'] = form.scopeGroupDocumentId;
      }
      if (type == SurveyType.multiple || type == SurveyType.election) {
        final nonEmpty = form.options
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .map((t) => {'text': t})
            .toList();
        if (nonEmpty.isNotEmpty) {
          data['options'] = nonEmpty;
        }
      }

      final responseData = await _client.postMultipartWithMedia(
        '/api/surveys/atomic',
        data: data,
        heroImage: form.heroImage,
      );
      final entry = SurveyEntry.fromJson(responseData, _client.baseUrl);
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
      return SurveyCreateNotifier(ref.watch(strapiClientProvider), ref);
    });
