class PhoneEntry {
  final String number;
  final String? label;
  final bool toWhatsApp;

  PhoneEntry({required this.number, this.label, this.toWhatsApp = false});

  factory PhoneEntry.fromJson(Map<String, dynamic> json) {
    return PhoneEntry(
      number: json['number'] as String,
      label: json['label'] as String?,
      toWhatsApp: json['toWhatsApp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'number': number, 'label': label, 'toWhatsApp': toWhatsApp};
  }
}

class HelpEntry {
  final String title;
  final String text;
  final List<PhoneEntry> phones;
  final String? website;
  final String? location;
  final String? category;
  final int? order;
  final String? email;

  HelpEntry({
    required this.title,
    required this.text,
    this.phones = const [],
    this.website,
    this.location,
    this.category,
    this.order,
    this.email,
  });

  factory HelpEntry.fromJson(Map<String, dynamic> json) {
    List<PhoneEntry> phonesList = [];
    if (json['phones'] != null) {
      phonesList = (json['phones'] as List)
          .map((phone) => PhoneEntry.fromJson(phone as Map<String, dynamic>))
          .toList();
    }

    return HelpEntry(
      title: json['title'] as String,
      text: json['text'] as String,
      phones: phonesList,
      website: json['website'] as String?,
      location: json['location'] as String?,
      category: json['category'] as String?,
      order: json['order'] as int?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'text': text,
      'phones': phones.map((phone) => phone.toJson()).toList(),
      'website': website,
      'location': location,
      'category': category,
      'order': order,
      'email': email,
    };
  }
}
