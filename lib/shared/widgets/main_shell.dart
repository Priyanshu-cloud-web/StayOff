import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:focusguard/core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _Tab(icon: Icons.home_rounded,       label: 'Home',   route: '/dashboard'),
    _Tab(icon: Icons.block_rounded,      label: 'Block',  route: '/blocklist'),
    _Tab(icon: Icons.shield_rounded,     label: 'Guard',  route: '/safeguard'),
    _Tab(icon: Icons.lock_clock_rounded, label: 'Lock', route: '/lock'),
    _Tab(icon: Icons.settings_rounded,   label: 'More',   route: '/settings'),
  ];

  int _idx(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idx = _idx(context);
    final bg2 = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final bdr = isDark ? FGColors.border : FGColorsLight.border;
    final active = isDark ? FGColors.purpleLight : FGColorsLight.purpleLight;
    final inactive = isDark ? FGColors.textThird : FGColorsLight.textThird;

    return Scaffold(
      backgroundColor: isDark ? FGColors.bg : FGColorsLight.bg,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg2,
          border: Border(top: BorderSide(color: bdr, width: 1))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final isActive = i == idx;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go(_tabs[i].route),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? active.withOpacity(0.12) : Colors.transparent,
                            borderRadius: FGRadius.full),
                          child: Icon(_tabs[i].icon, size: 20,
                            color: isActive ? active : inactive)),
                        const SizedBox(height: 3),
                        Text(_tabs[i].label,
                          style: TextStyle(fontFamily: 'DM Sans', fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? active : inactive)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.icon, required this.label, required this.route});
  final IconData icon; final String label, route;
}