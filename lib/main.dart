import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/vpn_service.dart';  // triggers VPN sync on startup

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const ProviderScope(child: StayOffApp()));
}

class StayOffApp extends ConsumerWidget {
  const StayOffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    // Watch themeProvider at ROOT level — changing it rebuilds MaterialApp
    // which propagates Theme.of(context) everywhere in the app
    final themeMode = ref.watch(themeProvider);
    // Sync blocklist to VPN whenever it changes
    ref.watch(vpnInitProvider);

    return MaterialApp.router(
      title: 'StayOff',
      debugShowCheckedModeBanner: false,
      theme: FGTheme.light,
      darkTheme: FGTheme.dark,
      themeMode: themeMode,   // ← this controls the whole app
      routerConfig: router,
    );
  }
}