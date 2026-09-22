# Tunly 🎵

A Spotify/Apple Music-style music player built with Flutter, targeting native iOS. Features song search via iTunes Search API, YouTube-backed playback, and synced lyrics display.

## Features

- **Song Search**: Search for songs and artists using the iTunes Search API
- **YouTube Playback**: Play audio via YouTube IFrame Player embedded in a WebView
- **Synced Lyrics**: Display LRC-format lyrics synced to playback progress
- **Beautiful UI**: Dark theme with glassmorphism effects
- **Mini Player**: Persistent bottom player with quick controls
- **Full-Screen Player**: Immersive now playing view with large artwork and lyrics

## Tech Stack

- **Framework**: Flutter (stable channel)
- **State Management**: Provider
- **Network**: HTTP package for API calls
- **Video Playback**: webview_flutter for YouTube IFrame Player
- **Target Platform**: iOS (native)
- **Build Pipeline**: GitHub Actions with macOS runner

## APIs Used

- **iTunes Search API**: Free, no API key required
- **lrclib.net**: Free lyrics API, no API key required
- **YouTube**: Embedded via IFrame Player API

## Local Development Setup

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK (included with Flutter)
- Git
- For iOS builds: Access to GitHub Actions (no Mac required locally)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd tunly
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```

### Running the App

#### Web (for quick testing)
```bash
flutter run -d chrome
# or
flutter run -d edge
```

#### Local Development
```bash
flutter run
```

### Building Locally

#### Web Build
```bash
flutter build web --release
```
Output: `build/web/`

#### iOS Build (no codesign)
```bash
flutter build ios --release --no-codesign
```
Note: This will compile the Dart code and check for errors but won't produce a signed .ipa on non-Mac systems. The actual iOS build happens in CI.

## CI/CD Pipeline

### GitHub Actions Workflows

#### iOS Build Workflow
- **Trigger**: Push to main/develop branches, pull requests, or manual dispatch
- **Runner**: macOS-latest
- **Steps**:
  1. Checkout repository
  2. Setup Flutter (stable channel)
  3. Install dependencies
  4. Build iOS with `--no-codesign` flag
  5. Export unsigned .ipa artifact
  6. Upload artifact for download (retained for 30 days)
  7. Build iOS simulator version for testing

#### Web Build Workflow
- **Trigger**: Push to main/develop branches, pull requests, or manual dispatch
- **Runner**: ubuntu-latest
- **Steps**:
  1. Checkout repository
  2. Setup Flutter
  3. Install dependencies
  4. Build web release
  5. Upload web artifact (retained for 7 days)

### Triggering the CI Pipeline

1. **Automatic**: Push to main or develop branch
2. **Manual**: Go to Actions tab in GitHub, select "Build iOS App" or "Build Web App", click "Run workflow"

### Downloading Build Artifacts

1. Go to the Actions tab in your GitHub repository
2. Select the workflow run you want
3. Scroll down to "Artifacts" section
4. Download the desired artifact:
   - `tunly-ios-unsigned`: Unsigned .ipa for sideloading
   - `tunly-ios-simulator`: Simulator build for testing
   - `tunly-web`: Web build for browser testing

## Installing on iPhone

### Important Notes

- **Free Apple ID**: No paid Developer Program membership required
- **7-Day Expiry**: Apps signed with free Apple ID expire after 7 days
- **Weekly Re-signing**: You must re-sign the app weekly
- **Device Limitation**: Manual device registration may be required

### Installation Methods

#### Method 1: AltStore (Recommended for iOS)

1. **Install AltStore** on your iPhone (requires computer for initial setup)
2. **Download the unsigned .ipa** from GitHub Actions artifacts
3. **Open AltStore** and tap the "+" button
4. **Select the .ipa file** and enter your Apple ID credentials
5. **Wait for installation** to complete

#### Method 2: Sideloadly (Windows/Mac)

1. **Download Sideloadly** for your platform
2. **Connect your iPhone** via USB
3. **Enter your Apple ID** and app-specific password
4. **Drag and drop the .ipa** onto Sideloadly
5. **Wait for installation** to complete

#### Method 3: Xcode (Mac only)

If you have access to a Mac:
1. Open the project in Xcode: `open ios/Runner.xcworkspace`
2. Select your personal team (Apple ID)
3. Connect your iPhone
4. Click "Run" to build and install

### Trusting the Developer Certificate

After installation:
1. Go to **Settings > General > VPN & Device Management**
2. Find your Apple ID in the developer list
3. Tap **"Trust [Your Name]"**
4. Confirm by tapping **"Trust"**

### Re-signing the App

Since free Apple ID signing expires after 7 days:

- **AltStore**: Automatically refreshes when connected to same Wi-Fi as your computer
- **Sideloadly**: Re-run the app with your device connected
- **Set a reminder** to re-sign before expiration

For detailed instructions, see [docs/ios-signing-guide.md](docs/ios-signing-guide.md).

## Project Structure

```
tunly/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── song.dart            # Song data model
│   │   └── lyrics.dart          # Lyrics data model
│   ├── providers/
│   │   └── music_provider.dart  # State management
│   ├── screens/
│   │   ├── home_screen.dart    # Main search screen
│   │   └── now_playing_screen.dart # Full-screen player
│   ├── services/
│   │   ├── itunes_service.dart  # iTunes Search API
│   │   ├── lyrics_service.dart  # lrclib.net API
│   │   └── youtube_service.dart # YouTube search
│   └── widgets/
│       ├── search_bar.dart      # Search input widget
│       ├── song_list.dart       # Search results list
│       ├── mini_player.dart     # Bottom mini player
│       ├── youtube_player_widget.dart # YouTube WebView
│       └── lyrics_widget.dart   # Lyrics display
├── ios/                         # iOS-specific files
├── web/                         # Web-specific files
├── .github/workflows/           # CI/CD configurations
└── docs/                        # Documentation
```

## Development Notes

### State Management

The app uses Provider for state management. The main state is managed in `MusicProvider` which handles:
- Search results
- Current playing song
- Playback state
- Queue management
- Lyrics loading

### API Integration

- **iTunes Search**: Returns song metadata with artwork URLs
- **YouTube Search**: Simple HTML parsing to find video IDs (consider YouTube Data API for production)
- **Lyrics**: lrclib.net provides both synced (LRC) and plain lyrics

### WebView Integration

The YouTube player is embedded using webview_flutter with JavaScript bridge for:
- Play/pause control
- Seeking
- Volume control
- Current time tracking for lyrics sync

## Troubleshooting

### Flutter Doctor Issues

- Ensure Flutter SDK is in your PATH
- Run `flutter doctor` to diagnose issues
- For iOS development on Windows/Linux, use GitHub Actions for builds

### Build Errors

- Check that all dependencies are installed: `flutter pub get`
- Verify Flutter version: `flutter --version`
- Clean build: `flutter clean`

### Installation Issues

- Make sure your device is trusted in Settings
- Check that you have enough storage space
- Verify your Apple ID credentials
- Try reinstalling the app

### 7-Day Expiry

- This is a limitation of free Apple ID signing
- Set up automatic re-signing with AltStore
- Or manually re-sign weekly with Sideloadly

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational purposes. Please respect the terms of service of the APIs used (iTunes, YouTube, lrclib.net).

## Acknowledgments

- iTunes Search API for song metadata
- lrclib.net for lyrics
- YouTube IFrame Player API for audio playback
- Flutter team for the amazing framework

## Future Enhancements (Out of Scope for Now)

- User accounts and playlists
- Favorites persistence
- Android build
- Paid Apple Developer Program integration
- TestFlight distribution
- Offline playback
- YouTube Data API integration for more reliable video search