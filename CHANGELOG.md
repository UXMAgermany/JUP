# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.0] - 2026-04-23

### Added

- Umfragen: Freitext-Optionen — User können eigene Antwortoptionen für Multiple-Choice-Umfragen einreichen, Status wird im Bottom Sheet angezeigt (In Prüfung / Abgelehnt)
- Umfragen: Voting auf freigegebene Freitext-Optionen direkt in der Umfrage
- Umfragen: Push-Notification bei Annahme oder Ablehnung einer eingereichten Option
- User: FCM-Token wird beim App-Start an das Backend gesendet für gezielte Push-Notifications

### Changed

- Android compileSdk auf 36 aktualisiert — aktiviert Predictive Back Gesture (Android 16)
- Bottom Sheets: Hintergrundfarbe einheitlich auf surfaceContainerLow gesetzt
- Profilbearbeitung: Avatar wird größer angezeigt
- WLAN Password wird nicht mehr Uppercase angezeigt, sondern in "original"
- Errortexte unter Input werden nicht mehr ellipsed(...) sonder brechen auf max 3 Zeilen um
- Kategorie-Filter: Pfeil dreht sich beim Öffnen/Schließen, Farben für ausgewählte Optionen korrigiert, Position des Check-Icon korrigiert (rechts nach links).

## [2.2.1] - 2026-04-21

### Changed

- Zentraler `StrapiClient` für alle API-Aufrufe — ersetzt duplizierte HTTP-Logik in 10 Controllern
- `PaginatedListNotifier<T>` Basis-Klasse für Events und Surveys extrahiert
- `SurveyCard` (810 → ~270 Zeilen) in fokussierte Widgets aufgeteilt
- `CommentItem` als eigenständiges Widget aus `CommentSection` extrahiert
- `AuthNotifier` auf `StrapiClient` migriert
- 4 Markdown-Screens (`Impressum`, `Datenschutz`, `Verhaltenskodex`, `Nutzungsbedingungen`) von `FutureBuilder` auf Riverpod-Provider umgestellt
- Neue Riverpod-Provider für FAQ, Markdown-Texte und Dateien
- Ungenutztes `provider`-Package entfernt

## [2.2.0] - 2026-04-13

### Added

- Neue Kategorie "Sonstiges" für News und Events
- Kategorie-Feld im CMS ist jetzt optional (Default: Sonstiges)
- Unbekannte Kategorien vom Backend werden als "Sonstiges" angezeigt
- Neuer Umfragetyp "Wahl" mit Mehrfachstimmen-Unterstützung (maxVotes) und eigenem Kartendesign
- "Vorbei!"-Badge bei Umfragen entfernt — wird nur noch bei Events angezeigt
- "schedule"-Icon statt "flag"-Icon bei abgelaufenen Umfragen
- Admins können bei Wahlen nicht abstimmen
- Anonymisierung von Wahlen

### Removed

- Eventkategorie "Event" entfernt — war redundant, bestehende Events werden als "Sonstiges" angezeigt

## [2.1.0] - 2026-04-08

### Added

- "Vorbei!"-Badge für vergangene Events: blauer Badge (secondaryContainer-Farben) ersetzt den "Neu!"-Badge, wenn ein Event in der Vergangenheit liegt

- publishAt-Sicherheitscheck: Einträge mit einem `publishAt`-Datum in der Zukunft werden in der App nicht mehr angezeigt, auch wenn sie versehentlich im CMS published wurden (betrifft News, Events, Umfragen und Shorts)

### Changed

- Vergangene Events erzeugen keinen roten Notification-Dot mehr im Events-Tab
- Opacity vergangener Event-Karten von 70% auf 60% angepasst (Figma-Design)
- "Neu!" Badge Verhalten verbessert: Notification-Dots verschwinden sofort beim Scrollen

## [2.0.0] - 2026-04-01

### Fixed

- iOS Swipe-Back-Geste und Android-Back-Gesture funktionierten nicht auf Detail-Seiten (CustomRoute durch CupertinoPageRoute ersetzt)
- Leere-Zustand-Texte in Events und Umfragen waren generisch/nichtssagend — durch hilfreiche Beschreibungen ersetzt
- Tippfehler im Zugesagt-Tab: "keinem Events" → "keinem Event", Button-Label korrigiert ("Bin dabei" → "Jup, bin dabei")
- Kommentar-Button sprang beim Auf-/Zuklappen der Kommentar-Sektion nach unten (top-Padding im expanded State korrigiert)

