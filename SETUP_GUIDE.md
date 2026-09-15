# Tunely Flutter Setup Guide

## Quick Start for iOS Development

### Prerequisites

1. **Install Flutter SDK**
   - Download from https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Run `flutter doctor` to verify installation

2. **Install Xcode**
   - Download from Mac App Store
   - Install Xcode command line tools: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
   - Accept Xcode license: `sudo xcodebuild -license`

3. **Install CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

### Project Setup

1. **Navigate to project directory**
   ```bash
   cd tunely_flutter
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install iOS dependencies**
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Flutter Liquid Glass Setup

The project uses `liquid_glass_renderer` for glassmorphism effects. This package:

- ✅ Works on iOS with Impeller rendering
- ✅ Provides stunning glass effects
- ⚠️ Is experimental - test thoroughly
- ⚠️ Requires iOS 13.0+

### Important Notes

- **Impeller Required**: The package only works with Impeller (Flutter's new rendering engine)
- **Performance**: Monitor memory usage and frame rates
- **Testing**: Test on actual devices, not just simulators
- **Limitations**: Maximum 16 blended shapes per group

## YouTube Integration

The app uses `youtube_player_flutter` for audio streaming:

### Configuration

The YouTube player is configured to:
- Hide video controls
- Auto-play when song starts
- Loop disabled
- Background playback (requires iOS setup)

### iOS Background Audio

To enable background audio, the following is already configured in `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Building for iOS

### Development Build
```bash
flutter build ios --debug --no-codesign
```

### Profile Build
```bash
flutter build ios --profile --no-codesign
```

### Release Build
```bash
flutter build ios --release
```

### Creating IPA File
```bash
flutter build ios --release
cd build/ios/iphoneos
zip -r tunely-ios.ipa Runner.app
```

## GitHub Actions Setup

The project includes automated iOS building via GitHub Actions.

### No Secrets Required

The workflow uses `--no-codesign` for development builds, so no Apple Developer account or secrets are needed initially.

### To Enable App Store Builds

For production builds with code signing, you'll need:

1. **Apple Developer Account** ($99/year)
2. **GitHub Secrets**:
   - `APPLE_ID`: Your Apple ID email
   - `APPLE_APP_SPECIFIC_PASSWORD`: App-specific password
   - `APPLE_TEAM_ID`: Your Team ID
   - `CERTIFICATE_BASE64`: Base64 encoded certificate
   - `CERTIFICATE_PASSWORD`: Certificate password

### Manual Build Trigger

1. Go to Actions tab in GitHub
2. Select "Build iOS IPA"
3. Click "Run workflow"
4. Choose build type (debug/profile/release)
5. Click "Run workflow"

## Installing IPA on iPhone

### Method 1: AltStore (Free)
1. Install AltStore from https://altstore.io
2. Connect iPhone to computer
3. Open AltStore and install the IPA
4. Apps expire after 7 days (free Apple ID)

### Method 2: Sideloadly (Free)
1. Download Sideloadly from https://sideloadly.io
2. Connect iPhone to computer
3. Drag and drop IPA to Sideloadly
4. Enter Apple ID credentials

### Method 3: Xcode (Mac only)
1. Open Xcode project in `ios/Runner.xcworkspace`
2. Select your connected device
3. Click Run button

## Customization

### Add Your Own Songs

Edit `lib/models/songs_data.dart`:

```dart
Song(
  id: 13,
  title: "Your Song",
  artist: "Artist Name",
  coverImage: "https://images.unsplash.com/...",
  youtubeId: "YouTubeVideoID",
  duration: "3:45",
)
```

### Modify Glass Effects

Edit `lib/widgets/liquid_glass_components.dart`:

```dart
LiquidGlassSettings(
  thickness: 15,        // Refraction strength
  blur: 8,             // Background blur
  glassColor: Color(0x1AFFFFFF), // Glass tint
  lightIntensity: 1.2,  // Highlight brightness
  outlineIntensity: 0.3, // Edge visibility
)
```

### Change Color Scheme

Update gradient colors in the screens:

```dart
LinearGradient(
  colors: [
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ],
)
```

## Troubleshooting

### Flutter Command Not Found
- Ensure Flutter is in your PATH
- Restart your terminal after installation
- Run `flutter doctor` to diagnose issues

### Pod Install Fails
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Build Fails
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios
```

### YouTube Player Issues
- Check internet connection
- Verify YouTube video IDs are valid
- Some videos may have regional restrictions
- Ensure background audio is enabled in Info.plist

### Performance Issues
- Reduce number of glass components
- Use FakeGlass for non-critical elements
- Monitor with Flutter DevTools
- Test on actual devices

## Performance Tips

1. **Limit Glass Components**: Use glass effects sparingly
2. **Use FakeGlass**: For non-critical UI elements
3. **Minimize Animations**: Moving glass shapes are expensive
4. **Monitor Memory**: Use Flutter DevTools to track usage
5. **Test on Devices**: Simulators don't reflect real performance

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Performance Profiling
```bash
flutter run --profile
```

## Next Steps

Once you have the app running:

1. Test on actual iOS devices
2. Monitor performance metrics
3. Add more songs to the playlist
4. Customize the glass effects
5. Implement additional features

## Support

- Flutter Documentation: https://flutter.dev/docs
- liquid_glass_renderer: https://pub.dev/packages/liquid_glass_renderer
- YouTube Player Flutter: https://pub.dev/packages/youtube_player_flutter
- Flutter Community: https://flutter.dev/community

Enjoy your premium music streaming app with Flutter Liquid Glass! 🎵
