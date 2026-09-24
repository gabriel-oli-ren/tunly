import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../music/data/music_providers.dart';
import '../../music/data/music_region.dart';

Future<void> showMusicRegionSettings(BuildContext context) =>
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => const _MusicRegionSheet(),
    );

class _MusicRegionSheet extends ConsumerStatefulWidget {
  const _MusicRegionSheet();

  @override
  ConsumerState<_MusicRegionSheet> createState() => _MusicRegionSheetState();
}

class _MusicRegionSheetState extends ConsumerState<_MusicRegionSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _useLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(musicRegionServiceProvider).useDeviceLocation();
      ref.invalidate(musicRegionProvider);
      ref.invalidate(homeFeedProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectCountry(MusicRegion region) async {
    await ref.read(musicRegionServiceProvider).setCountry(region);
    ref.invalidate(musicRegionProvider);
    ref.invalidate(homeFeedProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(musicRegionProvider);
    final height = math.min(MediaQuery.sizeOf(context).height * .76, 620.0);
    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x55FFFFFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 2),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Music in your region',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(CupertinoIcons.xmark_circle_fill),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  'Use your country to find songs appearing in YouTube trends there. Tunly stores your country only; coordinates are used once to identify it. Country lookup by OpenStreetMap.',
                  style: TextStyle(
                    color: TunlyTheme.secondaryText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoButton.filled(
                  onPressed: _busy ? null : _useLocation,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: _busy
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : Text(
                              current.usesDeviceLocation
                                  ? 'Refresh my location'
                                  : 'Use my location',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 13,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 5),
                child: Text(
                  'COUNTRY · ${current.countryName.toUpperCase()}',
                  style: const TextStyle(
                    color: TunlyTheme.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: musicCountries.length,
                  itemBuilder: (context, index) {
                    final country = musicCountries[index];
                    final selected = country.countryCode == current.countryCode;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 9,
                      ),
                      onPressed: () => _selectCountry(country),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              country.countryName,
                              style: TextStyle(
                                color: selected
                                    ? TunlyTheme.accent
                                    : CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              CupertinoIcons.checkmark,
                              color: TunlyTheme.accent,
                              size: 18,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
