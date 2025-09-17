// lib/main.dart
import 'package:flutter/material.dart';
import 'package:meu_app_inicial/screens/home_screen.dart'; 
import 'package:meu_app_inicial/screens/onboarding_screen.dart'; 
import 'package:meu_app_inicial/screens/splash_screen.dart';
import 'package:meu_app_inicial/utils/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmaFox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal, 
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.SPLASH,
      routes: {
        AppRoutes.SPLASH: (ctx) => const SplashScreen(),
        AppRoutes.ONBOARDING: (ctx) => const OnboardingScreen(),
        AppRoutes.HOME: (ctx) => const HomeScreen(),
      },
    );
  }
}