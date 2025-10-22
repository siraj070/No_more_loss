import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'add_product_screen.dart';
import 'shop_registration_screen.dart';
import '../utils/slide_transition.dart';
import 'settings/shop_owner_settings.dart';

class ShopOwnerDashboard extends StatefulWidget {
  const ShopOwnerDashboard({super.key});

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  final ProductService _productService = ProductService();
  String? _ownerUID;
  bool _loading = true;
  String _greeting = '';
  String _shopName = '';
  double _revenue = 0;
  int _soldCount = 0;
  int _availableCount = 0;
  List<Product> _nearExpiry = [];
  List<Product> _topSelling = [];

  late final FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _initializeData();

    // listen for auth changes
    _auth.authStateChanges().listen((user) async {
      if (user != null && user.uid != _ownerUID) {
        await _reloadUID(user.uid);
      }
    });
  }

  Future<void> _reloadUID(String newUID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopOwnerUID', newUID);
    await _loadData(newUID);
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUID = _auth.currentUser?.uid;
    if (currentUID != null) {
      await prefs.setString('shopOwnerUID', currentUID);
    }
    final savedUID = prefs.getString('shopOwnerUID');
    final ownerUID = currentUID ?? savedUID;

    if (ownerUID != null) {
      await _loadData(ownerUID);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadData(String ownerUID) async {
    try {
      // shop name
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(ownerUID).get();
      _shopName = userDoc.data()?['shopName'] ?? 'Your Shop';

      // greeting
      final hour = DateTime.now().hour;
      if (hour < 12) {
        _greeting = 'Good Morning';
      } else if (hour < 17) {
        _greeting = 'Good Afternoon';
      } else {
        _greeting = 'Good Evening';
      }

      // products and orders
      final productSnap = await FirebaseFirestore.instance
          .collection('products')
          .where('ownerId', isEqualTo: ownerUID)
          .get();
      final products =
          productSnap.docs.map((doc) => Product.fromFirestore(doc)).toList();

      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('ownerId', isEqualTo: ownerUID)
          .get();
      final soldIds = orderSnap.docs.map((e) => e['productId']).toList();

      // analytics
      double revenue = 0;
      int soldCount = soldIds.length;
      List<Product> soldProducts = [];

      for (var doc in productSnap.docs) {
        final p = Product.fromFirestore(doc);
        if (soldIds.contains(p.id)) {
          soldProducts.add(p);
          revenue += p.discountedPrice;
        }
      }

      int availableCount = products.length - soldCount;

      // near expiry (≤5 days)
      final now = DateTime.now();
      final nearExpiry = products
          .where((p) =>
              p.expiryDate.difference(now).inDays >= 0 &&
              p.expiryDate.difference(now).inDays <= 5)
          .toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      // top selling
      Map<String, int> sellCount = {};
      for (var id in soldIds) {
        sellCount[id] = (sellCount[id] ?? 0) + 1;
      }
      final topSelling = products
          .where((p) => sellCount.containsKey(p.id))
          .toList()
        ..sort((a, b) => sellCount[b.id]!.compareTo(sellCount[a.id]!));

      setState(() {
        _ownerUID = ownerUID;
        _revenue = revenue;
        _soldCount = soldCount;
        _availableCount = availableCount;
        _nearExpiry = nearExpiry;
        _topSelling = topSelling.take(3).toList();
        _loading = false;
      });
    } catch (e) {
      print('⚠️ Error loading dashboard: $e');
      setState(() => _loading = false);
    }
  }

  void _navigateToAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    await _loadData(_ownerUID!);
  }

  void _navigateToShopRegistration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ownerUID == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Shop Owner Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context)
                  .push(SlideRightRoute(page: const ShopOwnerSettingsScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _navigateToAddProduct,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => await _loadData(_ownerUID!),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧑‍💼 Greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '$_greeting, $_shopName 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // 🧮 Store Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('Revenue', '₹${_revenue.toStringAsFixed(0)}',
                            Colors.indigo),
                        _summaryItem('Sold', '$_soldCount', Colors.red),
                        _summaryItem('Available', '$_availableCount', Colors.green),
                      ],
                    ),
                  ),
                ),
              ),

              // ⚠️ Near Expiry Products — Professional Vertical Layout
              if (_nearExpiry.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Near Expiry Products',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: _nearExpiry.map((p) {
                          final daysLeft =
                              p.expiryDate.difference(DateTime.now()).inDays;
                          final isExpired = daysLeft < 0;

                          Color badgeColor;
                          if (isExpired) {
                            badgeColor = Colors.grey;
                          } else if (daysLeft <= 2) {
                            badgeColor = Colors.red.shade400;
                          } else {
                            badgeColor = Colors.orange.shade400;
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // 🖼 Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: p.imageUrl.isNotEmpty
                                        ? Image.network(
                                            p.imageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.orange.shade50,
                                            child: const Icon(
                                              Icons.inventory_2_outlined,
                                              color: Colors.orange,
                                              size: 30,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // 📄 Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Category: ${p.category}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isExpired
                                                ? 'Expired'
                                                : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // ⭐ Top Selling Products
              if (_topSelling.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    color: Colors.blue.shade50,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏆 Top Selling Products',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._topSelling.map((p) {
                            return Text(
                              '• ${p.name}',
                              style: GoogleFonts.poppins(fontSize: 13),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}
