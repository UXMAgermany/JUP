# iOS CI/CD with Fastlane - Complete Setup Guide

This guide documents how to set up automated iOS builds and TestFlight deployment using Fastlane, Fastlane Match, and GitLab CI/CD.

## Overview

**What this setup provides:**

- Automated iOS builds with proper code signing via Fastlane Match
- Certificates and profiles stored securely in GitLab Secure Files
- Automated deployment to TestFlight
- Secure credential management via App Store Connect API Key
- GitLab CI/CD integration with macOS runner

**Pipeline Flow:**

```
Code Push → Lint → Test → Build IPA (with Match signing) → Deploy to TestFlight
```

---

## Prerequisites

- Flutter project with iOS support
- GitLab repository with CI/CD enabled
- Apple Developer account with your app created
- App Store Connect access
- macOS GitLab Runner (iOS builds require macOS)
- Ruby installed locally (for Fastlane)
- Xcode installed

---

## Part 1: Apple Developer Setup

### 1.1 Register App ID

1. Go to **Apple Developer** → **Certificates, Identifiers & Profiles**
2. Click **Identifiers** → **+** (Add new)
3. Select **App IDs** → Continue
4. Select **App** → Continue
5. Enter:
   - **Description:** Your App Name
   - **Bundle ID:** Explicit, e.g., `de.yourcompany.yourapp`
6. Select **Capabilities** as needed:
   - Push Notifications (if using)
   - Associated Domains (for deep links)
7. Click **Register**

### 1.2 Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **Apps** → **+** → **New App**
3. Fill in:
   - **Platform:** iOS
   - **Name:** Your App Name
   - **Primary Language:** Your language
   - **Bundle ID:** Select the one created in 1.1
   - **SKU:** Unique identifier (e.g., `yourapp-ios-2026`)
4. Click **Create**

---

## Part 2: Local Fastlane Setup

### 2.1 Create Gemfile

Create `ios/Gemfile`:

```ruby
source "https://rubygems.org"

gem "fastlane", "~> 2.225"
```

### 2.2 Install Dependencies

```bash
cd ios
bundle install
```

This creates a `Gemfile.lock` - commit this file to version control.

### 2.3 Initialize Fastlane

```bash
cd ios
bundle exec fastlane init
# Select option 2 for TestFlight
```

### 2.4 Configure Appfile

Create/update `ios/fastlane/Appfile`:

```ruby
app_identifier("de.yourcompany.yourapp")

# Apple Developer Team ID (found in Apple Developer account)
team_id("XXXXXXXXXX")

# App Store Connect Team ID (may differ from team_id)
itc_team_id("123456789")
```

**Finding your Team IDs:**

- **team_id:** Apple Developer → Membership → Team ID
- **itc_team_id:** Run `bundle exec fastlane spaceship` or check App Store Connect URL

---

## Part 3: App Store Connect API Key

The API Key is the recommended authentication method for CI/CD. It doesn't require 2FA and doesn't expire.

### 3.1 Create API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **Users and Access**
3. Select **Integrations** tab (top)
4. Click **App Store Connect API** (left sidebar)
5. Click **Generate API Key** or **+**
6. Enter:
   - **Name:** e.g., `Fastlane CI`
   - **Access:** Admin (or App Manager)
7. Click **Generate**

### 3.2 Download and Save Credentials

After creation, note down:

| Credential    | Location                    | Example                                |
| ------------- | --------------------------- | -------------------------------------- |
| **Issuer ID** | Top of the page             | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| **Key ID**    | In the table                | `XXXXXXXXXX`                           |
| **.p8 File**  | Download button (one-time!) | `AuthKey_XXXXXXXXXX.p8`                |

**Important:** The .p8 file can only be downloaded **once**! Store it securely.

### 3.3 Create api_key.json

Create `ios/fastlane/api_key.json`:

```json
{
  "key_id": "YOUR_KEY_ID",
  "issuer_id": "YOUR_ISSUER_ID",
  "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "in_house": false
}
```

Or place the `.p8` file directly in `ios/fastlane/` and reference it in the Fastfile.

### 3.4 Update .gitignore

Add to `.gitignore`:

```gitignore
# iOS Fastlane secrets
/ios/fastlane/AuthKey_*.p8
/ios/fastlane/api_key.json
/ios/.bundle
/ios/vendor
```

### 3.5 Configure GitLab Apple App Store Connect Integration

This integration connects GitLab with App Store Connect, allowing the CI pipeline to upload builds to TestFlight.

1. Go to GitLab Project → **Settings** → **Integrations**
2. Find and click **Apple App Store Connect**
3. Enable the integration and configure:
   - **Issuer ID:** Your App Store Connect Issuer ID (from Part 3.2)
   - **Key ID:** Your API Key ID (from Part 3.2)
   - **Private Key:** Paste the contents of your `.p8` file
