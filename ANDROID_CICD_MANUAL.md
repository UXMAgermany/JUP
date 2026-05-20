# Android CI/CD with Fastlane - Complete Setup Guide

This guide documents how to set up automated Android builds and Play Store deployment using Fastlane and GitLab CI/CD from scratch.

## Overview

**What this setup provides:**

- Automated linting and testing on every push
- Signed AAB builds for releases
- Automated deployment to Google Play Store (Internal Track)
- Secure credential management via GitLab Secure Files

**Pipeline Flow:**

```
Code Push → Lint → Test → Build AAB → Deploy to Play Store
```

---

## Prerequisites

- Flutter project with Android support
- GitLab repository with CI/CD enabled
- Google Play Console account with your app created
- Ruby installed locally (for Fastlane)

---

## Part 1: Local Fastlane Setup

### 1.1 Initialize Fastlane in Android Directory

```bash
cd android
gem install bundler
```

### 1.2 Create Gemfile

Create `android/Gemfile`:

```ruby
source "https://rubygems.org"

gem "fastlane"
```

### 1.3 Install Dependencies

```bash
cd android
bundle install
```

This creates a `Gemfile.lock` - commit this file to version control.

### 1.4 Initialize Fastlane

```bash
bundle exec fastlane init
```

Select option 4 (Manual setup) when prompted.

### 1.5 Configure Appfile

Edit `android/fastlane/Appfile`:

```ruby
json_key_file("") # Path to service account JSON - configured in Fastfile instead
package_name("com.yourcompany.yourapp") # Your app's package name
```

### 1.6 Configure Fastfile

Edit `android/fastlane/Fastfile`:

```ruby
# This file contains the fastlane.tools configuration
# Documentation: https://docs.fastlane.tools

default_platform(:android)

platform :android do
  desc "Runs all the tests"
  lane :test do
    gradle(task: "test")
  end

  desc "Upload pre-built AAB to Play Store Internal Track"
  lane :beta do
    # Use the AAB already built by CI (from build_android job)
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      json_key: 'google-play-service-account.json',
      release_status: 'draft',  # Required while app is not yet published (see note below)
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

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
end
```

**Track options:**

- `internal` - Internal testing (limited testers)
- `alpha` - Closed testing
- `beta` - Open testing
- `production` - Production release

---

## Part 2: Android Signing Setup

### 2.1 Generate Upload Keystore

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

**Critical:**

- Store passwords securely (password manager recommended)
- Back up the keystore file - losing it means you can never update your app
- Never commit to version control

### 2.2 Create key.properties

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

For CI/CD, use absolute path:

```properties
storeFile=/builds/YOUR_GROUP/YOUR_PROJECT/android/upload-keystore.jks
```

### 2.3 Update .gitignore

Ensure these are in your `.gitignore`:

```gitignore
# Android signing
android/upload-keystore.jks
android/key.properties
android/google-play-service-account.json

# Local properties
android/local.properties
```

### 2.4 Configure build.gradle.kts

Edit `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties from key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yourcompany.yourapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.yourcompany.yourapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing for local development
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
```

---

## Part 3: Google Play Service Account

### 3.1 Create Service Account

1. Go to **Google Play Console** → **Settings** → **API access**
2. Click **Create new service account**
3. Follow link to **Google Cloud Console**
4. Create service account with name like `fastlane-supply`
5. Skip role assignment (not needed)
6. Click **Done**

### 3.2 Generate JSON Key

1. In Google Cloud Console, find your service account
2. Go to **Keys** tab
3. Click **Add Key** → **Create new key**
4. Select **JSON** format
5. Download the file (name it `google-play-service-account.json`)

### 3.3 Invite Service Account / Grant Permissions in Play Console

1. Return to **Google Play Console** → **Users & Permissions** → **Invite**
2. Enter your service account E-Mail Address (email was assigned in step 3.1)
3. Go to **App permissions** tab
4. Select your app
5. Grant these permissions:
   - **Release to production, exclude devices, and use Play App Signing**
   - Or for internal only: **Release apps to testing tracks**
6. Click **Invite user** and **Save**

---

## Part 4: GitLab CI/CD Configuration

### 4.1 Upload Secure Files

Go to **GitLab** → **Settings** → **CI/CD** → **Secure Files** and upload:

1. `upload-keystore.jks` - Your signing keystore
2. `key.properties` - Signing credentials (with CI path)
3. `google-play-service-account.json` - Play Store API credentials
4. `google-services.json` - Firebase config (if using Firebase, goes to android/app/)

### 4.2 Create .gitlab-ci.yml

Create `.gitlab-ci.yml` in project root:

