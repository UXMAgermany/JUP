# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.7.1]

### Fixed

- Das Abzeichen „Ideenreich" wurde beim Einreichen einer Antwort auf eine Umfrage nicht freigeschaltet.

## [2.7.0]

### Added

- Achievements: neuer Menüpunkt mit Abzeichen in 7 Stufen (verdient durch App-Aktivität und QR-Code-Scans auf dem Jugendplatz), versteckten Spezial-Abzeichen und kuratierten Bestenlisten; der QR-Scanner ist über den Header und das Menü erreichbar.
- News-Beiträge lassen sich jetzt mit Daumen hoch/runter bewerten.

## [2.6.0]

### Changed

- Flutter auf 3.47.1 angehoben und Abhängigkeiten aktualisiert, u. a. Firebase, `video_player`, Riverpod und `flutter_local_notifications` auf 22.x
- CI installiert Abhängigkeiten jetzt mit `--enforce-lockfile`, damit Builds exakt die gelockten Paketversionen verwenden
- Geteilte Links zu News, Events und Shorts sind jetzt normale `https`-Links statt `jup://` — sie sind in Messengern klickbar, öffnen die App wenn sie installiert ist und führen sonst in den App-Store. Bereits geteilte `jup://`-Links funktionieren weiter

## [2.5.2]

### Changed

- Android-App zielt jetzt auf Android 16 (API 36), um die Google-Play-Zielversion-Anforderung zu erfüllen
- iOS-App nutzt jetzt den UIScene-Lifecycle, den kommende iOS-Versionen voraussetzen

### Fixed

- Das Einstellungs-Icon in der Gruppen-Detail-AppBar war im Dark Mode hart weiß auf hellem Lila, ist jetzt korrekt nach Farbschema `onPrimary`.
- Gleiches Problem beim Nein-Icon einer beantworteten Ja/Nein-Umfrage: hart weiß auf hellem Lila, jetzt `onPrimary` wie das Ja-Icon.
- „Einloggen" auf dem Willkommens-Screen lag als 14px-Weiß auf Lila unter der WCAG-Kontrastschwelle; die Beschriftung ist jetzt größer und fett.
- Push oder Deep Link auf News/Events landete auf einer leeren Seite statt auf der Detailseite; ebenso führte „Irgendwie konnten wir den Eintrag nicht finden…" ins Leere statt zur Übersicht
- Lade- und Fehlerseiten beim Öffnen eines Beitrags aus einer Benachrichtigung hatten keinen Hintergrund und waren im hellen Farbschema unlesbar (dunkle Schrift auf Schwarz); sie nutzen jetzt denselben Hintergrund wie die übrigen Unterseiten
- Ein geteilter `jup://`-Link startete die App auf einem schwarzen Bildschirm, wenn sie vorher geschlossen war; Android reicht solche Links jetzt wie iOS an die App-eigene Deep-Link-Behandlung weiter statt an den Router
- News-Titel auf den Beitragskarten wurden nach einer Zeile abgeschnitten; sie dürfen jetzt zwei Zeilen nutzen

## [2.5.1]

### Fixed

- Umfragen-Card zeigte die Gruppen-Zugehörigkeit doppelt an (unterhalb der Antwortoptionen erneut); die zweite Anzeige wurde entfernt
- In versteckten Gruppen fehlte Gruppen-Admins das Options-Menü zur Mitgliederverwaltung (Admin ernennen/entziehen, Mitglied entfernen); die Verwaltung funktioniert jetzt wie in normalen Gruppen — das CMS erlaubte sie bereits
- Versteckte Gruppen erscheinen jetzt im „Gruppe"-Filter (News/Events/Umfragen) für ihre Mitglieder — auch für JUZ-Admins, deren Filterliste bisher nur öffentliche Gruppen enthielt

## [2.5.0]

### Added