### Added

- "Neu!"-Badge auf News-, Event- und Umfrage-Karten: ungesehene Beiträge werden visuell hervorgehoben, neue Beiträge werden oben sortiert
- Rote Notification-Dots an den Tab-Icons (News, Events, Umfragen) zeigen an, ob es ungesehene Beiträge gibt — verschwinden sofort, wenn alle neuen Beiträge gesehen wurden
- Gesehene Beiträge werden lokal gespeichert (SharedPreferences), sodass der Status über App-Neustarts erhalten bleibt
- News-Feed lädt progressiv: zunächst 5 Einträge, dann 15 per "Mehr laden", dann alle per "Alle laden" — Limit wird bei Filterwechsel und Pull-to-Refresh zurückgesetzt
- Hilfen-Tab zeigt jetzt zwei Tabs: "Angebote" (bisherige Hilfsangebote) und "FAQs" (häufig gestellte Fragen mit Akkordeon-Ansicht) — FAQs sind nicht mehr über Profil-Einstellungen erreichbar

### Changed

- Event-Teilnahme-Button zeigt jetzt immer "Jup, bin dabei" (vorher "Bin dabei")
- Schrittweises Laden des Newsfeed (mehr laden -> Alle laden)
- Hilfen-Tab-Icon von Fragezeichen zu Handshake geändert
- FAQs vom Profil in Hilfen-Tab verschoben
- FAQ-Controller und -Model von `features/profile` nach `features/content` verschoben
- Profil-Einstellungen "Hilfe und Support": FAQ us Untertitel entfernt

## [1.2.4] - 2026-03-25

- App Sprache auf Deutsch gestellt

### Fixed

- Event-Startzeiten wurden 1 Stunde verschoben angezeigt (UTC statt lokale Zeitzone)
- Shorts- und Umfrage-Notifications leiten jetzt korrekt zum Shorts-Feed bzw. zur Umfragen-Übersicht weiter
- Nicht eingeloggte User werden beim Notification-Tap zur Login-Seite weitergeleitet statt "Fehlerscreen" zu sehen

## [1.2.3] - 2026-02-26

### Fixed

- Android Zurück-Geste schloss die App statt zur vorherigen Seite zu navigieren (Deep Links nutzten System-Navigator statt AutoRouter)
- Zurück-Button auf Event-Detailseiten war gegen dunkle Hintergrundbilder kaum sichtbar (halbtransparenter Hintergrund hinzugefügt)

## [1.2.1] - 2026-02-13

### Fixed

- iOS Shorts-Videos: Ton verschwand nach ~20-60 Sekunden und Videos pausierten sich selbst
- Video-Player-Backend von AVPlayer auf media_kit (libmpv) umgestellt für stabilere Wiedergabe auf iOS

### Changed

- Neue Dependency: `video_player_media_kit` als Drop-in-Replacement für bessere iOS-Performance
- VideoPlayerPool optimiert: Reduzierte Pool-Größe (2 statt 3), synchrones Dispose

## [1.2.0] - 2026-02-11

### Added

- Vergangene Events werden nun in der Event-Übersicht angezeigt (unter den aktuellen Events)
- Vergangene Events sind visuell abgedimmt und zeigen "X waren dabei" statt "X sind dabei"
- Teilnahme-Button ("Jup, bin dabei") bei vergangenen Events ausgeblendet

### Changed

- iOS StatusBar wird nun versteckt für immersives Fullscreen-Design (`UIStatusBarHidden: true`, `UIViewControllerBasedStatusBarAppearance: false`)

### Fixed

- Shorts-Videos laufen nicht mehr im Hintergrund weiter wenn der Tab gewechselt wird

## [1.1.1] - 2026-02-04

### Fixed

- Markdown-Styling plattformübergreifend vereinheitlicht (Listen hatten auf iOS zu kleine Schrift)

## [1.1.0] - 2026-01-22

### Fixed

