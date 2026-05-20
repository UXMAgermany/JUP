# Google Play Store Deployment Setup

This document outlines the required steps to configure the CI/CD pipeline for Google Play Store deployment.

## Prerequisites

Before deploying to the Play Store, you must complete the following setup:

### 1. Generate Upload Keystore

Generate a keystore for signing your app releases:

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

**Important:**
- Keep this keystore file secure and backed up
- Never commit it to version control (already in .gitignore)
- Record the passwords securely (you'll need them for CI/CD)

### 2. Configure GitLab Secure Files

Upload the following files to GitLab CI/CD → Settings → CI/CD → Secure Files:

1. **upload-keystore.jks** - Your signing keystore
2. **key.properties** - Contains signing credentials (see template below)

#### key.properties Template

Create `android/key.properties` locally (excluded from git):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/builds/amt-suederbrarup/jup-app/upload-keystore.jks
```

### 3. Set Up Google Play Service Account

1. Go to Google Play Console → Settings → API access
2. Create a new service account
3. Grant "Release to production, exclude devices, and use Play App Signing" permission
4. Download the JSON key file
5. Upload to GitLab Secure Files as `google-play-service-account.json`

### 4. Configure GitLab CI/CD Variables

Add the following variables in GitLab CI/CD → Settings → CI/CD → Variables:

| Variable Name | Value | Protected | Masked |
|--------------|-------|-----------|--------|
| `STORE_PASSWORD` | Your keystore password | ✓ | ✓ |
| `KEY_PASSWORD` | Your key password | ✓ | ✓ |
| `KEY_ALIAS` | upload | ✗ | ✗ |

### 5. Update Fastlane Configuration

The Fastfile is located at `android/fastlane/Fastfile`. Update the `deploy` lane:

```ruby
desc "Deploy a new version to the Google Play"
lane :deploy do
  gradle(task: "clean")

  upload_to_play_store(
    track: 'internal',  # or 'beta', 'production'
    aab: '../build/app/outputs/bundle/release/app-release.aab',
    json_key: '../google-play-service-account.json',
    skip_upload_metadata: true,
    skip_upload_images: true,
    skip_upload_screenshots: true
  )
end
```

### 6. Verify Build Configuration

Check `android/app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            val keystoreProperties = Properties()
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            }

            storeFile = file(keystoreProperties["storeFile"] ?: "")
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## CI/CD Pipeline

### Current Pipeline Stages

1. **lint** - Runs `flutter analyze`
2. **test** - Runs `flutter test --coverage`
3. **package** - Builds signed AAB for main branch
4. **beta_deployment** (commented out) - Deploys to Play Store

### Enabling Deployment

To enable automatic Play Store deployment:

1. Uncomment the `beta_deployment` stage in `.gitlab-ci.yml` (lines 107-117)
2. Ensure all secure files and variables are configured
3. Update the Fastfile deploy lane as shown above

### Manual Deployment

The `build_android` job creates a signed AAB artifact that can be manually uploaded to Play Store:

1. Go to GitLab CI/CD → Pipelines
2. Find the pipeline for your main branch
3. Download the `app-release.aab` artifact
4. Upload to Google Play Console manually

## Troubleshooting

### Build fails with "keystore not found"

- Verify upload-keystore.jks is in GitLab Secure Files
- Check that the download-secure-files script runs in build_android job
- Verify SECURE_FILES_DOWNLOAD_PATH is set correctly

### Bundle install fails

- Bundler version mismatch has been fixed (updated to 2.7.2)
- Gemfile.lock should be committed to version control

### Signing configuration error

- Verify key.properties exists and has correct values
- Check that file paths in key.properties are absolute paths for CI
- Ensure passwords don't contain special characters that need escaping

## Security Checklist

- ✓ upload-keystore.jks in .gitignore
- ✓ key.properties in .gitignore
- ✓ Passwords stored in GitLab CI/CD variables (masked)
- ✓ Service account JSON in Secure Files only
- ✗ TODO: Set up signing with key.properties template in CI

## Next Steps

1. Generate your upload keystore
2. Upload keystore and service account JSON to GitLab Secure Files
3. Configure GitLab CI/CD variables
4. Test build locally: `cd android && bundle exec fastlane android deploy`
5. Push to main branch and verify CI pipeline succeeds
6. Enable beta_deployment stage once confident

## Support

For issues with:
- **Play Store setup**: Check Google Play Console documentation
- **Fastlane**: See https://docs.fastlane.tools/
- **GitLab CI**: See GitLab CI/CD documentation