- **Gruppen-Scope für News, Events und Umfragen**: Beiträge können beim Erstellen optional an eine Gruppe gebunden werden. Neuer Stepper-Schritt 1 „Für wen erstellst du …?" mit „Alle" (nur JUZ-Admin) + den Gruppen, in denen man Admin ist. Für JUZ-Admins ohne eigene Admin-Gruppen wird der Schritt automatisch übersprungen; Group-Admins durchlaufen ihn immer (auch bei einer einzigen Gruppe — Transparenz beim neuen Rollenkonzept). Group-Admins dürfen jetzt News/Events/Umfragen erstellen — der Create-FAB im Drawer respektiert das neue Recht; Backend (`/atomic`-Endpoints) lehnt unautorisierte Scopes mit 403 ab. Im normalen Feed erscheinen gruppen-gescopte Beiträge zusätzlich zu globalen, aber strikt nur für Mitglieder der jeweiligen Gruppe (JUZ-Admins sehen alles als Moderations-Override). Neuer „Gruppe ▾"-Dropdown-Filter neben dem Thema-Filter (News-, Events-„Alle"-Tab) mit Optionen „Alle" (Default) und den eigenen Gruppen. Beitragskarten zeigen den Gruppennamen als zweite Meta-Zeile (Icon + Name) — VoiceOver kündigt „Aus der Gruppe X" an. Beim Löschen einer Gruppe werden alle gruppen-gescopten News/Events/Umfragen serverseitig kaskadiert mitgelöscht, damit kein Privacy-Leak durch ehemals scoped, plötzlich orphaned Beiträge entsteht. CMS-Schemas bekommen ein neues nullable `manyToOne`-Feld `group → api::group.group`; bestehende Datensätze bleiben global. Kein Edit-Flow für die drei Inhaltstypen, daher ist `group` faktisch write-once
- Neues Feature **Gruppen**: eigener Menüpunkt „Gruppen" im App-Drawer (zwischen Umfragen und Hilfen) mit Listen-Tab „Meine Gruppen" / „Alle Gruppen". Jede:r authentifizierte User:in darf eine eigene Gruppe gründen (Name, 16:9-Bild, Beschreibung) und wird damit automatisch Gruppen-Admin — max. eine selbst-gegründete Gruppe pro User, der „+ Gruppe"-FAB im Drawer versteckt sich entsprechend; per Promote kann ein User aber in mehreren Gruppen Admin werden. Neue Gruppen starten als `pending` und müssen von einem JUZ-Admin (`isJUPAdmin`) im Strapi-CMS freigegeben werden; Reject = Hard-Delete mit E-Mail an Ersteller:in. Beitritt erfolgt per Anfrage mit Admin-Approval, im Mitglieder-Tab sehen Admins eine inline-Liste „Beitrittsanfragen" mit ✓/✗-Buttons. Admins sehen Klarnamen aller Mitglieder, normale Mitglieder nur Nicknames (Datenschutz wird backend-seitig durch Strippen der `firstname`/`lastname`-Felder erzwungen). Konsistenzregeln für Verlassen/Löschen: der letzte Admin kann nicht verlassen (muss zuerst jemand:en promoten oder löschen), Löschen nur wenn genau ein Admin existiert. Logged-out User können die Liste der freigegebenen Gruppen browsen und werden beim Beitrittsversuch zum Login geleitet. CMS: neues `group`-Content-Type mit atomic-create-Endpoint (`POST /api/groups/atomic` analog Events/News), Membership-Endpoints (`request-join`, `approve/:userId`, `reject/:userId`, `leave`, `promote/:userId`, `demote/:userId`, `remove-member/:userId`), Lifecycle-Hooks für E-Mail bei Review-Entscheidung. VoiceOver kündigt Karten mit Mitgliederzahl + Beziehungsstatus, Beitrittsbuttons mit Nickname-Kontext und Mitglieder mit Rolle und „Optionen verfügbar"-Hinweis an. Offene Beitrittsanfragen sind für Admins jetzt auch außerhalb der Detail-Page sichtbar: roter Dot am „Gruppen"-Item im Side-Menü plus rotes Zahl-Badge inline neben dem Gruppennamen auf der Card in „Meine Gruppen"
- **Unsichtbare Gruppen** (CMS-kuratiert): neues `isHidden`-Flag im Group-Schema (default `false`). Hidden Groups tauchen nicht in „Alle Gruppen" auf, Detail-Endpoint liefert 404 für Nicht-Mitglieder. Mitglieder sehen die Gruppe in „Meine Gruppen" wie eine normale Gruppe; Gruppen-Admins und JUP-Admins (sofern Mitglied) können sie voll verwalten — Edit/Promote/Demote/Remove/Delete/Approve/Reject funktionieren analog zu normalen Gruppen. Was CMS-only bleibt: Sichtbarkeit (kein Discovery in „Alle Gruppen") und Beitritt (`request-join`/`cancel-request` antworten 403, Mitgliedschaft entsteht nur über Strapi)
- Viewcount für News und Events, Umfragen: analog zu Shorts wird beim Öffnen der Detailseite einmal pro Aufruf ein neuer Endpoint (`POST /api/events/{documentId}/view`, `POST /api/news-posts/{documentId}/view`) getriggert; die Anzeige „X Mal angesehen" erscheint dezent in der Header-Meta-Zeile der Detail-Page sowie in den Listen-Cards, ist aber nur für JUP-Admins (`isJUPAdmin`) sichtbar. Normaluser sehen den Counter nicht — ihre Aufrufe zählen aber dennoch. CMS: neues `viewCount`-Integer-Feld in News- und Event-Schema (default 0), Controller-Logik analog Shorts. VoiceOver kündigt den Counter mit „nur für Administratoren sichtbar"-Hinweis an
- **Anmeldeschluss für Events**: optionaler Stichtag, der im Create-Wizard (Step 3) als „Soll es einen Anmeldeschluss geben?"-Switch gesetzt werden kann. Ab dem hinterlegten Tag ist der „Teilnehmen"-Button in der Detail-Page deaktiviert + Hinweis „Anmeldung geschlossen"; bereits eingetragene User dürfen sich weiterhin austragen. Neue dedizierte CMS-Endpoints `POST /api/events/:documentId/join` und `DELETE /api/events/:documentId/leave` ersetzen den bisherigen generischen PUT-Bypass und validieren serverseitig gegen das neue Schema-Feld `signupClosesAt` (date, optional). 403-Response trägt eine konkrete Message für den Snackbar
- Bei der Registrierung können sich Institutionen jetzt selbst markieren (neue optionale Checkbox „Ich bin eine Institution und möchte eine Gruppe gründen können." über dem Verhaltenskodex). Das `canCreateGroup`-Flag wird ans CMS mitgeschickt (neu in der `register.allowedFields`-Whitelist); die endgültige Freigabe bleibt wie bisher beim JUZ im Rahmen der Registrierungs-Freischaltung. Alte App-Versionen ohne das Feld funktionieren weiter — der Schema-Default `false` greift
- **Push-Benachrichtigungen für Gruppeninhalte**: Wird eine Umfrage/News/Veranstaltung mit Gruppenbindung veröffentlicht, erhalten ausschließlich die Mitglieder dieser Gruppe eine Push („Neue Umfrage in _[Gruppenname]_") — zugestellt als Direkt-Push an die Geräte der Mitglieder (members + admins + creator), nicht per Broadcast-Topic. Öffentliche (gruppenlose) Inhalte bleiben globaler Broadcast. Neuer Einstellungsbereich „Benachrichtigungen" mit zwei Abschnitten „JUZ" und „Meine Gruppen" (je News/Events/Umfragen); die Gruppen-Präferenzen werden zum CMS synchronisiert (neue User-Felder `groupNewsEnabled`/`groupEventsEnabled`/`groupSurveysEnabled`, default an) und serverseitig beim Versand berücksichtigt. Bei unklarer Gruppenauflösung wird fail-closed nichts gesendet (nie versehentlicher Broadcast)

- **Zugangsdaten in Keychain/Passwortmanager speichern**: Login- und Registrierungs-Formular unterstützen jetzt System-Autofill (iOS Keychain, Google Passwortmanager). Nach erfolgreichem Login/Registrierung erscheint die „Passwort sichern?"-Abfrage, beim nächsten Login werden die Zugangsdaten vorgeschlagen. Für iOS neu: Associated-Domains-Entitlement (`webcredentials:<YOUR_HOST>`) + AASA-Auslieferung über eine neue CMS-Middleware

### Changed

- Session-Laufzeit von 30 auf 180 Tage erhöht (`jwt.expiresIn` im CMS explizit gesetzt; die bisherige `jwtManagement`/`sessions`-Refresh-Config war mit Strapi 5.23 wirkungslos und wurde entfernt)
- Erstell-Routen für News, Events und Umfragen sind im App-Router jetzt zusätzlich per `ContentCreateGuard` gesichert (vorher: nur Auth-Check). Erlaubt sind JUZ-Admins und Group-Admins; alle anderen werden zurückgewiesen. Verhindert das Erreichen der Create-Pages per Deeplink durch Nicht-Berechtigte (Defense in depth, Backend lehnte bereits ab)

### Changed

- Event-Erstellung: das bisherige „Ablaufdatum" heißt jetzt „Enddatum" und ist nur noch bei wiederkehrenden Events wählbar — es markiert das Ende der Wiederholungsserie. Wird die Wiederholung wieder ausgeschaltet, wird auch das Enddatum verworfen
- Group-Detail- und Group-Settings-Page nutzen jetzt die zentrale `SubPageAppBar` statt jeweils einer handgebauten AppBar mit eigener Statusbar-Inset-Kompensation. Damit teilen sie das Verhalten mit den ~17 anderen Sub-Pages (Auth, Content, Profile-Settings), inklusive transparenter Darstellung bei aktivem Background-Pattern
- Snackbars bleiben jetzt einheitlich 5 Sekunden sichtbar (vorher Flutter-Default von 4 Sekunden). Hintergrund: bei Undo-Actions blieb der Tap-Slot oft zu knapp, jetzt geht alles über die neue `context.showAppSnackbar(...)`-Extension
- JUZ-Admins sehen im Mitglieder-Tab einer Gruppe ihre eigene Beitrittsanfrage jetzt mit dem Suffix „ (Ich)" hinter dem Nickname (z.B. „Patrick (Ich)") — analog zum Figma-Mock. Approve-/Reject-Buttons bleiben aktiv, JUZ-Admins können ihre eigene Anfrage direkt bestätigen; Tooltips passen sich an („Eigene Beitrittsanfrage annehmen/ablehnen")
- Versteckte Gruppen (`isHidden`) sind in „Meine Gruppen" und im AppBar-Titel der Detail-Page jetzt mit einem dezenten Schloss-Icon markiert; VoiceOver kündigt sie zusätzlich als „versteckte Gruppe" an. Damit erkennen Mitglieder und Admins auf einen Blick, dass die Gruppe nicht öffentlich auffindbar ist

### Fixed

- JUP-Admins bekommen im Mitglieder-Tab einer Gruppe kein Zähl-Badge mehr für neue Beitrittsanfragen. Der Badge-Hinweis ist nur noch für Gruppen-Admins gedacht; JUP-Admins können die Anfragen weiterhin sehen und annehmen/ablehnen, werden aber nicht mehr proaktiv darauf hingewiesen
- Beim ersten Login eines neuen Users werden Inhalte (News, Shorts, Events, Umfragen) nicht mehr fälschlich als „neu" markiert. Der Cutoff für die roten Dots im Drawer hängt jetzt am Zeitpunkt des ersten Logins statt am ersten App-Start
- „Jup, bin dabei"-Button reagiert wieder auf Tap. Zwei Ursachen, beide aus dem `signupClosesAt`-Commit: (1) der `EventParticipationNotifier` machte beim Anlegen einen redundanten `fetchEventById`-Roundtrip — schlug der fehl, landete der State in `AsyncValue.error` und `toggleParticipation` brach am `state.value == null`-Guard stillschweigend ab (kein Spinner, kein Fehler, nichts). (2) die neuen `/events/:id/join` und `/.../leave`-Endpoints im CMS aktualisierten via `strapi.documents().update()` nur den **Draft**, die App liest aber via `find`/`findOne` den **Published-Stand** — der blieb leer, sodass die App den User weiterhin als „nicht zugesagt" anzeigte und beim nächsten Tap an einem Dedup-400 hängenblieb. Der Notifier startet jetzt leer (das Event ist ohnehin schon im `eventsListProvider`), der Toggle bekommt den aktuellen Teilnahmestatus explizit übergeben, Fehler werden als Snackbar sichtbar gemacht, und die CMS-`join`/`leave`-Actions publishen den Event-Stand nach jedem `update()` sofort nach
- Fixed Shorts-Push-Notifications
- User werden beim App-Start nicht mehr ausgeloggt, wenn das Backend vorübergehend mit einem Server-Fehler (5xx) antwortet — der gespeicherte Login wird nur noch bei tatsächlich ungültigem Token (401) verworfen
- Sortierung im Events-Tab „Alle": vorbei-Events landen jetzt zuverlässig am Ende, auch direkt nach dem Reload. Hauptursache war die Pagination: mit `sort=startTime:asc` und `pageSize=10` lieferte Strapi zuerst die ältesten Events zurück — wenn das alles past-Events waren, sah der User direkt 10 vorbei-Events, und die zukünftigen tauchten erst nach `loadMore` auf. `EventsListNotifier` lädt jetzt in zwei Phasen: erst zukünftige Events (`startTime >= now`, ASC), nach Erschöpfung past-Events (`startTime < now`, DESC). Innerhalb der „Vorbei"-Gruppe: jüngste zuerst. `sortWithBadges` wird zusätzlich mit explizitem `compare`-Parameter aufgerufen, damit die Reihenfolge auch in den „Gemerkt"/„Zugesagt"-Tabs deterministisch ist
- Kommentar-Löschen lief bisher als clientseitiger `PUT` mit der vollständigen Kommentar-Liste (ohne den zu löschenden Eintrag); das Backend prüfte beim `update` keinerlei Autor:innen-/Admin-Berechtigung, sodass jeder eingeloggte User per direktem API-Aufruf Kommentare an fremden Events/Umfragen löschen oder ändern konnte. Es gibt jetzt dedizierte `DELETE /api/events/{documentId}/comments/{commentId}` und `DELETE /api/surveys/{documentId}/comments/{commentId}` Endpoints, die serverseitig prüfen `user.isJUPAdmin || comment.author.id === user.id`. App-Controller (`events_controller.dart`, `surveys_controller.dart`) wurden auf diese Endpoints umgestellt; bei 403 erscheint die Meldung „Du darfst diesen Kommentar nicht löschen." statt eines generischen Fehlers
- `SubPageAppBar`: doppelte Statusbar-Höhe in `preferredSize` entfernt. Bisher addierte das Widget `MediaQuery.padding.top` selbst zur preferredSize, was sich mit dem Statusbar-Inset doppelte, das Material's `Scaffold` (primary=true) automatisch oben drauf legt. Effekt: ~50 px Whitespace zwischen AppBar und Body-Start. In den bisherigen ~17 Verwendungen unsichtbar, weil deren Body-Content sowieso Top-Padding hatte; in der neuen Group-Detail-Page mit nahtloser TabBar wurde es offensichtlich. AppBar liegt jetzt direkt am Body-Start
- Orphan-Uploads beim Abbruch von Create-Wizards: News-, Event- und Umfrage-Erstellung läuft jetzt atomar über drei neue CMS-Endpoints (`POST /api/{news-posts,events,surveys}/atomic`). Hero-Bild, Block-Medien und Metadaten gehen in einem einzigen Multipart-Request an das CMS — schlägt der Create-Schritt fehl, werden bereits hochgeladene Files serverseitig wieder entfernt, statt als Waisen in der Strapi-Media-Library liegenzubleiben. Reduziert nebenbei die Submit-Latenz, weil Block-Medien nicht mehr sequentiell vor dem Create hochgeladen werden müssen
- Auth-Init beim App-Start ohne Netz: ein gültiger Login-Token wurde bei `SocketException` aus dem User-Lookup stumm verworfen, sodass der User trotz vorhandener Session auf die „nicht eingeloggt"-View fiel. Der Token bleibt jetzt im AuthState erhalten; `isAuthenticated` hängt nur noch am JWT, nicht zusätzlich am User-Objekt. Der Profil-Tab zeigt in diesem Übergangs-Zustand das bekannte Sad-Star-Widget mit „Nochmal probieren"-Button (`ConnectionErrorWidget`); der Tap stößt `loadSession()` neu an und holt die User-Daten nach, sobald die Verbindung steht. Echte 401-Antworten (ungültiger/abgelaufener Token) loggen den User weiterhin sauber aus
- Accessibility in den Create-Wizards: `CompactDropdown` (Stunden-/Minuten-Picker), `NumberSpinner` (Survey-`maxVotes`, ±-Buttons) und die Bild-/Video-Vorschauen in `HeroImageUploadTile`, `ContentBlockTile` und `VideoThumbnail` sind jetzt für VoiceOver/TalkBack als Buttons/Bilder mit aussagekräftigen Labels annonciert; die bisherigen Tooltip-Fallbacks reichten dafür nicht
- `StrapiClient`: API-Aufrufe mit `useUserAuth: true` fielen bei fehlendem User-Token still auf den App-Token zurück. Stattdessen wird jetzt eine `AppException('Du bist nicht eingeloggt.')` geworfen — verhindert, dass User-Aktionen versehentlich mit anonymem Token den Server erreichen
- Surveys-Liste lädt auch ohne Login wieder (öffentliche Sicht). Durch das verschärfte `useUserAuth`-Hardening warf `SurveysController.fetchSurveys` für nicht eingeloggte User „Du bist nicht eingeloggt." und die `SurveysLoggedOutPage` blieb leer. Das Listing geht jetzt wie News/Events/Shorts mit dem App-Token raus; Voting, Kommentare und Custom-Options bleiben weiterhin user-token-pflichtig
- Shorts-Preview auf Home- und News-Übersicht: Sortierreihenfolge ist wieder rein chronologisch (neueste zuerst). Bisher gruppierte `sortWithBadges` die Liste in „Neu > Gesehen" und schob jüngere bereits angesehene Shorts hinter ältere noch ungesehene. Die NEW/SEEN-Information bleibt als Badge erhalten, beeinflusst aber nicht mehr die Reihenfolge. Vollbild-Feed war nicht betroffen — er nutzte schon vorher direkt die Controller-Sortierung
- Placeholder-Banner für Gruppen ohne eigenes Bild: `GroupCard` zeigte bisher nur einen farbigen Container mit `Icons.groups`-Icon, `_GroupImage` im Detail-Header lud fälschlicherweise das Event-Placeholder (`placeholder_event_*.svg`). Beide Stellen nutzen jetzt die neuen `placeholder_groups_{light,dark}.svg`-Banner aus `assets/banners/` — Theme-abhängig, mit dem im Repo etablierten `Transform.scale`-Zoom-Pattern (Card 1.2, Detail-Header 1.3)
- Fehlermeldungen bei Membership-Aktionen (Beitritt anfragen, Anfrage zurückziehen, verlassen, befördern, …) waren bisher generisch und doppelt — Snackbar zeigte „Aktion fehlgeschlagen: Aktion fehlgeschlagen.". `GroupsController._membershipPost` extrahiert jetzt die konkrete Strapi-Response-Message aus dem Error-Body (`body.error.message`) und gibt sie 1:1 an den Snackbar weiter, z.B. „Du bist bereits Mitglied dieser Gruppe.", „Diese Gruppe ist noch nicht freigegeben." oder „Du hast keine Berechtigung, Gruppen zu erstellen.". Netzwerk- und Decode-Fehler fallen weiterhin auf die zentrale `ErrorHandler.parseError`-Logik zurück (Offline-/Timeout-/Status-Code-Texte)
- Chip-Abstand im ersten Schritt der Create-Wizards (News, Events, Umfragen) ist jetzt einheitlich: News und Events nutzten `WrapAlignment.spaceEvenly`, was den Restplatz zwischen den Chips verteilte und je nach Zeilenfüllung unterschiedlich große Lücken erzeugte. Alle drei Flows verwenden nun zentrierten 16 px-Abstand (`WrapAlignment.center` + `runAlignment: start`), passend zum Figma-Design
- Nach einer Beitrittsanfrage erscheint die Gruppe jetzt sofort unter „Meine Gruppen" mit dem Info-Tag „Anfrage gesendet" + Hourglass-Icon (analog zum bestehenden „In Prüfung"-Tag für Group-Review-`pending`). Der bisherige Action-Button auf der `requestSent`-Card entfällt — Cancel-Pfad ist in der App nicht mehr exponiert. CMS-Filter `GET /api/groups?mine=true` wurde um `pendingRequests` erweitert, `sanitizeGroup` gibt nicht-Admins ausschließlich ihren eigenen pending-Eintrag zurück (fremde Anfragen bleiben Admins vorbehalten, kein PII-Leak). `GroupMembershipNotifier` triggert nach jedem Fehler einen Best-Effort-Refresh beider Listen-Provider — bei „Deine Beitrittsanfrage ist bereits offen."-Konflikten (z.B. nach App-Restart mit veraltetem lokalem Stand) holt sich der Client damit sofort den korrekten Server-State, sodass die Card im nächsten Frame auf den Info-Tag schaltet
- Tab „Alle Gruppen" zeigte trotz offener eigener Beitrittsanfrage weiterhin den „Gruppe beitreten"-Button. Ursache: der Listing-Call ging mit App-Token raus, das CMS-Backend sah keinen `requester` und konnte den Self-Inclusion-Branch im Sanitizer nicht greifen. `GroupsListNotifier` reicht jetzt `useUserAuth` durch und beide Listen-Provider (`all`, `my`) nutzen User-Auth, sobald jemand eingeloggt ist — die `requestSent`-Card mit „Anfrage gesendet"-Tag erscheint nun konsistent in beiden Tabs. Logged-out User bleiben beim App-Token (keine Anfragen erwartet)
- Kommentare auf Umfragen werden in der Detail-Ansicht jetzt verlässlich nach Timestamp sortiert (neueste zuerst). Bisher kam die unsortierte CMS-Reihenfolge an
- Filtern der News-Kategorie lieferte gelegentlich die ungefilterte Liste, weil der Filter-Provider zwei parallele Fetch-Calls auslöste und je nach Antwortreihenfolge der falsche gewinnen konnte. Die Filterung wird jetzt atomar beim Aufbau des Providers gesetzt
- Kommentar-Löschen ist im 3-Punkte-Menü als eigener „Löschen"-Eintrag erreichbar (vorher nur per Swipe-Geste); macht die Funktion auch für VoiceOver- und TalkBack-User auffindbar. Swipe-Geste bleibt zusätzlich verfügbar
- Backend-Sync-Konflikte beim Beitreten (Server kennt die offene Anfrage, Client noch nicht) zeigen jetzt einen Material-Dialog „Deine Beitrittsanfrage wird aktuell noch geprüft. Du bekommst eine E-Mail, sobald deine Anfrage angenommen oder abgelehnt wurde." statt eines technischen Snackbar-Hinweises. Andere Fehler (Offline, „Bereits Mitglied", 500) bleiben weiterhin als Snackbar mit der konkreten Backend-Message
- Fehler-Anzeige in der Gruppen-Liste rendert keine rohen Dart-Type-Errors mehr (z.B. „type 'Null' is not a subtype of type 'bool' of 'function result'"). `_buildList` gibt jetzt — analog zu Events/Surveys — die zentrale `ErrorHandler.parseError`-Lokalisierung weiter (Offline-/Timeout-/Status-Code-Texte, sonst Fallback „Das hat nicht geklappt. Versuch's nochmal."). Im Debug-Build wird zusätzlich der Stack-Trace inklusive `onlyMine`/`useUserAuth`-Kontext geloggt, um die exakte Quelle solcher Type-Errors beim nächsten Auftreten identifizieren zu können

## [2.4.1] - 2026-06-03

### Added

- Umfragen-Cards: Tap auf das Card-Bild öffnet es jetzt im Vollbild-Viewer mit Hero-Animation und Drag-to-Dismiss — analog zum bestehenden Verhalten in News- und Event-Detail-Bildern. Placeholder-Banner und Election-Star bleiben non-interactive

### Fixed

- Registrierungs-Erfolgsseite: Android-Back-Geste schloss bisher die App, weil `RegisterPage` per `replaceAll([RegisterSuccessRoute()])` navigiert und damit den gesamten Auto-Route-Stack leert. `PopScope` mit `canPop: false` führt die Back-Geste jetzt — analog zum bereits vorhandenen „Zur Startseite"-Button — zur `AuthRoute` im Profile-Tab (`MainRoute → ProfileNavigationRoute → AuthRoute`). Navigation in eine private `_navigateToStart`-Methode extrahiert, sodass Button und Back-Geste identisches Verhalten teilen

### Changed

- Teilen von Events und News: der Share-Button öffnet jetzt einen Auswahldialog mit zwei Optionen — „Als Link teilen" (öffnet das System-Share-Sheet mit einem erklärenden Begleittext und Mail-Subject, sodass Empfänger sehen, dass die JUP-App zum Öffnen benötigt wird) oder „QR-Code anzeigen" (zeigt einen scanbaren QR-Code für den `jup://`-Deep-Link, der beim Scannen mit der Kamera direkt in der App öffnet). Bisher wurde stumm nur die nackte `jup://`-URL geteilt, die in WhatsApp/Mail/Slack nicht als klickbarer Link erkannt wurde

### Fixed

- Android-12+-Splashscreen: JUP!-Logo wirkte sehr klein. Untertitel aus dem Splash-Asset (`assets/icons/JUP.png`) entfernt, sodass das Logo den maximal nutzbaren Anteil der kreisförmigen Android-12-Sichtbarkeitszone ausfüllt; `icon_background_color: '#9A7FFE'` in `flutter_native_splash.yaml` ergänzt, was den sichtbaren Icon-Bereich von 108dp auf 160dp erweitert. Untertitel bleibt unverändert in `splash.png` (Android < 12), Onboarding und sonstigen In-App-Stellen
- Umfragen-Cards: Untertitel-Texte (Frage-Beschreibung) wurden nach 2 Zeilen mit „…" abgeschnitten und waren damit teilweise unlesbar. `maxLines`/`TextOverflow.ellipsis` aus den `BodyMedium`-Subtitle-Texten der Ja/Nein- und Multiple-Choice/Election-Card entfernt — Beschreibungstexte werden jetzt immer vollständig dargestellt
- Create-Stepper (News, Events, Umfragen): AppBar-Title saß zu nah an der Statusbar und die Statusbar-Icons folgten nicht dem App-Theme. AppBar-Höhe von 104→120 px und Title mit zusätzlichem Top-Padding (+16 px) versehen; `systemOverlayStyle` mit dem etablierten App-Pattern (Light Mode → dunkle Icons, Dark Mode → helle Icons) gesetzt, wie in `SubPageAppBar`/`MainAppBar` bereits in Verwendung
- Logout / Profil löschen: nach „Ausloggen bestätigen" zeigte der Profil-Tab beim erneuten Antippen noch die Einstellungen-Seite samt offenem Logout-Bottom-Sheet, die News-Seite blitzte zudem kurz im eingeloggten Zustand auf, und während des FCM-Backend-Clears (~0,5–1,5 s) hingen die Bestätigungs-Bottom-Sheets ohne sichtbares Feedback. Ursachen: (1) `replaceAll([MainRoute()])` wirkte auf den nested `ProfileNavigationRouter` statt auf den Root-Router, sodass der IndexedStack des Profil-Tabs nie geleert wurde; (2) `authNotifier.logout()` wurde nicht awaited — der State-Flip auf `isAuthenticated=false` lag hinter den FCM-Backend-Calls, bis dahin renderten andere Tabs mit altem Auth-State; (3) Bestätigungs-Buttons hatten keinen Loading-State. Beide Sheets wurden in eigene `ConsumerStatefulWidget`s (`_LogoutBottomSheet`, `_DeleteProfileBottomSheet`) extrahiert mit lokalem `_isLoading`-Flag (Pattern wie in `custom_option_sheet`/`report_bottom_sheet` etabliert). Der Logout **awaitet** jetzt den vollständigen `logout()`-Durchlauf (Reihenfolge unverändert, weil `clearFcmTokenInBackend` den gültigen Auth-Header braucht), zeigt währenddessen einen 20×20-Spinner statt des Button-Texts und disabled Abbrechen + Bestätigen, und schaltet erst nach dem State-Flip `currentTabIndexProvider` + Tab-Index auf News um und resettet den Profil-Tab-Stack explizit auf `AuthRoute`
- Verifizierungsscreen: brach optisch aus dem App-Pattern aus, weil der Content direkt auf dem Surface-Hintergrund lag (kein „weißer" Content-Block wie auf den anderen Sub-Pages). Texte werden jetzt analog zu Impressum/Datenschutz/AGB in einen `Container` mit `surfaceContainerLowest`-Hintergrund gelegt; überflüssiger `Stack`-Wrapper mit nur einem Kind entfernt
- Push-Notifications (News & Events): Tippen auf eine Notification öffnete bisher die jeweilige Übersichtsseite ohne AppBar statt der Detail-Page. Ursache: `Navigator.of(context).push(MaterialPageRoute(...))` in `notification_service.dart` mischte die Material Navigator API mit dem auto_route-Tab-Stack (Drawer-Eintrag), dadurch wurde `canPop=true` auf dem aktiven Tab und `MainPage` blendete folgerichtig die AppBar aus; zusätzlich lief der nachfolgende `context.router.pop()` + `navigate()` in `NotificationDetailHandlerPage` in eine Race-Condition, sodass die Detail-Route verloren ging und nur die Overview sichtbar blieb. Der Push erfolgt jetzt über die bereits registrierte `NotificationDetailHandlerRoute` als Top-Level auto_route, und der Handler setzt erst den Ziel-Tab-Stack, bevor er sich via `removeLast()` selbst entfernt — damit landet der User direkt auf der `NewsDetailPage`/`EventDetailPage` mit deren eigener AppBar und Back-Navigation zur Overview

## [2.4.0] - 2026-05-22

### Fixed

- Android-Spacing: auf Tabs mit Hintergrund-Pattern (News, Events) entstand zwischen TabBar und Tab-Inhalt sowie zwischen AppBar und erstem Listen-Element ein zu großer vertikaler Abstand. Ursache: bei `extendBodyBehindAppBar: true` bleibt `MediaQuery.padding.top` unverbraucht und wird zusätzlich vom internen Padding-Default der `ListView` erneut addiert. Der Body-Content wird nun zentral mit `MediaQuery.removePadding(removeTop: true)` umhüllt, sodass nachgelagerte Scrollables und Widgets das Statusbar-Padding nicht erneut anwenden; analog wurde das nun redundante `SafeArea` aus dem `OfflineBanner` entfernt
- Offline-Modus: das zuletzt gecachte WLAN-Passwort bleibt jetzt offline sichtbar. Statt die App komplett durch den „Oops! Du bist gerade offline"-Fullscreen zu ersetzen, zeigt ein dezenter Offline-Banner unter der AppBar den Status an; gecachte Inhalte (z.B. WLAN-Passwort in News-Banner und Profil-Settings) bleiben weiter zugänglich. Screens ohne Cache fallen wie bisher auf das partielle `ConnectionErrorWidget` zurück
- Welcome-Header (klein & groß): Button- und Schriftfarben sind nun Theme-unabhängig immer in Light-Farben — der lila Hintergrund (`primaryFixed`) ist in Light und Dark identisch, dadurch waren im Dark Mode die Buttons (hellviolett auf hellviolett) und der „Einloggen"-Text (dunkelviolett auf lila) kaum lesbar. Lokaler `Theme(data: lightTheme, …)`-Wrapper sorgt jetzt für konsistenten Kontrast in beiden Modi
- Bottom Sheets: Inhalte wurden auf Android unten von der System-Navigations-/Gestenleiste überdeckt — Buttons und ListTiles am unteren Rand waren teils nicht klickbar. Neuer zentraler Wrapper `showJupBottomSheet` setzt das Bottom-Padding jetzt korrekt auf `max(viewInsets.bottom, viewPadding.bottom)`; alle 10 vorhandenen `showModalBottomSheet`-Aufrufe (Login, Profil-Settings, Logout-/Löschen-/Nickname-/Passwort-Dialog, WiFi-Passwort, Umfrage-Custom-Option, Media-Source, Report) wurden darauf migriert. Sheet-Hintergrund reicht weiterhin Material-3-typisch bis zum Display-Rand
- Push-Notifications: nicht eingeloggte User bekommen keine Broadcast-Notifications mehr. Topic-Subscriptions (news/events/surveys), System-Permission-Anfrage und FCM-Token-Sync sind jetzt strikt an den Login gebunden; beim Logout wird der FCM-Token zusätzlich im Backend zurückgesetzt. Bestehende Installationen ohne Login werden beim nächsten App-Start automatisch von allen Topics abgemeldet
- Android: Statusbar wird wieder angezeigt — `windowFullscreen=true` aus dem `LaunchTheme` entfernt (war versehentlich mit der Splashscreen-Korrektur eingeflossen und blieb nach dem Splash als Window-Flag bestehen)
- News/Shorts/Umfragen-Sortierung: Inhalte mit terminierter Veröffentlichung (`publishAt` in der Zukunft) springen nach Pull-to-Refresh nicht mehr in die Listenmitte. Sortierung nutzt jetzt clientseitig die tatsächliche Sichtbarkeitszeit (`publishAt`, sonst `createdAt`) statt nur des DB-Erstelldatums
- News-Detail: Video-Blöcke wurden als kaputter Bild-Placeholder angezeigt (Skia `Failed to decode image`), weil Strapi 5 das `mime`-Feld in nested-populate-Antworten weglassen kann. `StrapiFile.isVideo`/`isImage` nutzen jetzt zusätzlich die URL-Endung als Fallback
- News-Detail: hochkant gefilmte Videos überfüllten die Seite. Inline-Player ist jetzt auf 60 % der Bildschirmhöhe gedeckelt — Portrait-Videos werden schmaler und zentriert dargestellt, Landscape-Videos bleiben full width
- AppBar überlagerte bei aktivem Hintergrund-Pattern den Content. Der Content-Layer des Body-Stacks reichte durch `extendBodyBehindAppBar` bis hinter die transparente AppBar und verdeckte dort das Pattern. Content beginnt jetzt per Top-Padding (`kToolbarHeight + viewPadding.top`) sauber unter der AppBar; Pattern bleibt durchgehend als Wallpaper über AppBar und Body sichtbar
- Scroll-to-Top via Drawer-Tap funktionierte auf den Tabs „Profil" und „Hilfen" nicht mehr — die `ScrollController`-Registrierung benutzte noch die alten Tab-Indizes von vor der Menü-Umsortierung (Profil registrierte sich auf Index 3, Hilfen auf 4, real ist es umgekehrt). Indizes werden jetzt dynamisch aus `firstLevelDestinations` via neuem `tabIndexOf(NavigationElement)`-Helper aufgelöst, sodass sie bei zukünftigen Umsortierungen automatisch korrekt bleiben

### Added

- In-App-Erstellung für News und Events: JUP-Admins können beide Inhaltstypen direkt aus der App heraus anlegen — über einen kontextuellen „+ News" / „+ Event"-Button im Drawer (sichtbar nur für Admins im jeweiligen Tab)
- Content-Blöcke: News und Events bestehen aus einem Pflicht-Text plus optionalen Text-, Bild- und Video-Blöcken in beliebiger Reihenfolge
- Bild-Upload (Galerie oder Kamera) mit automatischem Zuschnitt — Hero-Bild auf 16:9, Inhalts-Bilder auf 4:3 (image_cropper)
- Video-Upload für Inhalts-Blöcke; Block-Vorschau zeigt ein Thumbnail (erstes Frame) statt eines generischen Play-Icons
- Events: optionale Wiederholungen (wöchentlich/monatlich/jährlich, CMS-Lifecycle erstellt die Folge-Events) und optionales Ablaufdatum
- News- und Event-Detail: rendert die Content-Blöcke (Text + Bild + Video) in der vom Autor angelegten Reihenfolge; ältere Einträge ohne Blöcke fallen weiterhin auf das `text`-Feld zurück
- News-Detail: Inline-Video-Player für Video-Blöcke (tap toggelt Play/Pause, Progress-Bar mit Scrubbing, kein Autoplay)
- News- und Event-Detail: Bilder (Hauptbild und Content-Block-Bilder) sind jetzt antippbar und öffnen sich in einer Vollbildansicht — Hero-Animation in einen schwarzen Viewer, schließbar per Swipe-down, X-Button oder System-Back. Voiceover/TalkBack annonciert die Bilder als Buttons mit Doppeltipp-Hinweis; Placeholder-SVGs (wenn kein Bild gepflegt ist) bleiben bewusst nicht-interaktiv

### Changed

- Hauptnavigation umgestellt: Bottom-Tabs durch linksseitiges Seitenmenü (Drawer) ersetzt — Vorbereitung für weitere Menüpunkte
- Reihenfolge der Hauptnavigation angepasst: Hilfen jetzt vor Profil
- Master-Scaffold-Refactor: AppBar liegt zentral im MainPage, Tab-Overview-Pages haben keine eigene AppBar mehr
- News-uneingeloggt: jup!-Logo wandert vom Banner in die AppBar; Banner zeigt nur noch Subtitle + Buttons
- CMS: News- und Event-Schema um `contentBlocks` (Dynamic Zone aus Text- und Media-Blöcken) erweitert; für News ist `text` jetzt optional und wird per Migration als erster Text-Block übernommen
- News-Erstellung: Kategorie-Label „Event" zu „Events" vereinheitlicht (gleiches Wording wie in der News-Detailansicht)
- Generische Wizard-Widgets (`CompactDropdown`, `VideoThumbnail`, `ContentBlockTile`, `HeroImageUploadTile`) nach `lib/shared/` verschoben — News- und Event-Wizard nutzen jetzt die gleichen Komponenten
- `EventRepeatType`-Enum an CMS-Schema angeglichen (`daily` entfernt, `yearly` ergänzt)
- Bildbereich auf Cards und Detailseiten für Events, News und Umfragen vereinheitlicht (16:9 via `AspectRatio`). Cards sind dadurch leicht größer (Events/News von 150 px, Umfragen von 120 px auf ~16:9), die Detail-Hero wird kompakter (von 300 px auf ~16:9). Dadurch zeigen Card und Detail denselben Bildausschnitt
- Abhängigkeits-Upgrades (Major-Versionssprünge ohne Verhaltensänderung):
  - `app_links` 6.4.1 → 7.0.0 (7.1.x ist intern auf AGP 9 ausgelegt; gepinnt auf 7.0.0)
  - `device_info_plus` 12.4.0 → 13.1.0
  - `package_info_plus` 9.0.1 → 10.1.0
  - `share_plus` 10.1.3 → 13.1.0 (Aufruf migriert von `Share.share` auf `SharePlus.instance.share(ShareParams(...))`)
  - `image_cropper` 9.1.0 → 12.2.1
  - `flutter_local_notifications` 17.0.0 → 21.0.0 (Aufrufe migriert auf benannte Parameter für `initialize` und `show`)
  - `flutter_riverpod` 2.5.1 → 3.3.1 (alle 19 Provider-Definitions-Files importieren zusätzlich `package:flutter_riverpod/legacy.dart` für `StateNotifier`/`StateNotifierProvider`/`StateProvider`; vier Aufrufe von `AsyncValue.valueOrNull` umgestellt auf das in v3 nullable gewordene `value`)
- Android-Toolchain angehoben (Voraussetzung für `app_links 7.x`): Gradle 8.12 → 8.14, Android Gradle Plugin 8.9.1 → 8.11.1, Kotlin 2.1.0 → 2.2.20
- `gradle.properties`: `android.newDsl=false` → `true` (Voraussetzung für `app_links 7.0`-Build mit der neuen AGP-DSL)

## [2.3.1] - 2026-05-07

### Fixed

- Umfragen: Dialog „Bereits abgestimmt" (sowie „Nicht erlaubt" und „Umfrage abgelaufen") ließ sich nicht mehr per „Ok" schließen und warf intern `Null check operator used on a null value`. Ursache war eine Regression aus dem Pop-Up-Refactoring: der Dialog wird via `navigatorKey.currentContext` auf dem Root-Navigator geöffnet, der Ok-Button popte aber den (nested) Tab-Navigator des Aufrufer-Contexts. Aktionen sind jetzt in einen `Builder` gewrappt und nutzen den Dialog-eigenen Context (analog zu `login_page.dart`)
- Push-Notifications: nicht eingeloggte User bekommen keine Broadcast-Notifications mehr. Topic-Subscriptions (news/events/surveys), System-Permission-Anfrage und FCM-Token-Sync sind jetzt strikt an den Login gebunden; beim Logout wird der FCM-Token zusätzlich im Backend zurückgesetzt. Bestehende Installationen ohne Login werden beim nächsten App-Start automatisch von allen Topics abgemeldet

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
