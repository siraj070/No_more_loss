import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "AIzaSyBCg2JMJQcWEKUJ3kBY1ok2PmjQeo-Cf28",
    appId: "1:1003283641297:web:4b0c198595db271d27e6f0",
    messagingSenderId: "1003283641297",
    projectId: "shop-cust",
    authDomain: "shop-cust.firebaseapp.com",
    storageBucket: "shop-cust.appspot.com", // ✅ fixed domain
    measurementId: "G-TWMHE5KGG8",
  );
}
