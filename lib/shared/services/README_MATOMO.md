# Matomo Tracking Integration

Diese App verwendet Matomo für Analytics-Tracking mit vollständiger DSGVO-Konformität und Pseudonymisierung.

## 📊 Was wird getrackt?

### Aktuell implementiert ✅

**1. Screen-Views (Seitenaufrufe)**

- **Was**: Alle Navigationen zwischen Screens in der App
- **Implementierung**: Automatisch via `MatomoRouteObserver` (siehe `main.dart`)
- **Beispiele**: NewsOverviewRoute, EventsOverviewRoute, ProfileRoute, EventDetailRoute, etc.
- **Zweck**: Verstehen welche Bereiche der App genutzt werden

**2. User-Sessions**

- **Was**: Pseudonymisierte User-ID (SHA-256 Hash)
- **Wann**: Bei Login gesetzt, bei Logout gelöscht
- **Zweck**: User-Journey über mehrere Sessions nachvollziehen (ohne echte User-ID zu kennen)

### Nicht implementiert (Nur als Code-Beispiele vorhanden) ❌

Die folgenden Tracking-Möglichkeiten sind **vorbereitet aber nicht aktiv**:

- Login/Logout Events
- Event-Bookmarks
- Umfrage-Votes
- Kommentare
- Video-Views
- Sonstige User-Interaktionen

**Um diese zu aktivieren**, müssen die entsprechenden `trackEvent()` Calls in den jeweiligen Widgets/Controllers hinzugefügt werden (siehe Beispiele unten).

## Konfiguration

Die Matomo-Konfiguration erfolgt über die `.env` Datei:

```env
MATOMO_URL=https://analytics.amt-suederbrarup.de
MATOMO_SITE_ID=6
MATOMO_USER_SALT=jup-secure-salt-2024-prod-v1
```

### Pseudonymisierung

Statt der echten User-ID wird ein **SHA-256 Hash** an Matomo gesendet:

- `User ID 123` → `Hash: a3f8b9c2d4e5f6...` (64 Zeichen)
- Der Hash wird aus `userId:MATOMO_USER_SALT` berechnet
- Die User-ID kann aus dem Hash **nicht** zurückgerechnet werden
- Gleicher User = Gleicher Hash → User-Journey über Sessions trackbar
- **DSGVO-konform**: Pseudonymisierung gemäß Art. 4 Nr. 5 DSGVO

## Datenschutz & Consent (DSGVO Art. 8)

**Tracking ist nur aktiv wenn:**

1. ✅ User ist eingeloggt
2. ✅ User hat Tracking im CMS aktiviert (`trackingEnabled = true`)
3. ✅ User ist mindestens 16 Jahre alt (Geburtsdatum-Check)

**Kein Tracking erfolgt für:**

- ❌ Nicht eingeloggte User
- ❌ User unter 16 Jahren
- ❌ User die Tracking nicht aktiviert haben

Die Prüfung erfolgt automatisch durch die `User.isTrackingAllowed()` Methode.

## Automatisches Screen-Tracking ✅ AKTIV

Alle Screen-Navigationen werden **automatisch** über den `MatomoRouteObserver` getrackt, aber nur wenn die Consent-Bedingungen erfüllt sind.

**Implementierung**:

- `main.dart` Zeile 94: `navigatorObservers: () => [MatomoRouteObserver()]`
- Jede Navigation (push, pop, replace) wird automatisch erfasst

## Manuelles Event-Tracking ⚠️ NICHT IMPLEMENTIERT

Die folgenden Code-Beispiele zeigen, **wie** du custom Events tracken **könntest**. Sie sind aktuell **nicht im Code aktiv**:

```dart
import 'package:jup/shared/services/matomo_service.dart';

final matomoService = MatomoService();

// Track ein custom Event
matomoService.trackEvent(
  category: 'User',
  action: 'Login',
  name: 'LoginButton',
);

// Track eine Goal-Conversion
matomoService.trackGoal(1);

// Setze User-ID nach Login
matomoService.setUserId(user.id.toString());

// Lösche User-ID nach Logout
matomoService.clearUserId();
```

