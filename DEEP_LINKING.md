# Deep Linking Guide

JUP supports deep links to allow users to share and open specific content directly in the app.

## 📱 Supported Deep Links

### Shorts

```
jup://shorts/<documentId>
```

**Example**: `jup://shorts/abc123`

**Behavior**: Opens the shorts feed and displays the specific short

### Events

```
jup://events/<documentId>
```

**Example**: `jup://events/def456`

**Behavior**: Opens the event detail page

### News

```
jup://news/<documentId>
```

**Example**: `jup://news/ghi789`

**Behavior**: Opens the news article detail page

### Surveys

```
jup://surveys/<documentId>
```

**Example**: `jup://surveys/jkl012`

**Behavior**: Opens the surveys overview page (surveys display inline, no detail page)

## 🔄 How It Works

### 1. Share Functionality

All detail pages have a share button that generates deep links:

**Shorts** (shorts_feed_item.dart:311-315):

```dart
final deepLink = _deepLinkService.generateShortsLink(short.documentId);
await Share.share(deepLink);
```

**Events** (event_detail_page.dart:101-104):

```dart
final deepLink = _deepLinkService.generateEventLink(eventEntry.documentId);
await Share.share(deepLink);
```

**News** (news_detail_page.dart:85-88):

```dart
final deepLink = _deepLinkService.generateNewsLink(newsEntry.documentId);
await Share.share(deepLink);
```

### 2. Deep Link Handling

When a user clicks a deep link:

1. **App not running**: Link launches the app and navigates to content
2. **App in background**: Link brings app to foreground and navigates
3. **App already open**: Link navigates to content immediately

**Implementation**: `main.dart:116-168` handles all deep link types

### 3. Content Loading

For events and news:

- Deep link handler uses `NotificationDetailHandlerPage`
- Page fetches content by document ID
- Shows loading indicator while fetching
- Navigates to detail page when data is loaded
- Shows error and redirects to overview if content not found

For shorts:

- Direct navigation to `ShortsFeedRoute` with `initialShortsId`
- Shorts feed handles loading and error states

## 🧪 Testing Deep Links

### On iOS Simulator

```bash
xcrun simctl openurl booted "jup://events/abc123"
xcrun simctl openurl booted "jup://news/def456"
xcrun simctl openurl booted "jup://shorts/ghi789"
```

### On Android Emulator

```bash
adb shell am start -W -a android.intent.action.VIEW -d "jup://events/abc123" com.suederbrarup.jup
adb shell am start -W -a android.intent.action.VIEW -d "jup://news/def456" com.suederbrarup.jup
adb shell am start -W -a android.intent.action.VIEW -d "jup://shorts/ghi789" com.suederbrarup.jup
```

### On Physical Device

Share a link via WhatsApp, Messages, etc., and tap it.

## ⚙️ Configuration

### Android (Already Configured)

`android/app/src/main/AndroidManifest.xml` lines 30-35:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="jup"/>
</intent-filter>
```

### iOS Configuration

Check `ios/Runner/Info.plist` for URL scheme configuration. Should include:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.suederbrarup.jup</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>jup</string>
        </array>
    </dict>
</array>
```

## 🔧 Implementation Details

### Service: DeepLinkService

Location: `lib/shared/services/deep_link_service.dart`

**Methods**:

- `generateShortsLink(String shortsId)` → `jup://shorts/{id}`
- `generateNewsLink(String newsId)` → `jup://news/{id}`
- `generateEventLink(String eventId)` → `jup://events/{id}`
- `generateSurveyLink(String surveyId)` → `jup://surveys/{id}`
- `parseShortsId(Uri)` → Extract shorts ID from URI
- `parseNewsId(Uri)` → Extract news ID from URI
- `parseEventId(Uri)` → Extract event ID from URI
- `parseSurveyId(Uri)` → Extract survey ID from URI

### Handler Page

Location: `lib/shared/screens/notification_detail_handler_page.dart`

Handles deep links for events and news by:

1. Fetching content by document ID
2. Showing loading state
3. Navigating to detail page with proper navigation stack
4. Handling errors gracefully

## 📋 Current Status

| Content Type | Share Button | Deep Link Generation | Deep Link Handling   |
| ------------ | ------------ | -------------------- | -------------------- |
| Shorts       | ✅ Yes       | ✅ Yes               | ✅ Yes               |
| Events       | ✅ Yes       | ✅ Yes               | ✅ Yes               |
| News         | ✅ Yes       | ✅ Yes               | ✅ Yes               |
| Surveys      | ❌ No        | ✅ Yes (available)   | ✅ Yes (to overview) |

## 🎯 Adding Share to Surveys (Optional)

Surveys don't have detail pages, so sharing is less useful. If needed, you could:

1. Add share button to survey cards
2. Link goes to surveys overview: `jup://surveys/abc123`
3. User sees all surveys and can find the one shared

Not implemented because surveys display inline without dedicated pages.

## 🚀 Usage for Developers

To share any content:

```dart
import 'package:jup/shared/services/deep_link_service.dart';
import 'package:share_plus/share_plus.dart';

final deepLinkService = DeepLinkService();

// Share an event
final link = deepLinkService.generateEventLink(eventDocumentId);
await Share.share('Check out this event: $link');

// Share news
final link = deepLinkService.generateNewsLink(newsDocumentId);
await Share.share('Check out this news: $link');

// Share a short
final link = deepLinkService.generateShortsLink(shortsDocumentId);
await Share.share('Watch this short: $link');
```

## ✅ Summary

Deep linking is **fully implemented** for:

- ✅ Shorts (with direct navigation to video)
- ✅ Events (with detail page via handler)
- ✅ News (with detail page via handler)
- ✅ Surveys (navigation to overview only)

Users can share content, and recipients can tap the link to open the app directly to that content!
