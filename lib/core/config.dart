/// Public service endpoints live here so providers can be swapped centrally.
abstract final class TunlyConfig {
  static const itunesSearchBase = 'https://itunes.apple.com/search';
  static const itunesLookupBase = 'https://itunes.apple.com/lookup';
  static const deezerApiBase = 'https://api.deezer.com';
  static const musicBrainzApiBase = 'https://musicbrainz.org/ws/2';
  static const lrclibApiBase = 'https://lrclib.net/api';
  static const reverseGeocodeBase =
      'https://nominatim.openstreetmap.org/reverse';

  /// Public Invidious instances provide a key-free YouTube video search API.
  /// Instances are community operated, so the resolver falls through the list.
  static const invidiousInstances = <String>[
    'https://inv.nadeko.net',
    'https://invidious.nerdvpn.de',
    'https://yt.chocolatemoo53.com',
    'https://invidious.tiekoetter.com',
  ];

  /// Public Piped instances; availability and policies vary over time.
  static const pipedInstances = <String>[
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.leptons.xyz',
    'https://pipedapi.syncpundit.io',
    'https://api-piped.mha.fi',
    'https://pipedapi.tokhmi.xyz',
  ];
}
