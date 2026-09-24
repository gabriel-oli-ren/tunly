import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../../app/theme.dart';

bool get usesNativeCupertino =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

class TunlySegmentedControl extends StatelessWidget {
  const TunlySegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (usesNativeCupertino) {
      return CNSegmentedControl(
        labels: labels,
        selectedIndex: selectedIndex,
        onValueChanged: onChanged,
        color: TunlyTheme.accent,
        height: 38,
      );
    }
    return CupertinoSlidingSegmentedControl<int>(
      groupValue: selectedIndex,
      backgroundColor: TunlyTheme.surface,
      thumbColor: TunlyTheme.accent,
      children: {
        for (var index = 0; index < labels.length; index++)
          index: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Text(labels[index], style: const TextStyle(fontSize: 12)),
          ),
      },
      onValueChanged: (index) {
        if (index != null) onChanged(index);
      },
    );
  }
}

class TunlyAddButton extends StatelessWidget {
  const TunlyAddButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (usesNativeCupertino) {
      return CNButton.icon(
        icon: const CNSymbol('plus', size: 20),
        onPressed: onPressed,
        tint: TunlyTheme.accent,
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: const Icon(CupertinoIcons.add),
    );
  }
}
