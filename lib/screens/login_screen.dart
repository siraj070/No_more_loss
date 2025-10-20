import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'product_list_screen.dart';
import 'shop_owner_dashboard.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _selectedRole = 'Customer';

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      User? user;

      if (_isSignUp) {
        user = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': Timestamp.now(),
        });
      } else {
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        user = FirebaseAuth.instance.currentUser;
      }

      // ✅ Check role from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final role = doc['role'] ?? 'Customer';

      // ✅ Redirect based on role
      if (role == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (role == 'Shop Owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShopOwnerDashboard()),
        ); // ✅ Fixed name here
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProductListScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: 20,
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          size: screenHeight * 0.08,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Near Expiry Market',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save Money, Reduce Waste',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Signup Role Selector
                        if (_isSignUp) ...[
                          Text(
                            'I am a:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedRole = 'Customer'),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'Customer'
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedRole == 'Customer'
                                            ? const Color(0xFF10B981)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      'Customer',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: _selectedRole == 'Customer'
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedRole = 'Shop Owner'),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'Shop Owner'
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedRole == 'Shop Owner'
                                            ? const Color(0xFF10B981)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      'Shop Owner',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: _selectedRole == 'Shop Owner'
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(fontSize: 14),
                            prefixIcon: const Icon(Icons.email,
                                color: Color(0xFF10B981), size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF10B981), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password field
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(fontSize: 14),
                            prefixIcon: const Icon(Icons.lock,
                                color: Color(0xFF10B981), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF10B981), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          obscureText: _obscurePassword,
                        ),
                        const SizedBox(height: 20),

                        // Login/Signup Button
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _authenticate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  _isSignUp ? 'Sign Up' : 'Login',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                        const SizedBox(height: 12),

                        // Toggle login/signup
                        TextButton(
                          onPressed: () {
                            setState(() => _isSignUp = !_isSignUp);
                          },
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Login'
                                : 'Don\'t have an account? Sign Up',
                            style: const TextStyle(
                                color: Color(0xFF10B981), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
