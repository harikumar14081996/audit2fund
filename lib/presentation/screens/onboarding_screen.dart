import 'package:audit2fund/presentation/screens/dashboard_screen.dart';
import 'package:audit2fund/presentation/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    // Request Notification Permission using native service
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.requestPermissions();

    // Save completion flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 80,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Audit2Fund',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'To help you track loan files efficiently, we need permission to send notifications for follow-ups.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _completeOnboarding,
                  icon: const Icon(Icons.check),
                  label: const Text('Grant Permissions & Start'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
