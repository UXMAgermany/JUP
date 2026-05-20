class Markdown {
  final String text;

  Markdown({required this.text});

  factory Markdown.fromJson(Map<String, dynamic> data) {
    return Markdown(text: data['text']);
  }
}