4. Click **Save changes**
5. Optionally click **Test settings** to verify the connection

**Note:** This integration allows GitLab to authenticate with App Store Connect without needing to pass credentials in the CI pipeline.

---

## Part 4: Fastlane Match Setup (Code Signing)

Fastlane Match manages code signing certificates and provisioning profiles, storing them in GitLab Secure Files.

### 4.1 Create GitLab Project Access Token

1. Go to GitLab Project → **Settings** → **Access Tokens**
2. Create token:
   - **Name:** `fastlane-match`
   - **Role:** Maintainer
   - **Scopes:** `api`
3. **Copy and save the token** (shown only once!)

### 4.2 Generate Distribution Certificate

```bash
# Run in a secure directory
cd ~/Desktop

# 1. Generate private key
openssl genrsa -out distribution_private.key 2048

# 2. Generate CSR
openssl req -new -key distribution_private.key -out distribution.csr \
  -subj "/CN=Apple Distribution Certificate"

# 3. Go to Apple Developer Portal:
    https://developer.apple.com/account/resources/certificates/add
    - Select "Apple Distribution"
    - Upload distribution.csr
    - Download the .cer file (e.g., distribution.cer)
```

### 4.3 Create .p12 by exporting from Keychain Access

**IMPORTANT:** Do NOT create the .p12 file with OpenSSL! You must export it from Keychain Access.

OpenSSL-generated .p12 files cause "MAC verification failed during PKCS12 import" errors because OpenSSL 3.x uses encryption algorithms incompatible with macOS.

**Steps:**

1. **Import private key to Keychain:**

   ```bash
   open ~/Desktop/distribution_private.key
   ```

   - Add to **login** keychain

2. **Import certificate to Keychain:**

   ```bash
   open ~/Desktop/distribution.cer
   ```

   - Add to **login** keychain

3. **Export as .p12 from Keychain Access:**
   - Open **Keychain Access** app
   - Select **login** keychain (left sidebar)
   - Click **My Certificates** category
   - Find `Apple Distribution: Your Company (TEAM_ID)`
   - The certificate **MUST** show a triangle (>) indicating it has a private key attached
   - Right-click → **Export**
   - Choose format: **Personal Information Exchange (.p12)**
   - Save as `distribution.p12`
   - **Leave password empty!**

### 4.4 Initialize Fastlane Match

```bash
cd ios

# Initialize match
bundle exec fastlane match init
# Select option 4: gitlab_secure_files
# Enter GitLab project path: your-group/your-project
# Enter GitLab host: https://gitlab.yourcompany.com
```

This creates `ios/fastlane/Matchfile`.

### 4.5 Import Certificate

```bash
cd ios


bundle exec fastlane match import --type appstore

# When prompted:
#   - Certificate path: <PATH-TO-DESKTOP-OR-CERT-LOCATION>//2SUWPHKKHW_distribution_5K3R9XTKSP.p12 (your .p12 file)
#   - Private key path: Same .p12 file (it contains both cert and key)
#   - Provisioning profile: Press Enter (leave empty)
#   - URL to the git repo containing all the certificates: Press Enter (leave empty)
#   - Gitlab Access Token: Your Fastlane Access token created in 4.1
#   - Please provide your Apple Developer Program account credentials (Username): Your developer apple id

```

### 4.6 Generate Provisioning Profile

```bash
cd ios

bundle exec fastlane match appstore \
  --api_key_path fastlane/api_key.json

# When prompted:
#   - Gitlab Access Token: Your Fastlane Access token created in 4.1
#   - Username: Your developer apple id
```

This creates the `match AppStore de.yourcompany.yourapp` provisioning profile.

---

## Part 5: Configure Xcode for Manual Signing

For CI builds, use **manual signing** with Match-managed profiles. Debug builds can stay on Automatic for local development.

### 5.1 Update via Xcode UI

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target
3. Go to **Signing & Capabilities** tab
4. In the top dropdown, select **Release** configuration
5. Uncheck **Automatically manage signing**
6. Select **Provisioning Profile:** `match AppStore de.yourcompany.yourapp`
7. Team will be auto-selected based on the profile
8. Switch to **Debug** configuration and keep **Automatically manage signing** checked

### 5.3 Verify Configuration

After updating, verify:

- Debug builds still work locally with automatic signing
- The Release configuration shows the Match provisioning profile
- No signing errors when building Release locally

---

## Part 6: Configure Fastfile

