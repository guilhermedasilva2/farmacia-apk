import 'package:flutter/material.dart';
import 'package:meu_app_inicial/screens/home_screen.dart'; 
import 'package:meu_app_inicial/screens/onboarding_screen.dart'; 
import 'package:meu_app_inicial/screens/splash_screen.dart';
import 'package:meu_app_inicial/screens/policy_viewer_screen.dart';
import 'package:meu_app_inicial/screens/consent_screen.dart';
import 'package:meu_app_inicial/screens/products_screen.dart';
import 'package:meu_app_inicial/utils/app_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null && supabaseAnonKey != null &&
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
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
        AppRoutes.products: (ctx) => const ProductsScreen(),
        AppRoutes.policy: (ctx) => const PolicyViewerScreen(),
        AppRoutes.consent: (ctx) => const ConsentScreen(),
      },
    );
  }
}