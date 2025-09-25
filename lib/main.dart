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
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (ctx) => const SplashScreen(),
        AppRoutes.onboarding: (ctx) => const OnboardingScreen(),
        AppRoutes.home: (ctx) => const HomeScreen(),
      },
    );
  }
}