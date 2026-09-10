import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/achievements/models/leaderboard.dart';

void main() {
  const baseUrl = 'https://cms.example';

  test('Leaderboard.fromJson sorts entries by position and maps user', () {
    final lb = Leaderboard.fromJson({
      'documentId': 'lb1',
      'name': 'Mario Kart',
      'date': '2026-08-20',
      'order': 0,
      'entries': [
        {
          'position': 2,
          'user': {'documentId': 'u2', 'firstname': 'Ben', 'avatarPath': null},
        },
        {
          'position': 1,
          'user': {
            'documentId': 'u1',
            'firstname': 'Ada',
            'avatarPath': '/uploads/a.png',
          },
        },
      ],
    }, baseUrl);

    expect(lb.name, 'Mario Kart');
    expect(lb.entries.map((e) => e.position), [1, 2]);
    expect(lb.entries.first.firstname, 'Ada');
    expect(lb.entries.first.avatarPath, 'https://cms.example/uploads/a.png');
    expect(lb.entries.first.userDocumentId, 'u1');
  });

  test('handles empty entries', () {
    final lb = Leaderboard.fromJson({
      'documentId': 'lb2',
      'name': 'Leer',
      'date': '2026-08-20',
    }, baseUrl);
    expect(lb.entries, isEmpty);
  });
}
