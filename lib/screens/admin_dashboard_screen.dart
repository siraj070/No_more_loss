import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _updateShopStatus(
      String shopId, String newStatus, Map<String, dynamic> shopData) async {
    try {
      // ✅ Move shop to approved/rejected
      final targetCollection =
          newStatus == 'approved' ? 'approved_shops' : 'rejected_shops';

      await _firestore.collection(targetCollection).doc(shopId).set({
        ...shopData,
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      // ✅ Remove from pending
      await _firestore.collection('pending_shops').doc(shopId).delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Shop ${newStatus == 'approved' ? 'approved' : 'rejected'} successfully!',
        ),
        backgroundColor:
            newStatus == 'approved' ? Colors.green : Colors.redAccent,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildShopList(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              collectionName == 'pending_shops'
                  ? 'No pending shops found ✅'
                  : collectionName == 'approved_shops'
                      ? 'No approved shops yet 🏪'
                      : 'No rejected shops 🚫',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 15),
            ),
          );
        }

        final shops = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shops.length,
          itemBuilder: (context, index) {
            final shop = shops[index];
            final shopData = shop.data() as Map<String, dynamic>;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shopData['shopPhotoUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          shopData['shopPhotoUrl'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      shopData['shopName'] ?? 'Unnamed Shop',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shopData['email'] ?? 'No email',
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Text('GST: ${shopData['gstNumber'] ?? '-'}',
                        style: GoogleFonts.poppins(fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Address: ${shopData['shopAddress'] ?? '-'}',
                        style: GoogleFonts.poppins(fontSize: 14)),
                    const SizedBox(height: 10),

                    // Buttons only for pending shops
                    if (collectionName == 'pending_shops')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _updateShopStatus(
                                shop.id, 'approved', shopData),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _updateShopStatus(
                                shop.id, 'rejected', shopData),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      )
                    else
                      // Approved or Rejected info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(
                              shopData['status']?.toUpperCase() ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: shopData['status'] == 'approved'
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                          Text(
                            'Updated: ${shopData['updatedAt'] != null ? (shopData['updatedAt'] as Timestamp).toDate().toString().split('.')[0] : 'N/A'}',
                            style: GoogleFonts.poppins(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShopList('pending_shops'),
          _buildShopList('approved_shops'),
          _buildShopList('rejected_shops'),
        ],
      ),
    );
  }
}