```yaml
stages:
  - lint
  - test
  - package
  - beta_deployment

# Base configuration for Android jobs
.android_docker_image:
  image: 'ghcr.io/cirruslabs/flutter:3.35.0'
  tags:
    - node # Use your GitLab runner tag

# Setup for Fastlane jobs
.setup_fastlane_android:
  extends: .android_docker_image
  before_script:
    - cp .env.example .env || true
    - flutter pub get
    - cd android/
    - gem install --user-install bundler
    - bundle install

# Stage 1: Lint
lint:
  extends: .android_docker_image
  stage: lint
  before_script:
    - cp .env.example .env || true
    - flutter pub get
  script:
    - flutter analyze

# Stage 2: Code Quality (optional)
code_quality:
  extends: .android_docker_image
  stage: test
  before_script:
    - cp .env.example .env || true
    - flutter pub get
    - flutter pub global activate dart_code_metrics
    - export PATH="$PATH:$HOME/.pub-cache/bin"
  script:
    - metrics lib -r codeclimate > gl-code-quality-report.json
  artifacts:
    reports:
      codequality: gl-code-quality-report.json

# Stage 2: Unit Tests
unit_test:
  extends: .android_docker_image
  stage: test
  before_script:
    - cp .env.example .env || true
    - flutter pub get
  script:
    - flutter test --coverage

# Stage 3: Build Android AAB
build_android:
  stage: package
  extends: .setup_fastlane_android
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './'
  script:
    - apt update -y && apt install -y curl

    # Download signing files to android/ directory
    - cd /builds/YOUR_GROUP/YOUR_PROJECT/android
    - curl -s https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer | bash

    # Verify files downloaded
    - ls -la key.properties upload-keystore.jks

    # Download google-services.json to android/app/ (if using Firebase)
    - cd /builds/YOUR_GROUP/YOUR_PROJECT/android/app
    - curl -s https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer | bash

    # Return to project root for flutter build
    - cd /builds/YOUR_GROUP/YOUR_PROJECT
    - |
      flutter build appbundle --release \
        --build-number=$CI_PIPELINE_ID \
        --dart-define=STRAPI_BASE_URL="${STRAPI_BASE_URL}" \
        --dart-define=STRAPI_API_TOKEN="${STRAPI_API_TOKEN}"
  artifacts:
    paths:
      - build/app/outputs/bundle/release/app-release.aab
    expire_in: 1 day
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: never
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: always
    - when: manual
      allow_failure: true

# Stage 4: Deploy to Play Store
android_play_store_internal_deployment:
  stage: beta_deployment
  extends: .setup_fastlane_android
  dependencies:
    - build_android
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './android'  # Use relative path!
  script:
    - apt update -y && apt install -y curl
    - cd /builds/YOUR_GROUP/YOUR_PROJECT
    - curl -s https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer | bash

    # Verify secure files
    - ls -la android/key.properties android/upload-keystore.jks

    - cd android
    - bundle exec fastlane android beta
  only:
    - dev
    - main
  when: manual
```

**Important:** Replace `YOUR_GROUP/YOUR_PROJECT` with your actual GitLab path.

---

## Part 5: Testing the Setup

### 5.1 Test Local Build

```bash
# Build release AAB locally
flutter build appbundle --release

# Or use Fastlane (if you have service account configured)
cd android
bundle exec fastlane android deploy
```

### 5.2 Test CI/CD Pipeline

1. Push to main branch
2. Check GitLab CI/CD → Pipelines
3. Verify:
   - Lint passes
   - Tests pass
   - Build creates artifact
4. Manually trigger deployment job
5. Check Google Play Console for uploaded build

---

## Troubleshooting

### "Keystore not found" in CI

- Verify `upload-keystore.jks` is uploaded to GitLab Secure Files
- **Use relative paths** for `SECURE_FILES_DOWNLOAD_PATH` (e.g., `./android` not `/builds/.../android`)
- Absolute paths get appended to the current directory, causing duplicated paths
- Verify the download-secure-files script runs before the build

### "Invalid JSON key" error

- Verify `google-play-service-account.json` is valid JSON
- Check service account has correct permissions in Play Console
- Ensure the file is downloaded to the correct location

### "Version code already exists"

- Play Store requires unique, incrementing version codes
- Use `--build-number=$CI_PIPELINE_ID` to auto-increment
- Or manually bump `version` in `pubspec.yaml`

### "Only releases with status draft may be created on draft app"

- This error occurs when your app hasn't been published to Play Store yet
- Add `release_status: 'draft'` to your `upload_to_play_store` call in Fastfile
- Once your app is published for the first time, you can change this to `'completed'` or remove it

### Bundle install fails

- Commit `Gemfile.lock` to version control
- Ensure bundler version is compatible (2.x recommended)

### Signing configuration error

- Check `key.properties` has correct absolute paths for CI
- Verify passwords don't contain special characters needing escaping
- Ensure `storeFile` path is correct for your CI environment

---

## File Structure Reference

```
project/
├── .gitlab-ci.yml
├── pubspec.yaml
├── .gitignore
├── android/
│   ├── Gemfile
│   ├── Gemfile.lock          # Commit this
│   ├── key.properties        # DO NOT commit
│   ├── upload-keystore.jks   # DO NOT commit
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── google-services.json  # DO NOT commit (if using Firebase)
│   └── fastlane/
│       ├── Appfile
│       └── Fastfile
```

---

## Security Checklist

- [ ] `upload-keystore.jks` in `.gitignore`
- [ ] `key.properties` in `.gitignore`
- [ ] `google-play-service-account.json` in `.gitignore`
- [ ] Keystore backed up securely (not just in GitLab)
- [ ] Passwords stored in password manager
- [ ] Service account has minimal required permissions
- [ ] Secure Files used instead of CI/CD variables for files

---

## Useful Links

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane Supply (Play Store)](https://docs.fastlane.tools/actions/supply/)
- [GitLab Secure Files](https://docs.gitlab.com/ee/ci/secure_files/)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Google Play API Access](https://developers.google.com/android-publisher/getting_started)
