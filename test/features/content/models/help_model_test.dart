import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/content/models/help_model.dart';

void main() {
  group('PhoneEntry', () {
    group('fromJson', () {
      test('should parse phone entry with label', () {
        final json = {'number': '0461 90930', 'label': 'Hotline'};

        final phoneEntry = PhoneEntry.fromJson(json);

        expect(phoneEntry.number, '0461 90930');
        expect(phoneEntry.label, 'Hotline');
        expect(phoneEntry.toWhatsApp, false);
      });

      test('should parse phone entry without label', () {
        final json = {'number': '0151 12345678'};

        final phoneEntry = PhoneEntry.fromJson(json);

        expect(phoneEntry.number, '0151 12345678');
        expect(phoneEntry.label, null);
        expect(phoneEntry.toWhatsApp, false);
      });

      test('should parse phone entry with toWhatsApp true', () {
        final json = {
          'number': '0151 12345678',
          'label': 'WhatsApp',
          'toWhatsApp': true,
        };

        final phoneEntry = PhoneEntry.fromJson(json);

        expect(phoneEntry.number, '0151 12345678');
        expect(phoneEntry.label, 'WhatsApp');
        expect(phoneEntry.toWhatsApp, true);
      });

      test('should default toWhatsApp to false when missing', () {
        final json = {'number': '0461 90930', 'label': 'Hotline'};

        final phoneEntry = PhoneEntry.fromJson(json);

        expect(phoneEntry.toWhatsApp, false);
      });
    });

    group('toJson', () {
      test('should convert phone entry with label to JSON', () {
        final phoneEntry = PhoneEntry(number: '0461 90930', label: 'Hotline');

        final json = phoneEntry.toJson();

        expect(json['number'], '0461 90930');
        expect(json['label'], 'Hotline');
        expect(json['toWhatsApp'], false);
      });

      test('should convert phone entry without label to JSON', () {
        final phoneEntry = PhoneEntry(number: '0151 12345678');

        final json = phoneEntry.toJson();

        expect(json['number'], '0151 12345678');
        expect(json['label'], null);
        expect(json['toWhatsApp'], false);
      });

      test('should convert phone entry with toWhatsApp to JSON', () {
        final phoneEntry = PhoneEntry(
          number: '0151 12345678',
          label: 'WhatsApp',
          toWhatsApp: true,
        );

        final json = phoneEntry.toJson();

        expect(json['number'], '0151 12345678');
        expect(json['label'], 'WhatsApp');
        expect(json['toWhatsApp'], true);
      });
    });
  });

  group('HelpEntry', () {
    group('fromJson', () {
      test('should parse complete JSON with all fields', () {
        final json = {
          'title': 'Pro Familia Flensburg',
          'text': 'Beratung zu Sexualität',
          'phones': [
            {'number': '0461 90930', 'label': 'Hotline'},
            {'number': '0461 90931', 'label': 'Office'},
          ],
          'website': 'https://www.profamilia.de',
          'location': 'Rote Straße 22, 24937 Flensburg',
          'category': 'Psychosoziale und Familien-beratung',
        };

        final entry = HelpEntry.fromJson(json);

        expect(entry.title, 'Pro Familia Flensburg');
        expect(entry.text, 'Beratung zu Sexualität');
        expect(entry.phones.length, 2);
        expect(entry.phones[0].number, '0461 90930');
        expect(entry.phones[0].label, 'Hotline');
        expect(entry.phones[1].number, '0461 90931');
        expect(entry.phones[1].label, 'Office');
        expect(entry.website, 'https://www.profamilia.de');
        expect(entry.location, 'Rote Straße 22, 24937 Flensburg');
        expect(entry.category, 'Psychosoziale und Familien-beratung');
      });

      test('should parse JSON with null website', () {
        final json = {
          'title': 'Test Entry',
          'text': 'Test text',
          'phones': [
            {'number': '1234567890'},
          ],
          'website': null,
          'location': 'Test location',
          'category': 'Freizeit und Soziale Kontakte',
        };

        final entry = HelpEntry.fromJson(json);

        expect(entry.website, null);
        expect(entry.category, 'Freizeit und Soziale Kontakte');
      });

      test('should parse JSON with null category', () {
        final json = {
          'title': 'Test Entry',
          'text': 'Test text',
          'phones': [
            {'number': '1234567890'},
          ],
          'website': 'https://example.com',
          'location': 'Test location',
          'category': null,
        };

        final entry = HelpEntry.fromJson(json);

        expect(entry.category, null);
      });

      test('should parse JSON with empty phones array', () {
        final json = {
          'title': 'Test Entry',
          'text': 'Test text',
          'phones': [],
          'location': 'Test location',
          'category': 'Test Category',
        };

        final entry = HelpEntry.fromJson(json);

        expect(entry.phones, []);
      });

      test('should parse JSON with null phones', () {
        final json = {
          'title': 'Test Entry',
          'text': 'Test text',
          'phones': null,
          'location': 'Test location',
          'category': 'Test Category',
        };

        final entry = HelpEntry.fromJson(json);

        expect(entry.phones, []);
      });

      test('should parse JSON with null location', () {
        final json = {
          'title': 'Test Entry',
          'text': 'Test text',
          'phones': [
            {'number': '1234567890'},
          ],
          'location': null,
          'category': 'Test Category',
        };

        final entry = HelpEntry.fromJson(json);

        expect(entry.location, null);
      });
    });

    group('toJson', () {
      test('should convert entry to JSON with all fields', () {
        final entry = HelpEntry(
          title: 'Pro Familia Flensburg',
          text: 'Beratung zu Sexualität',
          phones: [
            PhoneEntry(number: '0461 90930', label: 'Hotline'),
            PhoneEntry(number: '0461 90931', label: 'Office'),
          ],
          website: 'https://www.profamilia.de',
          location: 'Rote Straße 22, 24937 Flensburg',
          category: 'Psychosoziale und Familien-beratung',
        );

        final json = entry.toJson();

        expect(json['title'], 'Pro Familia Flensburg');
        expect(json['text'], 'Beratung zu Sexualität');
        expect(json['phones'].length, 2);
        expect(json['phones'][0]['number'], '0461 90930');
        expect(json['phones'][0]['label'], 'Hotline');
        expect(json['phones'][1]['number'], '0461 90931');
        expect(json['phones'][1]['label'], 'Office');
        expect(json['website'], 'https://www.profamilia.de');
        expect(json['location'], 'Rote Straße 22, 24937 Flensburg');
        expect(json['category'], 'Psychosoziale und Familien-beratung');
      });

      test('should convert entry with null website to JSON', () {
        final entry = HelpEntry(
          title: 'Test Entry',
          text: 'Test text',
          phones: [PhoneEntry(number: '1234567890')],
          website: null,
          location: 'Test location',
          category: 'Freizeit und Soziale Kontakte',
        );

        final json = entry.toJson();

        expect(json['website'], null);
        expect(json['category'], 'Freizeit und Soziale Kontakte');
      });

      test('should convert entry with null category to JSON', () {
        final entry = HelpEntry(
          title: 'Test Entry',
          text: 'Test text',
          phones: [PhoneEntry(number: '1234567890')],
          website: 'https://example.com',
          location: 'Test location',
          category: null,
        );

        final json = entry.toJson();

        expect(json['category'], null);
      });

      test('should convert entry with empty phones to JSON', () {
        final entry = HelpEntry(
          title: 'Test Entry',
          text: 'Test text',
          phones: [],
          website: 'https://example.com',
          location: 'Test location',
          category: 'Test Category',
        );

        final json = entry.toJson();

        expect(json['phones'], []);
      });

      test('should convert entry with null location to JSON', () {
        final entry = HelpEntry(
          title: 'Test Entry',
          text: 'Test text',
          phones: [PhoneEntry(number: '1234567890')],
          website: 'https://example.com',
          location: null,
          category: 'Test Category',
        );

        final json = entry.toJson();

        expect(json['location'], null);
      });
    });

    group('round-trip serialization', () {
      test('should preserve data through fromJson and toJson', () {
        final originalJson = {
          'title': 'Pro Familia Flensburg',
          'text': 'Beratung zu Sexualität',
          'phones': [
            {'number': '0461 90930', 'label': 'Hotline'},
            {'number': '0461 90931', 'label': 'Office'},
          ],
          'website': 'https://www.profamilia.de',
          'location': 'Rote Straße 22, 24937 Flensburg',
          'category': 'Psychosoziale und Familien-beratung',
        };

        final entry = HelpEntry.fromJson(originalJson);
        final resultJson = entry.toJson();

        expect(resultJson['title'], originalJson['title']);
        expect(resultJson['text'], originalJson['text']);
        expect(resultJson['phones'].length, 2);
        final originalPhones = originalJson['phones'] as List;
        expect(resultJson['phones'][0]['number'], originalPhones[0]['number']);
        expect(resultJson['phones'][0]['label'], originalPhones[0]['label']);
        expect(resultJson['phones'][1]['number'], originalPhones[1]['number']);
        expect(resultJson['phones'][1]['label'], originalPhones[1]['label']);
        expect(resultJson['website'], originalJson['website']);
        expect(resultJson['location'], originalJson['location']);
        expect(resultJson['category'], originalJson['category']);
      });
    });
  });
}
