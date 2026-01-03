import 'package:audit2fund/core/theme/app_theme.dart';
import 'package:audit2fund/presentation/screens/dashboard_screen.dart';
import 'package:audit2fund/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audit2Fund',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: const RootWidget(),
    );
  }
}

class RootWidget extends StatefulWidget {
  const RootWidget({super.key});

  @override
  State<RootWidget> createState() => _RootWidgetState();
}

class _RootWidgetState extends State<RootWidget> {
  bool? _completed;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.clear(); // Removed debug clear, new bundle ID handles fresh state
    setState(() {
      _completed = prefs.getBool('onboarding_completed') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_completed == true) {
      return const DashboardScreen();
    }

    return const OnboardingScreen();
  }
}
