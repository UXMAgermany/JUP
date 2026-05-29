# JUP! - Jugendapp

> **JU**gendap**P** für das Amt Süderbrarup

A modern Flutter mobile application connecting youth in the Amt Süderbrarup community through events, surveys, news, and social features.

**Download the app:**

- 📱 [Google Play Store](https://play.google.com/store/apps/details?id=com.suederbrarup.jup)
- 🍎 [iOS App Store ](https://apps.apple.com/de/app/jup/id6757519533)

## 📱 About

JUP! is a community engagement platform designed for young people in Süderbrarup. The app provides:

- **Events** - Discover and participate in local events with categories like sports, music, food, gaming, DIY
- **Surveys & Polls** - Vote on community topics with yes/no polls, multiple-choice surveys, and multi-vote elections ("Wahl"); users can submit and vote on custom free-text options
- **News** - Stay updated with local news and announcements
- **Shorts** - Watch and engage with short video content
- **Comments** - Discuss and interact on events, surveys, and news
- **Help** - Browse local help offerings and frequently asked questions (FAQs)
- **Profile** - Customise your avatar and manage your account
- **Push Notifications** - Stay informed about new events, surveys, and accepted survey contributions
- **Content Reporting** - Report inappropriate content on comments and shorts

## 🏗️ Architecture

### Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod 2.5+
- **Navigation**: AutoRoute 10+
- **Backend**: Strapi CMS (REST API)
- **Local Storage**: Flutter Secure Storage, Shared Preferences
- **UI**: Material Design 3
- **Analytics**: Matomo (GDPR-compliant, opt-in, pseudonymized)

### Project Structure

```
lib/
├── features/              # Feature modules
│   ├── auth/             # Authentication & user management
│   ├── content/          # Static content (FAQs, Markdown screens)
│   ├── events/           # Event browsing and participation
│   ├── files/            # File downloads (e.g. WiFi password)
│   ├── news/             # News articles
│   ├── profile/          # User profile and avatar
│   ├── shorts/           # Short videos
│   └── surveys/          # Surveys and polls
├── router/               # AutoRoute navigation configuration
├── shared/               # Shared utilities and widgets
│   ├── controllers/      # Session management, API config
│   ├── models/          # Shared data models
│   ├── widgets/         # Reusable UI components
│   └── utils/           # Helper functions
└── main.dart            # App entry point

test/                     # Test suite
├── features/            # Feature-specific tests
└── shared/              # Shared component tests
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.0 or higher
- Dart SDK 3.9.0 or higher
- iOS: Xcode 14+ with iOS Simulator
- Android: Android Studio with Android SDK
- Node.js (for version bumping)
- **Strapi Backend**: This app requires a Strapi 5.x backend. See the [jup-cms](https://github.com/your-org/jup-cms) repository for backend setup instructions.

**Recommended IDEs:**

- Visual Studio Code with Flutter extension
- IntelliJ IDEA / Android Studio with Flutter plugin

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/UXMAgermany/JUP.git
   cd jup
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up environment variables**

   Copy `.env.example` to `.env` and configure your Strapi backend:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your backend configuration:

   ```env
   STRAPI_BASE_URL=http://your-strapi-backend-url:1337
   STRAPI_BASE_URL_MACHINE=http://your-local-ip:1337  # For Android emulator
   STRAPI_API_TOKEN=your-api-token-here
   ```

   > **Note**: You need a running Strapi backend. See [Backend Setup](#-backend-setup) section below.

4. **(Optional) Configure Matomo Analytics**

   If you want to use analytics tracking, add Matomo configuration to `.env`:

   ```env
   MATOMO_URL=https://your-matomo-instance.com
   MATOMO_SITE_ID=1
   MATOMO_USER_SALT=your-secure-random-salt-here
   ```

   See [Matomo Integration Guide](lib/shared/services/README_MATOMO.md) for details.

5. **Generate code** (routes, mocks)

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### iOS Setup

For iOS development, install CocoaPods dependencies:

```bash
cd ios
pod install
cd ..
```

**Troubleshooting:** If Ruby installation fails, install via Homebrew:

```bash
brew install cocoapods
```

## 🧪 Testing

The project includes comprehensive unit tests for models and controllers.

**Run all tests:**

```bash
flutter test
```

**Run specific test files:**

```bash
flutter test test/features/events/models/event_model_test.dart
flutter test test/features/surveys/controllers/surveys_controller_test.dart
```

**Test coverage includes:**

- ✅ Model tests (Events, Surveys, Comments)
- ✅ Controller smoke tests
- ✅ Business logic validation
- ✅ JSON parsing and serialization
- ✅ Edge case handling

## 🛠️ Development

### Code Generation

This project uses code generation for routing and mocking:

```bash
# Generate routes after adding new pages
dart run build_runner build

# Clean and regenerate if issues occur
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**Important:** Add `@RoutePage()` annotation to new page widgets for AutoRoute generation.

### Adding a New Feature

1. Create feature directory under `lib/features/<feature_name>/`
2. Organize into subdirectories:
   - `models/` - Data models
   - `controllers/` - State management (Riverpod providers)
   - `screens/` - UI pages
   - `widgets/` - Feature-specific widgets
3. Add routes in `lib/router/app_router.dart`
4. Run code generation
5. Write tests in `test/features/<feature_name>/`

### Shared Components

Reusable components live in `lib/shared/`:

- **Widgets**: `comment_section.dart`, `async_state_builder.dart`, `event_card_wrapper.dart`
- **Models**: `comment_model.dart` (used across features)
- **Extensions**: `padding_extension.dart` for widget helpers

### State Management Patterns

Using Riverpod with these patterns:

- `StateNotifier` for complex state (lists, pagination)
- `FutureProvider` for async data fetching
- `Provider` for controllers and services
- Family modifiers for parameterized providers

Example:

```dart
final eventsListProvider =
  StateNotifierProvider<EventsListNotifier, AsyncValue<List<EventEntry>>>((ref) {
    final controller = ref.watch(eventsControllerProvider);
    return EventsListNotifier(controller);
});
```

## 📦 Building for Release

### Version Bumping

Update version following semantic versioning:

```bash
npx commit-and-tag-version
```

This updates `pubspec.yaml`, `CHANGELOG.md`, and creates a git tag.

### Manual Version Update

Edit `pubspec.yaml`:

```yaml
version: 1.2.3+4 # version+build_number
```

Then clean and rebuild:

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### Build Commands

**iOS:**

```bash
flutter build ios --release
```

**Android:**

```bash
flutter build apk --release      # APK
flutter build appbundle --release # App Bundle (recommended)
```

## 🎨 Design System

The app uses Material Design 3 with custom typography:

- **Primary Font**: Work Sans (Medium 500, Regular 400)
- **Display Font**: Rubik (Medium 500, Regular 400)

**Custom Widgets:**

- `HeadlineSmallEmphasized`, `BodyLarge`, `LabelLarge` - Consistent text styles
- `CommentSection` - Unified commenting interface

## 🐛 Troubleshooting

### Build Runner Issues

If generated files have errors:

```bash
dart run build_runner clean
rm -rf .dart_tool
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Hot Reload Not Working

```bash
flutter clean
flutter pub get
flutter run
```

### CocoaPods Issues (iOS)

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Environment Variables Not Loading

Ensure `.env` file exists in project root and run:

```bash
flutter clean
flutter pub get
```

## 📝 Code Style

Follow Flutter's official style guide. Key conventions:

- Use `dart format` before committing
- Follow Material Design 3 guidelines
- Keep widgets under 300 lines (extract to separate files)
- Prefer composition over inheritance
- Use const constructors where possible

## 🔐 Security

- **Never commit `.env` file** - it's in `.gitignore`
- **Never commit Firebase config files** - `google-services.json` and `GoogleService-Info.plist` are gitignored
- **Never commit signing keys** - `.jks`, `.keystore` files are gitignored
- API tokens are environment-specific
- Use Flutter Secure Storage for sensitive data
- Session tokens managed securely

For security issues, please see [SECURITY.md](SECURITY.md).

## 🔧 Backend Setup

This app requires a Strapi 5.x backend to function. The backend handles:

- User authentication and management
- Content management (events, news, surveys, shorts)
- Push notifications
- File storage

**Backend Repository**: [jup-cms](https://github.com/your-org/jup-cms)

The backend repository includes:

- Complete Strapi configuration
- Content type definitions
- API documentation
- Setup instructions

## 🔥 Firebase Setup

This app uses Firebase for push notifications. To set up your own Firebase project:

1. **Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com)

2. **Add Android app**:
   - Package name: `com.suederbrarup.jup`
   - Download `google-services.json`
   - Place in `android/app/google-services.json`

3. **Add iOS app** (when ready):
   - Bundle ID: (to be determined)
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/GoogleService-Info.plist`

4. **Enable Firebase Cloud Messaging (FCM)**:
   - Go to Project Settings → Cloud Messaging
   - Enable Cloud Messaging API

> # **Note**: These config files are gitignored. Each developer/deployment needs their own Firebase project.

## 📊 Privacy & Analytics

### Matomo Tracking (Optional, GDPR-Compliant)

The app includes **optional** Matomo analytics with strict privacy protections:

**What is tracked:**

- Screen views (page navigation)
- User sessions (with pseudonymized IDs)

**What is NOT tracked:**

- User interactions (clicks, votes, bookmarks)
- Personal data (names, emails, etc.)
- IP addresses (anonymized on server)

**Privacy Protections:**

- ✅ **Opt-in only**: Users must explicitly consent during registration
- ✅ **Age verification**: Only users 16+ can enable tracking (GDPR Art. 8)
- ✅ **Pseudonymization**: User IDs are SHA-256 hashed before sending
- ✅ **Conditional**: Checkbox only shown to users 16+
- ✅ **Transparent**: Users are informed data is pseudonymized

**For developers:**

- Matomo configuration is optional (app works without it)
- See [Matomo Integration Guide](lib/shared/services/README_MATOMO.md) for details
- Configure via `.env` file (see `.env.example`)

## 📄 License

This project is licensed under the **European Union Public Licence (EUPL) v1.2** - see the [LICENSE](LICENSE) file for details.

The EUPL is an open source copyleft license approved by the European Commission. It is compatible with many other open source licenses including GPL v2/v3, AGPL v3, and others (see LICENSE appendix for full list).

**Key features of EUPL:**

- ✅ Copyleft license ensuring derivatives remain open source
- ✅ Compatible with major open source licenses (GPL, AGPL, MPL, etc.)
- ✅ Available in all EU official languages with equal legal value
- ✅ Specifically designed for European public sector software
- ✅ Addresses EU-specific legal requirements

Copyright (c) 2025 Amt Süderbrarup

Licensed under the EUPL

## 📞 Support

For issues, questions, or bug reports:

- Open an issue on the [GitHub issue tracker](https://github.com/your-org/jup/issues)

## 🤝 Contributing

This project is primarily maintained by Amt Süderbrarup. While the code is open source for transparency and learning purposes, we are not actively seeking external contributions at this time.

If you find a bug or security issue, please report it via the issue tracker.

---

JUP! - Team 💜
