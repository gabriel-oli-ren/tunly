# Tunely - Premium Music Streaming App (Flutter)

A beautiful, premium music streaming application built with Flutter and the liquid_glass_renderer package for iOS, featuring YouTube audio integration and stunning glassmorphism effects.

## Features

- **Flutter Liquid Glass UI**: Native iOS glassmorphism effects using liquid_glass_renderer
- **Premium Dark Mode UI**: Pure black (#000000) background optimized for OLED screens
- **Gradient Accents**: Electric purple to neon pink gradients for active elements
- **YouTube Audio Streaming**: Hidden YouTube player integration for music playback
- **Impeller Rendering**: Native iOS GPU rendering for smooth performance
- **Featured Albums Carousel**: Horizontal scrolling album showcase
- **Most Played & New Releases**: Curated song lists
- **Now Playing Screen**: Full-screen with playback controls
- **Glassmorphism Effects**: Beautiful blur and refraction effects
- **GitHub Actions CI/CD**: Automated iOS IPA building

## Prerequisites

- Flutter SDK (3.16.0 or higher)
- Xcode (for iOS development)
- CocoaPods
- iOS 13.0 or higher

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd tunely_flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Install iOS dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
tunely_flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── song.dart            # Song model
│   │   └── songs_data.dart      # Song data with YouTube IDs
│   ├── providers/
│   │   └── music_provider.dart  # State management
│   ├── screens/
│   │   ├── home_screen.dart     # Home screen
│   │   └── now_playing_screen.dart # Now playing screen
│   └── widgets/
│       └── liquid_glass_components.dart # Glass UI components
├── ios/                         # iOS-specific files
├── pubspec.yaml                 # Dependencies
└── .github/workflows/           # CI/CD
```

## Key Technologies

- **Flutter**: Cross-platform framework
- **liquid_glass_renderer**: Glassmorphism effects
- **youtube_player_flutter**: YouTube integration
- **Provider**: State management
- **Impeller**: Native iOS rendering

## Liquid Glass Components

The app includes custom liquid glass components:

- **LiquidGlassButton**: Glass-style buttons
- **LiquidGlassCard**: Glass-effect cards
- **LiquidGlassSlider**: Custom progress slider
- **LiquidGlassListItem**: List items with glass effects
- **LiquidGlassTabBar**: Glass-style tab bar

## Data Architecture

The app uses local static data (`songs_data.dart`) containing:
- 12+ real songs with metadata
- High-quality Unsplash cover images
- YouTube video IDs for audio streaming
- Featured albums for the carousel

## Performance Considerations

Since liquid_glass_renderer is experimental:

- Test thoroughly on target devices
- Monitor performance metrics (memory, frame rates)
- Use FakeGlass for non-critical UI elements
- Limit animations to essential interactions
- Works only on Impeller (iOS only for now)

## GitHub Actions CI/CD

The project includes automated iOS IPA building via GitHub Actions.

### Required Setup

No secrets are required for basic builds. The workflow uses `--no-codesign` for development builds.

### Build Profiles

- **debug**: Development builds
- **profile**: Performance testing
- **release**: Production builds

### Manual Builds

You can trigger builds manually from the Actions tab by choosing the build type.

## Customization

### Adding Songs

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

### Glass Effect Settings

Modify glass settings in `lib/widgets/liquid_glass_components.dart`:

```dart
LiquidGlassSettings(
  thickness: 15,
  blur: 8,
  glassColor: Color(0x1AFFFFFF),
  lightIntensity: 1.2,
)
```

## Building for iOS

### Development Build
```bash
flutter build ios --debug --no-codesign
```

### Release Build
```bash
flutter build ios --release
```

### Creating IPA
```bash
flutter build ios --release
cd build/ios/iphoneos
zip -r tunely-ios.ipa Runner.app
```

## Troubleshooting

### Dependencies Issues
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### Build Issues
- Ensure Xcode command line tools are installed
- Verify iOS deployment target is set to 13.0
- Check that Impeller is enabled in your Flutter build

### YouTube Playback
- Ensure stable internet connection
- Some videos may have regional restrictions
- Hidden player works best with music videos

## Known Limitations

- iOS only (Impeller requirement)
- Experimental package - use with caution
- Performance may vary on older devices
- Maximum 16 blended shapes per group
- Blur introduces artifacts when blending

## Future Enhancements

- Android support (when Impeller is available)
- Search functionality
- Favorites/playlist system
- Background audio service
- Lyrics display
- Social sharing features

## License

This project is for educational purposes.

## Credits

- [liquid_glass_renderer](https://pub.dev/packages/liquid_glass_renderer) - Glassmorphism effects
- [youtube_player_flutter](https://pub.dev/packages/youtube_player_flutter) - YouTube integration
- [Flutter](https://flutter.dev) - Cross-platform framework
