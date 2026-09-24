# iOS Signing Guide for Tunly

## Overview

This guide explains how to sign and install the Tunly iOS app using a free Apple ID. Since we don't have a paid Apple Developer Program membership, we'll use the free personal team signing approach.

## Important Limitations

- **7-day expiry**: Apps signed with a free Apple ID expire after 7 days
- **Device limitation**: You must manually register your device UDID
- **No App Store/TestFlight**: Distribution is limited to sideloading
- **Weekly re-signing**: You'll need to re-sign the app every 7 days

## Method: AltStore/Sideloadly (Recommended)

This is the most reliable method for free-tier iOS app installation.

### Prerequisites

1. **AltStore** (on iOS) or **Sideloadly** (on Windows/Mac)
2. **Free Apple ID** (your personal Apple account)
3. **iTunes** (required for AltStore on Windows)
4. **Your iPhone's UDID** (can be found in Settings > General > About)

### Step 1: Get the Unsigned .ipa

1. Trigger the GitHub Actions workflow to build the iOS app
2. Download the `tunly-ios-unsigned` artifact from the Actions page
3. Extract the `Tunly-unsigned.ipa` file

### Step 2: Install via AltStore (iOS)

1. Install AltStore on your iPhone (requires a computer for initial setup)
2. Open AltStore on your iPhone
3. Tap the "+" button to add an app
4. Select the `Tunly-unsigned.ipa` file
5. Enter your Apple ID and password when prompted
6. Wait for the installation to complete

### Step 3: Install via Sideloadly (Windows/Mac)

1. Download and install Sideloadly
2. Connect your iPhone to your computer via USB
3. Open Sideloadly and select your device
4. Enter your Apple ID and app-specific password
5. Drag and drop the `Tunly-unsigned.ipa` file onto Sideloadly
6. Wait for the installation to complete

### Step 4: Trust the Developer Certificate

1. On your iPhone, go to Settings > General > VPN & Device Management
2. Find your Apple ID in the developer list
3. Tap "Trust [Your Name]"
4. Confirm by tapping "Trust"

## Automatic Re-signing

Both AltStore and Sideloadly handle automatic re-signing:

- **AltStore**: Automatically refreshes apps when connected to the same Wi-Fi network as your computer running AltServer
- **Sideloadly**: You can manually re-sign by connecting your device and running Sideloadly again

## Alternative: Manual Xcode Signing (Requires Mac)

If you have access to a Mac, you can sign directly in Xcode:

1. Open the project in Xcode: `open ios/Runner.xcworkspace`
2. Select your team (your personal Apple ID)
3. Connect your iPhone
4. Click "Run" to build and install

## Troubleshooting

### "Unable to verify app" error
- Make sure you've trusted the developer certificate in Settings
- Try reinstalling the app

### App expires after 7 days
- This is normal for free Apple ID signing
- Re-sign using AltStore/Sideloadly before expiration
- Set a reminder to re-sign weekly

### Installation fails
- Check that your device UDID is correctly registered
- Ensure you have enough storage space
- Try restarting your iPhone and computer

### Certificate errors
- Generate an app-specific password for your Apple ID
- Make sure 2FA is enabled on your Apple ID
- Check that your Apple ID is not locked

## Security Notes

- Never share your Apple ID password
- Use app-specific passwords when possible
- Only install apps from trusted sources
- The .ipa from our CI is safe to install

## References

- [AltStore Website](https://altstore.io/)
- [Sideloadly GitHub](https://github.com/Sideloadly/Sideloadly)
- [Apple Developer Documentation](https://developer.apple.com/support/xcode/)