// Sample Strapi API response fixtures for testing.
//
// All responses follow the Strapi v4 format: {"data": [...]} for lists
// and {"data": {...}} for single items.

const String newsListResponse = '''
{
  "data": [
    {
      "id": 1,
      "documentId": "abc123",
      "title": "Test News",
      "description": "Test description",
      "content": "Test content body",
      "category": "news",
      "createdAt": "2026-01-15T10:00:00.000Z",
      "updatedAt": "2026-01-15T10:00:00.000Z",
      "publishedAt": "2026-01-15T10:00:00.000Z",
      "publishAt": null,
      "image": null
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pageSize": 25,
      "pageCount": 1,
      "total": 1
    }
  }
}
''';

const String eventsListResponse = '''
{
  "data": [
    {
      "id": 1,
      "documentId": "evt123",
      "title": "Test Event",
      "description": "A test event",
      "startTime": "2026-03-01T14:00:00.000Z",
      "endTime": "2026-03-01T16:00:00.000Z",
      "location": "Testort",
      "category": "workshop",
      "createdAt": "2026-01-15T10:00:00.000Z",
      "updatedAt": "2026-01-15T10:00:00.000Z",
      "publishedAt": "2026-01-15T10:00:00.000Z",
      "publishAt": null,
      "expiresAt": null,
      "image": null,
      "participants": [],
      "templateEvent": null
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pageSize": 10,
      "pageCount": 1,
      "total": 1
    }
  }
}
''';

const String emptyListResponse = '''
{
  "data": [],
  "meta": {
    "pagination": {
      "page": 1,
      "pageSize": 25,
      "pageCount": 0,
      "total": 0
    }
  }
}
''';
