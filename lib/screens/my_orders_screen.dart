import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Color _statusColor(String s) {
    switch (s) {
      case 'ordered': return const Color(0xFF2563EB);
      case 'picked': return const Color(0xFFF59E0B);
      case 'delivered': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  int _statusIndex(String s) {
    switch (s) {
      case 'ordered': return 0;
      case 'picked': return 1;
      case 'delivered': return 2;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: uid == null
          ? Center(child: Text('Please sign in', style: GoogleFonts.poppins()))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(child: Text('No orders yet', style: GoogleFonts.poppins()));
                }
                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final status = d['status'] as String? ?? 'ordered';
                    final pricing = (d['pricing'] ?? {}) as Map<String, dynamic>;
                    final items = (d['items'] ?? []) as List;
                    final addressString = d['addressString'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (items.isNotEmpty)
                            Text(
                              '${items[0]['name']}${items.length > 1 ? ' + ${items.length - 1} more' : ''}',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          if (addressString.isNotEmpty)
                            Text(addressString, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₹${(pricing['grandTotal'] ?? 0).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                              Row(
                                children: List.generate(3, (idx) {
                                  final active = idx <= _statusIndex(status);
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: active ? _statusColor(status) : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
