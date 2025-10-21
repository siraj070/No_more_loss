import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/product_service.dart';
import 'screens/login_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/shop_owner_dashboard.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/my_orders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBCg2JMJQcWEKUJ3kBY1ok2PmjQeo-Cf28",
      authDomain: "shop-cust.firebaseapp.com",
      projectId: "shop-cust",
      storageBucket: "shop-cust.appspot.com",
      messagingSenderId: "1003283641297",
      appId: "1:1003283641297:web:00b498906c8adb5f27e6f0",
      measurementId: "G-VHVXN7WQQD",
    ),
  );
  runApp(const MyApp());
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
        theme: ThemeData(
          primarySwatch: Colors.green,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
                  child: CircularProgressIndicator(
            color: Colors.green,
          )));
        }
        if (authSnap.hasError) {
          return Scaffold(
            body: Center(
                child: Text('Auth Error: ${authSnap.error}',
                    style: TextStyle(color: Colors.red[700]))),
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
                      child: CircularProgressIndicator(
                color: Colors.green,
              )));
            }
            if (roleSnap.hasError) {
              return Scaffold(
                  body: Center(
                      child: Text('Error: ${roleSnap.error}',
                          style: TextStyle(color: Colors.red[700]))));
            }
            return roleSnap.data!;
          },
        );
      },
    );
  }
}