Update `ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and sign the application for distribution, upload to TestFlight"
  lane :beta do
    # Download and install the correct signing certificates
    # https://docs.fastlane.tools/actions/match/
    match(type: 'appstore', readonly: true)

    # Login to App Store Connect using GitLab integration
    # Environment variables are provided by GitLab Apple App Store Connect integration
    # https://docs.fastlane.tools/actions/app_store_connect_api_key/
    app_store_connect_api_key(
      is_key_content_base64: true
    )

    # Increment build number using CI pipeline ID
    # https://docs.fastlane.tools/actions/increment_build_number/
    increment_build_number(
      build_number: ENV['CI_PIPELINE_ID'] || Time.now.strftime("%Y%m%d%H%M"),
      xcodeproj: "Runner.xcodeproj"
    )

    # Build the app
    # https://docs.fastlane.tools/actions/build_app/
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store"
    )

    # Upload to TestFlight
    # https://docs.fastlane.tools/actions/upload_to_testflight/
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
end
```

**Note:** With the GitLab Apple App Store Connect integration (Part 3.5), you don't need to manually specify API key credentials. The `is_key_content_base64: true` option tells Fastlane to use the environment variables provided by the integration.

---

## Part 7: GitLab CI/CD Configuration

### 7.1 Secure Files

Fastlane Match automatically uploads certificates and profiles to GitLab Secure Files during setup.

With the GitLab Apple App Store Connect integration (Part 3.5), you **don't need** to upload API key files separately - the integration handles authentication automatically.

### 7.2 Set CI/CD Variables

Go to **GitLab** → **Settings** → **CI/CD** → **Variables** and add:

| Variable        | Value                            | Protected | Masked |
| --------------- | -------------------------------- | --------- | ------ |
| `PRIVATE_TOKEN` | Your GitLab project access token | Yes       | Yes    |

### 7.3 Update .gitlab-ci.yml

```yaml
stages:
  - lint
  - test
  - package
  - beta_deployment

variables:
  LC_ALL: 'en_US.UTF-8'
  LANG: 'en_US.UTF-8'

cache:
  key:
    files:
      - Gemfile.lock
  paths:
    - vendor/bundle

# iOS base configuration
.setup_ios:
  before_script:
    - touch .env # Create empty .env file if needed
    - flutter upgrade # Not running in container, may need to upgrade
    - flutter pub get
    - cd ios/
    - gem install --user-install bundler
    - bundle config --local set path 'vendor/bundle'
    - bundle check || bundle install
    - pod update # Hotfix for pods issues
  tags:
    - ios # Your macOS runner tag

# Build iOS (without signing - Fastlane handles signing in deployment)
build_ios:
  stage: package
  extends: .setup_ios
  script:
    - cd $CI_PROJECT_DIR
    # Build iOS app without codesigning
    - |
      flutter build ios --release --no-codesign \
        --build-number=$CI_PIPELINE_ID \
        --dart-define=YOUR_VAR="${YOUR_VAR}"
  artifacts:
    untracked: true
    expire_in: 1 day
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: never
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: always
    - when: manual
      allow_failure: true

# Deploy to TestFlight
ios_testflight_deployment:
  stage: beta_deployment
  extends: .setup_ios
  script:
    - bundle exec fastlane ios beta
  only:
    - main
  when: manual
```

**Note:** The deployment job is simple because:

- `.setup_ios` handles all the setup (flutter, bundler, pods)
- Match automatically downloads certificates from GitLab Secure Files
- The GitLab Apple App Store Connect integration provides API credentials

---

## Part 8: Testing the Setup

### 8.1 Test Local Match

```bash
cd ios

# Test Match can fetch certificates
bundle exec fastlane match appstore --readonly
```

This verifies that Match can successfully download certificates and provisioning profiles from GitLab Secure Files.

### 8.2 Test CI/CD Pipeline

1. Push to main branch
2. Check GitLab CI/CD → Pipelines
3. Verify:
   - Build creates IPA artifact
   - Match successfully fetches certificates
4. Manually trigger deployment job
5. Check App Store Connect → TestFlight for uploaded build

---

## Troubleshooting

### "No signing certificate found" or "No profiles found" in CI

- Ensure Match is configured in your Fastfile lanes
- Verify `PRIVATE_TOKEN` CI variable is set
- Check that certificates/profiles are uploaded to GitLab Secure Files
- Run `bundle exec fastlane match appstore --readonly` locally to verify

### "Is a directory" error during match import

- You entered a directory path instead of a file path
- Provide full paths to the actual `.cer` and `.p12` files

### Match asks for Git repo URL (when using gitlab_secure_files)

- Add explicit parameters to bypass prompts:
  ```bash
  bundle exec fastlane match import \
    --type appstore \
    --storage_mode gitlab_secure_files \
    --gitlab_project "your-group/your-project" \
    --gitlab_host "https://gitlab.yourcompany.com"
  ```

### "Failed to get authorization for username"

- Don't use Apple ID authentication in CI; use API Key instead
- Ensure API Key has Admin or App Manager access
- Add `--api_key_path fastlane/api_key.json` to match commands

### "Multiple App Store Connect teams found"

