import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  double? _minPrice;
  double? _maxPrice;
  double _minDiscount = 0;
  bool _expiringSoon = false;

  final List<String> _categories = [
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
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        title: Text('Search & Filter',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                hintText: 'Search for products...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // 🏷 Category Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: GoogleFonts.poppins(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedCategory = value ?? 'All'),
            ),
          ),

          // ⚙️ Filters row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Min Price',
                      prefixText: '₹',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _minPrice = double.tryParse(v.isEmpty ? '0' : v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Max Price',
                      prefixText: '₹',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _maxPrice = double.tryParse(v.isEmpty ? '0' : v),
                  ),
                ),
              ],
            ),
          ),

          // 🎯 Discount Slider + Expiry Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Min Discount: ${_minDiscount.toInt()}%',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  ],
                ),
                Slider(
                  value: _minDiscount,
                  onChanged: (v) => setState(() => _minDiscount = v),
                  min: 0,
                  max: 80,
                  divisions: 8,
                  activeColor: const Color(0xFF10B981),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Show expiring soon (3 days)',
                        style: GoogleFonts.poppins(fontSize: 14)),
                    Switch(
                      value: _expiringSoon,
                      onChanged: (v) => setState(() => _expiringSoon = v),
                      activeColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // 🧾 Product Results
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: productService.searchProducts(
                queryText: _searchController.text,
                category: _selectedCategory,
                minPrice: _minPrice,
                maxPrice: _maxPrice,
                minDiscountPercent: _minDiscount,
                expiringSoon: _expiringSoon,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No products found',
                        style: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 16)),
                  );
                }

                final products = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final daysLeft =
                        product.expiryDate.difference(DateTime.now()).inDays;
                    final isExpired =
                        product.expiryDate.isBefore(DateTime.now());

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12)),
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade100,
                                      child: const Icon(
                                          Icons.local_grocery_store_outlined,
                                          color: Colors.grey),
                                    ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    Text(product.category,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '₹${product.discountedPrice.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF10B981))),
                                    Text(
                                      isExpired
                                          ? 'Expired'
                                          : daysLeft <= 3
                                              ? '$daysLeft days left'
                                              : 'Exp: ${product.expiryDate.toLocal().toString().split(' ')[0]}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: isExpired
                                            ? Colors.red
                                            : daysLeft <= 3
                                                ? Colors.orange
                                                : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
