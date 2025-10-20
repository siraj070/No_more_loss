import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'shop_owner_dashboard.dart';
import 'checkout_screen.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  String _userRole = '';
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> categories = [
    'All',
    'Dairy',
    'Snacks',
    'Beverages',
    'Bakery',
    'Fruits',
    'Vegetables',
    'Frozen',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data()?['role'] == null) {
        await _showRoleSelectionDialog();
        return;
      }
      setState(() {
        _userRole = doc.data()?['role'] ?? 'Customer';
        _isLoading = false;
      });
    }
  }

  Future<void> _showRoleSelectionDialog() async {
    String selectedRole = 'Customer';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Select Your Role', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  title: Text('Customer'),
                  subtitle: Text('Browse and buy products'),
                  value: 'Customer',
                  groupValue: selectedRole,
                  onChanged: (value) => setDialogState(() => selectedRole = value!),
                  activeColor: Color(0xFF10B981),
                ),
                RadioListTile(
                  title: Text('Shop Owner'),
                  subtitle: Text('Add and manage products'),
                  value: 'Shop Owner',
                  groupValue: selectedRole,
                  onChanged: (value) => setDialogState(() => selectedRole = value!),
                  activeColor: Color(0xFF10B981),
                ),
              ],
            );
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final user = _authService.getCurrentUser();
              await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
                'email': user.email,
                'role': selectedRole,
                'createdAt': Timestamp.now(),
              });
              Navigator.pop(dialogContext);
              setState(() {
                _userRole = selectedRole;
                _isLoading = false;
              });
            },
            child: Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF10B981),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Fresh Deals 🔥',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Save 50-70% on Near Expiry Products',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (_userRole == 'Customer')
                IconButton(
                  icon: Icon(Icons.receipt_long, color: Colors.white),
                  tooltip: 'My Orders',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderHistoryScreen()),
                  ),
                ),
              if (_userRole == 'Shop Owner')
                IconButton(
                  icon: Icon(Icons.dashboard, color: Colors.white),
                  tooltip: 'Dashboard',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ShopOwnerDashboard()),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF10B981)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Color(0xFF10B981),
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Color(0xFF10B981) : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: StreamBuilder<List<Product>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No products available', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                final filteredProducts = _filterProducts(snapshot.data!);
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ProductCard(
                        product: filteredProducts[index],
                        isCustomer: _userRole == 'Customer',
                      );
                    },
                    childCount: filteredProducts.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _userRole == 'Customer' && cartService.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen()),
              ),
              icon: Icon(Icons.shopping_cart),
              label: Text('${cartService.itemCount} items • ₹${cartService.totalAmount.toStringAsFixed(0)}'),
              backgroundColor: Color(0xFFF59E0B),
            )
          : null,
    );
  }
}