- Add `itc_team_id` to your Appfile
- Find your team ID by running `bundle exec fastlane spaceship`

### "Version code already exists"

- TestFlight requires unique, incrementing build numbers
- Use `--build-number=$CI_PIPELINE_ID` in flutter build
- Or use `increment_build_number` in Fastfile

### Bundle install fails with bundler version error

- Install compatible bundler: `gem install bundler:2.7.2`
- Run with specific version: `bundle _2.7.2_ install`

### "MAC verification failed during PKCS12 import (wrong password?)"

This error occurs when the .p12 file was created with OpenSSL instead of exported from Keychain Access.

**Solution:** Follow section 4.3 - export the .p12 from Keychain Access, not with OpenSSL. Leave the password empty.

### "Could not create another Distribution certificate, reached maximum"

Apple limits the number of Distribution certificates per team. Solutions:

1. **Use existing certificate** - Run Match in readonly mode:

   ```bash
   bundle exec fastlane match appstore --readonly
   ```

2. **Clean up old certificates** - Go to Apple Developer Portal → Certificates and delete unused Distribution certificates

3. **Re-import certificate to Secure Files** - If you deleted certificate files from GitLab Secure Files:
   ```bash
   # Download .cer from Apple Developer Portal (click on certificate → Download)
   # Export .p12 from Keychain Access
   bundle exec fastlane match import --type appstore
   # Then generate profile:
   bundle exec fastlane match appstore
   ```

### "Provisioning profile doesn't include signing certificate"

This happens when you have multiple profiles and the selected one references a different/deleted certificate.

1. **In Xcode**: Check Signing & Capabilities → Release → Select the profile that shows a valid certificate
2. **Clean up Apple Developer Portal**: Delete old profiles that reference non-existent certificates
3. **Clean up GitLab Secure Files**: Delete old `.mobileprovision` files
4. **Regenerate**: Run `bundle exec fastlane match appstore --force`

### "The name 'match AppStore ...' is already taken"

An old profile with that name exists in Apple Developer Portal. Options:

1. **Delete the old profile** in Apple Developer Portal → Profiles, then re-run Match
2. **Or ignore it** - Match will create a profile with a timestamp suffix (e.g., `match AppStore de.yourapp 1768290236`). This works fine but is less clean.

### Certificate in Secure Files doesn't match Apple Developer Portal

If `cert_id` mismatch errors occur:

1. Delete certificate files from GitLab Secure Files
2. Delete the corresponding certificate from Apple Developer Portal (if it's orphaned)
3. Re-import your current certificate:
   ```bash
   bundle exec fastlane match import --type appstore
   bundle exec fastlane match appstore
   ```

### Match asks for Apple ID credentials

When Match prompts for username/password instead of using API key:

- **For local testing**: Either enter your Apple ID credentials, or create a local `api_key.json` and use `--api_key_path`
- **In CI**: The GitLab Apple App Store Connect integration provides credentials automatically via environment variables

### Long build times (20-30+ minutes)

First builds on the CI runner take longer because:

- All CocoaPods dependencies must be compiled from scratch
- Firebase and other large libraries have many source files
- No cached derived data exists

This is normal for first builds. Subsequent builds should be faster if the runner caches build artifacts.

---

## File Structure Reference

```
project/
├── .gitlab-ci.yml
├── pubspec.yaml
├── .gitignore
├── ios/
│   ├── Gemfile
│   ├── Gemfile.lock              # Commit this
│   ├── Runner.xcworkspace
│   ├── Runner/
│   │   ├── Assets.xcassets/
│   │   │   └── AppIcon.appiconset/
│   │   ├── Runner.entitlements
│   │   └── GoogleService-Info.plist  # DO NOT commit
│   └── fastlane/
│       ├── Appfile
│       ├── Fastfile
│       └── Matchfile               # Match configuration
```

**Note:** With the GitLab Apple App Store Connect integration (Part 3.5), you no longer need `api_key.json` or `AuthKey_*.p8` files in your repository or secure files.

---

## Security Checklist

- [ ] GitLab Apple App Store Connect integration configured (Part 3.5)
- [ ] API Key (.p8 file) backed up securely (cannot be re-downloaded from Apple!)
- [ ] `PRIVATE_TOKEN` set as protected CI variable
- [ ] `GoogleService-Info.plist` in `.gitignore` (if using Firebase)
- [ ] Distribution certificate private key backed up securely
- [ ] .p12 exported from Keychain Access (NOT created with OpenSSL!)
- [ ] Certificates and profiles uploaded to GitLab Secure Files via Match

---

## Useful Links

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/)
- [Fastlane Pilot (TestFlight)](https://docs.fastlane.tools/actions/pilot/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [GitLab Secure Files](https://docs.gitlab.com/ee/ci/secure_files/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Apple Developer Portal](https://developer.apple.com/)
