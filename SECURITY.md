# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in JUP, please report it responsibly:

1. **Do NOT** open a public issue
2. Email your findings to the address configured in `SUPPORT_EMAIL` environment variable
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond to security reports within 48 hours and work with you to address the issue.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Best Practices

### For Developers

1. **Never commit sensitive data**:
   - `.env` files (use `.env.example` instead)
   - Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`)
   - Signing keys (`.jks`, `.keystore`, `key.properties`)
   - API tokens or passwords
   - Google Play service account JSON files
   - Any file with private keys or certificates

2. **Environment variables**:
   - Use `.env` for local development (copy from `.env.example`)
   - Use `--dart-define` for production builds
   - Never hardcode credentials, emails, or URLs in source code
   - All configuration should use `ApiConfig` class from `lib/shared/utils/api_config.dart`
   - Generate secure random salts with: `openssl rand -hex 32`

3. **Dependencies**:
   - Keep Flutter and packages up to date
   - Run `flutter pub outdated` regularly
   - Review security advisories for dependencies

4. **Code review**:
   - Review all changes before merging
   - Pay special attention to authentication and data handling
   - Use `flutter analyze` to catch potential issues

### For Users

1. **Download only from official sources**:
   - Google Play Store: [com.suederbrarup.jup](https://play.google.com/store/apps/details?id=com.suederbrarup.jup)
   - iOS App Store [id6757519533](https://apps.apple.com/de/app/jup/id6757519533)

2. **Keep the app updated**:
   - Enable automatic updates
   - Security patches are released regularly

3. **Account security**:
   - Use a strong, unique password
   - Don't share your account credentials
   - Report suspicious activity

## Known Security Considerations

### Data Storage

- User credentials (JWT tokens) are stored using Flutter Secure Storage with platform-specific encryption
- User preferences are stored in SharedPreferences (non-sensitive data only)
- All network communication should use HTTPS in production

### Permissions

The app requests the following permissions:

- **Internet**: Required for API communication
- **Notifications**: Optional, for push notifications
- **Storage**: For caching images and videos

### Third-Party Services

This app integrates with:

- **Strapi CMS**: Backend API (self-hosted)
- **Firebase Cloud Messaging**: Push notifications
- **Google Play Services**: Android functionality

## Security Updates

Security updates are released as needed. Critical vulnerabilities will be patched as soon as possible and communicated through:

- GitHub releases
- App store update notes

## Acknowledgments

We appreciate the security research community and will acknowledge reporters (with permission) who help improve JUP's security.
