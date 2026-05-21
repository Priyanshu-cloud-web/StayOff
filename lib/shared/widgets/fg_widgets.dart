import 'package:flutter/material.dart';
import 'package:focusguard/core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// FGCard
// ─────────────────────────────────────────────
class FGCard extends StatelessWidget {
  const FGCard({
    super.key,
    required this.child,
    this.padding = FGPad.card,
    this.borderRadius = FGRadius.lg,
    this.color = FGColors.bg3,
    this.borderColor = FGColors.border,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: padding,
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: box);
    return box;
  }
}

// ─────────────────────────────────────────────
// FGBadge
// ─────────────────────────────────────────────
enum FGBadgeStyle { purple, teal, red, amber, gray }

class FGBadge extends StatelessWidget {
  const FGBadge(this.label, {super.key, this.style = FGBadgeStyle.gray});
  final String label;
  final FGBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    switch (style) {
      case FGBadgeStyle.purple:
        bg = const Color(0x267C6FED);
        fg = FGColors.purpleLight;
        border = const Color(0x407C6FED);
        break;
      case FGBadgeStyle.teal:
        bg = const Color(0x2600C9A7);
        fg = const Color(0xFF4DFFE0);
        border = const Color(0x4000C9A7);
        break;
      case FGBadgeStyle.red:
        bg = const Color(0x26FF6B6B);
        fg = const Color(0xFFFF8E8E);
        border = const Color(0x40FF6B6B);
        break;
      case FGBadgeStyle.amber:
        bg = const Color(0x26FFB347);
        fg = FGColors.amber;
        border = const Color(0x40FFB347);
        break;
      case FGBadgeStyle.gray:
      default:
        bg = FGColors.bg4;
        fg = FGColors.textSecond;
        border = FGColors.border2;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: FGRadius.full,
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ─────────────────────────────────────────────
// FGButton
// ─────────────────────────────────────────────
enum FGButtonStyle { primary, outline, danger, teal }

class FGButton extends StatelessWidget {
  const FGButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = FGButtonStyle.primary,
    this.icon,
    this.small = false,
    this.loading = false,
  });
  final String label;
  final VoidCallback onTap;
  final FGButtonStyle style;
  final IconData? icon;
  final bool small;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    switch (style) {
      case FGButtonStyle.primary:
        bg = FGColors.purple; fg = Colors.white; border = Colors.transparent;
        break;
      case FGButtonStyle.outline:
        bg = Colors.transparent; fg = FGColors.textSecond; border = FGColors.border2;
        break;
      case FGButtonStyle.danger:
        bg = const Color(0xFFE84393); fg = Colors.white; border = Colors.transparent;
        break;
      case FGButtonStyle.teal:
        bg = FGColors.teal; fg = Colors.white; border = Colors.transparent;
        break;
    }

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: small ? null : double.infinity,
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
            : const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: FGRadius.md,
          border: Border.all(color: border),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: small ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: 0.3,
                      )),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FGSectionLabel
// ─────────────────────────────────────────────
class FGSectionLabel extends StatelessWidget {
  const FGSectionLabel(this.text, {super.key, this.topPad = 16});
  final String text;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad, bottom: 10),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: FGColors.textThird,
            letterSpacing: 0.12,
          )),
    );
  }
}

// ─────────────────────────────────────────────
// FGToggleRow
// ─────────────────────────────────────────────
class FGToggleRow extends StatelessWidget {
  const FGToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
    this.showBorder = true,
  });

  final String title;
  final String? subtitle;
  final Widget? icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: FGColors.border, width: 1)))
          : null,
      child: Row(children: [
        if (icon != null) ...[icon!, const SizedBox(width: 12)],
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        )),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// FGTopBar
// ─────────────────────────────────────────────
class FGTopBar extends StatelessWidget {
  const FGTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (showBack) ...[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: FGColors.bg3,
                borderRadius: FGRadius.sm,
                border: Border.all(color: FGColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: FGColors.textSecond),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// FGIconBtn
// ─────────────────────────────────────────────
class FGIconBtn extends StatelessWidget {
  const FGIconBtn({super.key, required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: FGColors.bg3,
          borderRadius: FGRadius.sm,
          border: Border.all(color: FGColors.border),
        ),
        child: Icon(icon, size: 18, color: color ?? FGColors.textSecond),
      ),
    );
  }
}