- iOS Shorts Video-Wiedergabe verbessert: Controller-Lifecycle-Bug behoben ("VideoPlayerController was used after being disposed")
- VideoPlayerPool mit sicherem Disposal-Mechanismus überarbeitet (verhindert Race Conditions)
- Verpixelte Bilder in News, Events und Survey Cards behoben (Cache-Größen für Retina-Displays erhöht)
- Verpixelte Bilder auf News- und Event-Detailseiten behoben
- iOS StatusBar war versteckt - nun sichtbar
- Passwort-Änderung: Englische Fehlermeldung bei gleichem Passwort wird nun auf Deutsch angezeigt

### Added

- E-Mail-Feld für Hilfe-Einträge mit mailto-Funktionalität
- Hilfe-Einträge werden jetzt auch innerhalb der Kategorien nach `order` sortiert

### Changed

- AVAudioSession-Konfiguration für optimale Video-Wiedergabe auf iOS
- Performance-Optimierungen für Shorts: RepaintBoundary, AnimationController für Volume-Icon, extrahierte const Widgets

## [1.0.7] - 2026-01-16

### Fixed

- Rate Limit Fehler (429) werden jetzt benutzerfreundlich angezeigt
- API-Fehlerbehandlung verbessert: verschiedene Backend-Fehlerformate werden korrekt geparst

## [1.0.6] - 2026-01-09

### Added

- iOS Fastlane setup for automated TestFlight deployment
- iOS CI/CD documentation (`IOS_CICD_MANUAL.md`)

### Changed

- App display name changed to "JUP!" (iOS and Android)
- Improved error handling for network image loading (using CachedNetworkImage)
- More robust API response parsing in auth controller

### Fixed

- iOS app icon alpha channel issue (removed transparency)
- Missing images no longer cause errors (silently ignored)
- Placeholder image scaling now consistent between error states and entries without images
- Shorts with unavailable videos are now automatically hidden instead of showing infinite loader
- Events filter now fetches from server instead of filtering client-side (fixes empty list when filtering by category not in initial results)

## [1.0.5] - 2026-01-07

### Added

- `order` field on HelpEntry for custom sorting
- Help categories now sorted by order number (smallest first)
- Centralized `EnvConfig` class for environment configuration

### Changed

- Environment configuration now uses hybrid approach: `--dart-define` for CI/production, `.env` file fallback for local development
- Simplified `ApiConfig` to use `EnvConfig`

## [1.0.4] - 2025-12-19

### Added

- In-app content reporting with ReportBottomSheet
- Report button on comments and Shorts
- Dedicated child safety section on "Problem melden" page
- Draft status for Fastlane deployments

### Changed

- Improved video player pool management for Shorts
- UI improvements for event cards and survey cards

## [1.0.3] - 2025-12-18

### Added

- Tablet compatibility: Content is centered on wide screens (max 700dp)
- `ResponsiveContentWrapper` widget for consistent tablet display
- `toWhatsApp` field on PhoneEntry for per-number WhatsApp linking

### Changed

- Help page: Removed WhatsApp/All tabs, all entries now in single list
- Dialogs now have a maximum width (400dp) for better tablet display
- More consistent error handling throughout the app

### Removed

- `goToWhatsApp` field from HelpEntry (replaced by `toWhatsApp` on PhoneEntry)

## [1.0.2] - 2025-12-10

### Added

- Matomo Analytics integration for anonymous usage statistics

### Fixed

- Improved error handling
- Various bugfixes

## [1.0.1] - 2025-12-04

### Added

- Volume control for Shorts
- Push notifications
- Splash screen
- Offline detection (No Internet screen)
- Fastlane setup for automated deployments

### Fixed

- STRAPI_BASE_URL in production corrected
- Improved error messages
- Android signing corrected
- Recurring events are now marked correctly
- Help section redesigned

### Changed

- Splash screen implementation corrected
- UI fixes (round 2)

## [1.0.0] - 2025-11-28

### Added

- Initial release
- News feed with categories and filters
- Events with booking functionality
- Surveys (Yes/No and Multiple Choice)
- Shorts (video content)
- Help section with contact information
- User profile with avatar selection
- Authentication (login/registration)
- WiFi password banner
- Comment functionality for news and surveys
