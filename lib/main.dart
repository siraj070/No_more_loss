import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // ✅ Added for location permission init

// ✅ Import new theme files
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'theme/app_decorations.dart';

// Services
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/product_service.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/shop_owner_dashboard.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/my_orders_screen.dart';

/// ✅ Real Firebase config for `shop-cust` project
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "AIzaSyBCg2JMJQcWEKUJ3kBY1ok2PmjQeo-Cf28",
    appId: "1:1003283641297:web:4b0c198595db271d27e6f0",
    messagingSenderId: "1003283641297",
    projectId: "shop-cust",
    authDomain: "shop-cust.firebaseapp.com",
    storageBucket: "shop-cust.appspot.com",
    measurementId: "G-TWMHE5KGG8",
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Ask for location permission once during startup (for web + mobile)
    await _initializeLocationPermissions();

    // ✅ Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    debugPrint("⚠️ Initialization failed: $e");
  }

  runApp(const MyApp());
}

// ✅ Location permission helper
Future<void> _initializeLocationPermissions() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("⚠️ Location services are disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("🚫 Location permissions are permanently denied");
    } else {
      debugPrint("✅ Location permission ready");
    }
  } catch (e) {
    debugPrint("⚠️ Location init error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<CartService>(create: (_) => CartService()),
        ChangeNotifierProvider<ProductService>(create: (_) => ProductService()),
      ],
      child: MaterialApp(
        title: 'No More Loss',
        debugShowCheckedModeBanner: false,

        // 🎨 THEME SETUP (Zepto-style)
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bg,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.text),
            titleTextStyle: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            background: AppColors.bg,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// Loads the correct home screen based on user role from Firestore
  Future<Widget> _getHomeScreen(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = doc.data()?['role'] ?? 'Customer';

      if (role == 'Admin') return const AdminDashboardScreen();
      if (role == 'Shop Owner') return const ShopOwnerDashboard();
      return const ProductListScreen();
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Text(
            'Firestore error: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (authSnap.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Auth Error: ${authSnap.error}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        }

        if (!authSnap.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<Widget>(
          future: _getHomeScreen(authSnap.data!),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (roleSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Error: ${roleSnap.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              );
            }

            return roleSnap.data!;
          },
        );
      },
    );
  }
}

