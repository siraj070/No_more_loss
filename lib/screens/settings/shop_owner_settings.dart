import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../login_screen.dart';

class ShopOwnerSettingsScreen extends StatefulWidget {
  const ShopOwnerSettingsScreen({super.key});

  @override
  State<ShopOwnerSettingsScreen> createState() => _ShopOwnerSettingsScreenState();
}

class _ShopOwnerSettingsScreenState extends State<ShopOwnerSettingsScreen> {
  final _auth = FirebaseAuth.instance;
  DocumentSnapshot<Map<String, dynamic>>? _userDoc;
  DocumentSnapshot<Map<String, dynamic>>? _approvedShop;
  bool _loading = true;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _auth.currentUser!;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final approved =
        await FirebaseFirestore.instance.collection('approved_shops').doc(user.uid).get();
    setState(() {
      _userDoc = userDoc;
      _approvedShop = approved.exists ? approved : null;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? '';
    final name = _userDoc?.data()?['name'] ?? email.split('@').first;
    final role = _userDoc?.data()?['role'] ?? 'Shop Owner';

    final shopName = _approvedShop?.data()?['shopName'];
    final statusBadge = _approvedShop == null
        ? const _StatusBadge(text: 'Pending Approval', color: Color(0xFFF59E0B))
        : const _StatusBadge(text: 'Approved', color: Color(0xFF22C55E));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE8FFF3), Color(0xFFF4FFFA)], // very light green
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Near Expiry Market',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  )),
                              Text('Shop Owner Settings',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  )),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFF6EE7B7), // owner accent
                            child: Icon(Icons.store_mall_directory, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                Text(email,
                                    style: GoogleFonts.poppins(
                                        color: const Color(0xFF64748B),
                                        fontSize: 13)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _chip(role, const Color(0xFF0F766E)),
                                    if (shopName != null)
                                      _chip(shopName, const Color(0xFF14532D)),
                                    statusBadge,
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _TileHeader('Shop'),
                        _NavTile(
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFF6EE7B7),
                          title: 'Orders & Fulfillment',
                          subtitle: 'Incoming orders, history',
                          onTap: () {},
                        ),
                        _NavTile(
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF6EE7B7),
                          title: 'Inventory',
                          subtitle: 'Stock, pricing, expiry',
                          onTap: () {},
                        ),
                        _TileHeader('Preferences'),
                        _SwitchTile(
                          icon: Icons.notifications_active_outlined,
                          color: const Color(0xFF6EE7B7),
                          title: 'Notifications',
                          value: _notifications,
                          onChanged: (v) => setState(() => _notifications = v),
                        ),
                        _NavTile(
                          icon: Icons.map_outlined,
                          color: const Color(0xFF6EE7B7),
                          title: 'Shop Location Privacy',
                          subtitle: 'Hide door no. & street for customers',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.logout),
                            label: Text('Log out',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// shared tiles
class _TileHeader extends StatelessWidget {
  final String text;
  const _TileHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0.5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0.5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      ),
    );
  }
}