## Beispiele für Event-Tracking (Optional)

Diese Events sind **aktuell nicht implementiert**. Du kannst sie bei Bedarf hinzufügen:

### Login/Logout Tracking (Beispiel)

Falls gewünscht, könnte man in `lib/features/auth/controllers/auth_controller.dart` ergänzen:

```dart
// Nach erfolgreichem Login (optional)
MatomoService().trackEvent(
  category: 'Auth',
  action: 'Login',
  name: 'Success',
);

// Nach Logout (optional)
MatomoService().trackEvent(
  category: 'Auth',
  action: 'Logout',
);
```

> **Hinweis**: User-ID wird bereits automatisch via `updateTrackingConsent()` gesetzt/gelöscht. Event-Tracking ist optional.

### Event-Bookmark Tracking (Beispiel)

Falls gewünscht, könnte man in Event-Widgets ergänzen:

```dart
MatomoService().trackEvent(
  category: 'Events',
  action: 'Bookmark',
  name: event.title,
);
```

### Poll-Vote Tracking (Beispiel)

Falls gewünscht, könnte man in Survey-Widgets ergänzen:

```dart
MatomoService().trackEvent(
  category: 'Surveys',
  action: 'Vote',
  name: survey.title,
);
```

## Technische Implementation

### User-Model Erweiterung

Das `User`-Model enthält:

- `trackingEnabled` (bool): Consent-Status aus dem CMS
- `birthday` (DateTime?): Geburtsdatum für Altersverifizierung
- `isTrackingAllowed()`: Methode die beide Bedingungen prüft

### Auth-Flow Integration

Nach Login oder beim Session-Restore wird automatisch `MatomoService().updateTrackingConsent(user)` aufgerufen.
Bei Logout wird das Tracking deaktiviert und die User-ID gelöscht.

### Registrierungsprozess

Während der Registrierung wird der User gefragt, ob er/sie Tracking akzeptieren möchte:

- Die Tracking-Consent Checkbox erscheint **nur** wenn das gewählte Geburtsdatum indiziert, dass der User ≥16 Jahre alt ist
- Die Checkbox ist optional (kein Pflichtfeld)
- Wording: "**pseudonymisierte** Nutzungsdaten" (technisch korrekt)
- Der Consent-Status wird bei der Registrierung an das CMS gesendet (`trackingEnabled`)

### CMS-Requirements

Das Backend (Strapi) muss folgende Felder im User-Endpoint zurückgeben:

- `trackingEnabled` (boolean) - User's Tracking-Consent
- `birthday` (date) - Für Altersverifizierung (bereits vorhanden)

**Strapi Config:** In `config/plugins.ts` muss `trackingEnabled` zu den `allowedFields` der Registrierung hinzugefügt werden.

## Datenschutz-Maßnahmen

### Client-seitig (App):

1. ✅ **Pseudonymisierung**: User-ID wird gehasht (SHA-256 + Salt)
2. ✅ **Altersverifizierung**: Kein Tracking für User < 16 Jahre
3. ✅ **Opt-in**: User muss explizit zustimmen
4. ✅ **Conditional Display**: Checkbox nur bei Alter ≥16

### Server-seitig (Matomo):

- ⚠️ **IP-Anonymisierung**: Sollte in Matomo aktiviert werden
- ⚠️ **Datenaufbewahrung**: Retention-Policy konfigurieren (z.B. 6-12 Monate)
- ⚠️ **Cookie-Lifetime**: Kurze Session-Cookies bevorzugen

## Wichtige Hinweise

- Der Service wird automatisch beim App-Start in `main.dart` initialisiert
- Tracking-Status wird bei jedem Login/Logout automatisch aktualisiert
- Events werden automatisch im Hintergrund an den Matomo-Server gesendet
- Bei Netzwerkproblemen werden Events lokal zwischengespeichert und später versendet
- **Salt ändern**: Für Produktion unbedingt `MATOMO_USER_SALT` in `.env` auf einen sicheren, zufälligen Wert setzen!
