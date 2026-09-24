import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import '../../library/data/library_providers.dart';
import '../../library/data/local_library.dart';

class MusicRegion {
  const MusicRegion({
    required this.countryCode,
    required this.countryName,
    this.usesDeviceLocation = false,
  });

  final String countryCode;
  final String countryName;
  final bool usesDeviceLocation;

  static const initial = MusicRegion(
    countryCode: 'US',
    countryName: 'United States',
  );
}

const musicCountries = <MusicRegion>[
  MusicRegion(countryCode: 'ES', countryName: 'Spain'),
  MusicRegion(countryCode: 'US', countryName: 'United States'),
  MusicRegion(countryCode: 'GB', countryName: 'United Kingdom'),
  MusicRegion(countryCode: 'MX', countryName: 'Mexico'),
  MusicRegion(countryCode: 'BR', countryName: 'Brazil'),
  MusicRegion(countryCode: 'CA', countryName: 'Canada'),
  MusicRegion(countryCode: 'FR', countryName: 'France'),
  MusicRegion(countryCode: 'DE', countryName: 'Germany'),
  MusicRegion(countryCode: 'IT', countryName: 'Italy'),
  MusicRegion(countryCode: 'JP', countryName: 'Japan'),
  MusicRegion(countryCode: 'IN', countryName: 'India'),
  MusicRegion(countryCode: 'KR', countryName: 'South Korea'),
  MusicRegion(countryCode: 'AU', countryName: 'Australia'),
];

final musicRegionProvider = Provider<MusicRegion>((ref) {
  final library = ref.watch(localLibraryProvider);
  final code = library.setting('music_region') ?? 'US';
  final savedName = library.setting('music_region_name');
  final usesLocation = library.setting('uses_location') == 'true';
  final country = musicCountries.firstWhere(
    (item) => item.countryCode == code,
    orElse: () => MusicRegion(countryCode: code, countryName: code),
  );
  return MusicRegion(
    countryCode: country.countryCode,
    countryName: savedName ?? country.countryName,
    usesDeviceLocation: usesLocation,
  );
});

final musicRegionServiceProvider = Provider<MusicRegionService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return MusicRegionService(client, ref.watch(localLibraryProvider));
});

class MusicRegionService {
  MusicRegionService(this._client, this._library);
  final http.Client _client;
  final LocalLibrary _library;

  Future<MusicRegion> useDeviceLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on location services and try again.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Location permission was not granted.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location is blocked for Tunly. Allow it in your browser settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 20),
      ),
    );
    final uri = Uri.parse(TunlyConfig.reverseGeocodeBase).replace(
      queryParameters: {
        'lat': '${position.latitude}',
        'lon': '${position.longitude}',
        'format': 'jsonv2',
        'zoom': '3',
        'addressdetails': '1',
      },
    );
    final response = await _client
        .get(uri, headers: const {'accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Could not identify your country. Please choose it.');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final address = body is Map<String, dynamic> ? body['address'] : null;
    final code = address is Map<String, dynamic>
        ? address['country_code']?.toString().toUpperCase()
        : null;
    final name = address is Map<String, dynamic>
        ? address['country']?.toString()
        : null;
    if (code == null || code.length != 2 || name == null || name.isEmpty) {
      throw StateError('Could not identify your country. Please choose it.');
    }

    await _library.setSetting('music_region', code);
    await _library.setSetting('music_region_name', name);
    await _library.setSetting('uses_location', 'true');
    return MusicRegion(
      countryCode: code,
      countryName: name,
      usesDeviceLocation: true,
    );
  }

  Future<MusicRegion> setCountry(MusicRegion region) async {
    await _library.setSetting('music_region', region.countryCode);
    await _library.setSetting('music_region_name', region.countryName);
    await _library.setSetting('uses_location', 'false');
    return region;
  }
}
