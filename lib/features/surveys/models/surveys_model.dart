import 'package:jup/features/auth/models/user_model.dart';

enum SurveyType { yesno, custom }

class SurveysEntry {
  final String documentId;
  final SurveyType type;
  final String title;
  final String text;
  final DateTime endDate;
  final String? imageUrl;
  final List<SurveyOption> options;

  SurveysEntry({
    required this.documentId,
    required this.type,
    required this.title,
    required this.text,
    required this.endDate,
    required this.options,
    this.imageUrl,
  });

  factory SurveysEntry.fromJson(Map<String, dynamic> json) {
    return SurveysEntry(
      documentId: json['documentId'] as String,
      type: json['type'] as SurveyType,
      title: json['title'] as String,
      text: json['text'] as String,
      endDate: DateTime.parse(json['createdAt']),
      imageUrl: json['image'] != null ? json['image']['url'] as String : null,
      options: json['options'] != null
          ? List<SurveyOption>.from(json['options'] as List)
          : [],
    );
  }
}

class SurveyOption {
  final String option;
  final List<User> votedBy; //  User who voted for this option

  SurveyOption({
    required this.option,
    required this.votedBy, //  User who voted for this option.user,
  });
}
