# Shorts Feature

Die Shorts-Funktionalität ermöglicht das Anzeigen und Abspielen von kurzen Videos aus dem CMS.

## Struktur

```
shorts/
├── models/
│   └── shorts_model.dart          # Datenmodell für Shorts
├── controllers/
│   ├── shorts_controller.dart     # API-Aufrufe zum CMS
│   └── shorts_provider.dart       # Riverpod Provider
└── widgets/
    └── shorts_card.dart           # Card-Widget für einzelne Shorts
```

## CMS-Integration

### Erwartete API-Struktur

Die Shorts werden vom CMS über die API geladen:

```
GET /api/shorts
```

**Erwartetes JSON-Format:**

```json
{
  "data": [
    {
      "documentId": "short123",
      "title": "Mein erstes Short",
      "video": {
        "url": "https://example.com/videos/short.mp4"
      },
      "thumbnail": {
        "url": "https://example.com/thumbnails/short.jpg"
      },
      "viewCount": 42,
      "author": "Max Mustermann",
      "createdAt": "2025-01-15T10:30:00.000Z",
      "publishedAt": "2025-01-15T12:00:00.000Z"
    }
  ]
}
```

### Felder

- `documentId`: Eindeutige ID des Shorts
- `title`: Titel/Beschreibung des Videos
- `video.url`: URL zum Video (mp4, webm, etc.)
- `thumbnail.url`: Optional - Thumbnail-Bild URL
- `viewCount`: Anzahl der Aufrufe
- `author`: Name des Autors
- `createdAt`: Erstellungsdatum
- `publishedAt`: Veröffentlichungsdatum

## Verwendung

### Shorts anzeigen

```dart
import 'package:jup/features/shorts/widgets/shorts_card.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';

// Mit ShortsEntry-Objekt
ShortsCard(
  shortsEntry: myShort,
  onTap: () {
    // Zum Video-Player navigieren
  },
  onShare: () {
    // Share-Funktion
  },
)

// Oder mit direkten Properties (für Platzhalter)
ShortsCard(
  title: "Beispiel-Titel",
  viewCount: "25 mal angesehen",
  thumbnailUrl: "https://example.com/thumb.jpg",
  onTap: () {}
)
```

### Provider verwenden

```dart
import 'package:jup/features/shorts/controllers/shorts_provider.dart';

// In einem ConsumerWidget
final shortsAsync = ref.watch(shortsListProvider);

shortsAsync.when(
  data: (shorts) {
    // Shorts anzeigen
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(),
);
```
