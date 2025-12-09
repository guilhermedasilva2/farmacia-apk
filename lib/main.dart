import 'package:flutter/material.dart';
import 'package:meu_app_inicial/features/app/home/home_page.dart'; 
import 'package:meu_app_inicial/features/onboarding/presentation/screens/onboarding_screen.dart'; 
import 'package:meu_app_inicial/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:meu_app_inicial/features/onboarding/presentation/screens/policy_viewer_screen.dart';
import 'package:meu_app_inicial/features/onboarding/presentation/screens/consent_screen.dart';
import 'package:meu_app_inicial/features/products/presentation/screens/products_screen.dart';
import 'package:meu_app_inicial/features/medication_reminders/presentation/screens/medication_reminder_list_page.dart';
import 'package:meu_app_inicial/features/auth/presentation/screens/auth_screen.dart';
import 'package:meu_app_inicial/features/products/presentation/screens/admin_products_screen.dart';
import 'package:meu_app_inicial/features/orders/presentation/screens/admin_orders_screen.dart';
import 'package:meu_app_inicial/features/categories/presentation/screens/categories_screen.dart';
import 'package:meu_app_inicial/features/orders/presentation/screens/cart_screen.dart';
import 'package:meu_app_inicial/features/products/presentation/screens/product_details_screen.dart';
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
        AppRoutes.orders: (ctx) => const CartScreen(),
        AppRoutes.policy: (ctx) => const PolicyViewerScreen(),
        AppRoutes.consent: (ctx) => const ConsentScreen(),
        AppRoutes.reminders: (ctx) => const MedicationReminderListPage(),
        AppRoutes.auth: (ctx) => const AuthScreen(),
        AppRoutes.adminProducts: (ctx) => const AdminProductsScreen(),
        AppRoutes.adminOrders: (ctx) => const AdminOrdersScreen(),
        AppRoutes.adminCategories: (ctx) => const CategoriesScreen(),
        AppRoutes.productDetails: (ctx) => const ProductDetailsScreen(),
      },
    );
  }
}
