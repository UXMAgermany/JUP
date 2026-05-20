class Faq {
  final String documentId;
  final String question;
  final String answer;

  Faq({required this.documentId, required this.question, required this.answer});

  factory Faq.fromJson(Map<String, dynamic> data) {
    return Faq(
      documentId: data['documentId'],
      question: data['question'],
      answer: data['answer'],
    );
  }
}
