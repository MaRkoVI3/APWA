import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone =
      prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

  runApp(
    ProviderScope(
      child: ApwaisApp(startOnboarding: !onboardingDone),
    ),
  );
}

class ApwaisApp extends StatelessWidget {
  final bool startOnboarding;
  const ApwaisApp({super.key, required this.startOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apwais',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: startOnboarding
          ? const OnboardingScreen()
          : const HomeScreen(),
    );
  }
}