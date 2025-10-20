import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'services/cart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBCg2JMJQcWEKUJ3kBY1ok2PmjQeo-Cf28",
        authDomain: "shop-cust.firebaseapp.com",
        projectId: "shop-cust",
        storageBucket: "shop-cust.firebasestorage.app",
        messagingSenderId: "1003283641297",
        appId: "1:1003283641297:web:4b0c198595db271d27e6f0",
        measurementId: "G-TWMHE5KGG8",
      ),
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartService(),
      child: MaterialApp(
        title: 'Near Expiry Marketplace',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          textTheme: GoogleFonts.poppinsTextTheme(),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoginScreen(),
      ),
    );
  }
}
