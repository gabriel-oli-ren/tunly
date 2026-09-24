# Tunly

Tunly is a cross-platform music discovery app built with Flutter. The web target is designed to install from iPhone Safari as a standalone PWA. Metadata and album artwork come from Apple's public iTunes Search API. Playback uses the official YouTube embedded player, video results are matched through Piped's public search API, lyrics come from LRCLIB, and likes, searches, listening history and playlists stay in local Hive storage.

## Requirements

- Flutter stable with Dart 3.9 or newer
- Windows 10/11 with Chrome for local web development
- Git (optional, for deployment)

## Run on Windows

```powershell
flutter doctor
flutter pub get
flutter run -d chrome
```

Create a production web build with:

```powershell
flutter build web --release
```

The deployable site is written to `build/web`. Keep the hosting base path in mind: for a project site hosted below a repository path, build with `--base-href /repository-name/`.

The iOS-style Flutter app also runs in Chrome for day-to-day development. Native iOS controls use `cupertino_native`; its library filter, add button, and tab bar fall back to Flutter Cupertino controls in the PWA. Its current iOS plugin uses CocoaPods, so the Codemagic workflow keeps Flutter's Swift Package Manager migration disabled for this project. A native iOS build must run on macOS with Xcode, which Codemagic provides as a hosted build machine.

The YouTube player remains visible with its built-in controls in Now Playing. YouTube can show its own ads, playback stops when Now Playing closes, and background or audio-only playback is not provided. These are constraints of the embedded player and its terms, so Tunly is a music discovery/player MVP rather than an ad-free background streaming service.

## Test on iPhone

### Quick Safari check on your local network

1. Connect the iPhone and Windows PC to the same Wi-Fi network.
2. In PowerShell, run `ipconfig` and note the PC's IPv4 address for that Wi-Fi connection (for example, `192.168.1.24`).
3. From the project folder, start Flutter's web server:

   ```powershell
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```

4. Open `http://<PC-IPv4-address>:8080` in iPhone Safari, replacing the example with your PC's address. Allow Flutter through Windows Firewall if it asks.

This checks layout and touch behavior. It does not install the app or fully reproduce iOS PWA behavior.

### Install it as a Home Screen PWA

1. Build and deploy the web app to an HTTPS host using one of the options below.
2. Open the deployed HTTPS URL in Safari on the iPhone.
3. Tap **Share → Add to Home Screen → Add**, then launch Tunly from its Home Screen icon.
4. Tap a song and then Play in the visible YouTube player; iOS requires that user gesture to begin audio.

HTTPS is required for a real installable PWA. iOS may suspend background audio depending on the iOS version and Safari lifecycle. The web manifest requests standalone display and the page includes iOS status bar, app title, and safe-area viewport settings.

## Deploy the PWA

### Netlify

Create a site from this repository. Set the build command to `flutter build web --release` and publish directory to `build/web`. Use a Flutter-enabled build image or install Flutter in the build command.

### Cloudflare Pages

Connect the repository, build with `flutter build web --release`, and set the output directory to `build/web`. Configure the build environment to install Flutter stable first.

### GitHub Pages

Build with `flutter build web --release --base-href /<repository-name>/`, then publish `build/web` using the GitHub Pages deploy action or `gh-pages` branch. For a user or organization site at the domain root, use `--base-href /`.

## Build and sideload a native iPhone IPA from Windows

Windows cannot compile an iOS app: Xcode only runs on macOS. The included Codemagic workflow uses a hosted Mac to create an **unsigned** `Tunly.ipa`; AltServer signs it with your free Apple ID for personal testing. A paid developer account is not needed for this route, but free signing expires after seven days.

1. Put this project in a GitHub repository and push the project files. In Codemagic, sign in with GitHub, add the repository, and choose the `ios-release` workflow from `codemagic.yaml`. Start a build on the Mac runner.
2. When the build finishes, download the `Tunly.ipa` artifact from that build. The IPA is intentionally unsigned, so it cannot be installed by tapping it or by using iTunes alone.
3. On Windows, install iTunes and iCloud **from Apple's website**, not the Microsoft Store. Install AltServer for Windows and keep it running in the notification area.
4. Connect the iPhone over USB, unlock it, tap **Trust This Computer**, and enable Wi-Fi sync for the device in iTunes if you want later refreshes over Wi-Fi. Keep the iPhone and PC on the same Wi-Fi network.
5. From the AltServer notification-area icon, choose **Install AltStore** for your iPhone and enter your Apple ID when prompted. On the iPhone, trust the developer profile under **Settings → General → VPN & Device Management**. On iOS 16 or newer, turn on **Settings → Privacy & Security → Developer Mode** and restart if prompted.
6. To install Tunly, hold **Shift** while clicking the AltServer icon, choose **Sideload .ipa…**, select the downloaded `Tunly.ipa`, and enter the Apple ID used for signing. Keep AltServer installed and running so AltStore can refresh the app before its seven-day signature expires.
7. Open Tunly on the iPhone and test search, artwork, and playback. Tap a song and then tap Play in the visible YouTube player; iOS requires that user gesture.

AltStore Classic allows up to three active sideloaded apps under a free Apple ID. The app needs periodic refresh/re-signing, normally every seven days. See the [AltStore Windows setup guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) and [IPA sideload guide](https://faq.altstore.io/altstore-classic/sideloading-apps).

If you only want to test the iPhone layout first, use the PWA instructions above instead: deploy the web build to HTTPS, open it in Safari, then choose **Share → Add to Home Screen**. That avoids the Mac build step and sideloading entirely.

`codemagic.yaml` generates an iOS runner on the hosted Mac and packages the unsigned IPA. A signed App Store/TestFlight build requires Apple signing credentials. For local native builds and the iOS simulator, you still need macOS and Xcode.

## Project layout

```text
lib/
  app/                 app configuration, routes, and theme
  core/                shared configuration and domain foundations
  features/
    home/              home experience
    library/           local music library
    search/             discovery and browse
    music/              catalog models and iTunes adapter
    lyrics/             LRCLIB lookup and synced lyrics view
    player/             embedded YouTube playback and video resolver
    shell/              tab navigation shell
web/                   PWA entry page, manifest, and app icon
```

## Music services

Public metadata and lyrics endpoints are centralized in `lib/core/config.dart`. The music source abstraction isolates catalog metadata from providers. Playback directly uses `youtube_player_iframe` so Tunly can coordinate queue changes, resolution fallback, video state and synced lyrics with the official embedded player. `youtube_player_flutter` is a higher-level wrapper over that same IFrame API; the direct controller is a better fit for these custom controls. Public third-party services can change availability and may impose their own usage policies. YouTube embeds may show YouTube ads; Tunly does not hide or strip them.
