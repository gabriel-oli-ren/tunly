import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final Color? glowColor;
  final double? width;
  final double? height;

  const LiquidGlassButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.borderRadius = 16.0,
    this.glowColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: LiquidGlass.withOwnLayer(
        settings: const LiquidGlassSettings(
          thickness: 15,
          blur: 8,
          glassColor: Color(0x1AFFFFFF),
          lightIntensity: 1.2,
          outlineIntensity: 0.3,
        ),
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double thickness;
  final Color? glassColor;
  final double? width;
  final double? height;

  const LiquidGlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 20.0,
    this.blur = 10,
    this.thickness = 20,
    this.glassColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: LiquidGlass.withOwnLayer(
        settings: LiquidGlassSettings(
          thickness: thickness,
          blur: blur,
          glassColor: glassColor ?? const Color(0x1AFFFFFF),
          lightIntensity: 1.0,
          outlineIntensity: 0.4,
        ),
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}

class LiquidGlassSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const LiquidGlassSlider({
    Key? key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: inactiveColor ?? Colors.white.withOpacity(0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: FractionallySizedBox(
          widthFactor: value,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeColor ?? const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGlassListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LiquidGlassListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      settings: const LiquidGlassSettings(
        thickness: 12,
        blur: 8,
        glassColor: Color(0x1AFFFFFF),
        lightIntensity: 1.0,
        outlineIntensity: 0.4,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class LiquidGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IconData> icons;
  final List<String> labels;

  const LiquidGlassTabBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        thickness: 15,
        blur: 20,
        glassColor: Color(0x1AFFFFFF),
        lightIntensity: 1.0,
        outlineIntensity: 0.4,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 0),
      child: Container(
        height: 85,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isActive = index == currentIndex;
            return GestureDetector(
              onTap: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[index],
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
