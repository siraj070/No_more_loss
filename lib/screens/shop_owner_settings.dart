import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopOwnerSettingsScreen extends StatelessWidget {
  const ShopOwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title:
            Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
                ]),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(user?.email ?? 'User',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Shop Owner', style: GoogleFonts.poppins(color: Colors.grey.shade600))
                  ]))
            ]),
          ),
          const SizedBox(height: 24),
          Text('Account Settings',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTile(
              icon: Icons.store_outlined,
              title: 'Shop Information',
              subtitle: 'Update your shop details',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Go update shop info')));
              }),
          _buildTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Coming soon')));
              }),
          _buildTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with your account',
              onTap: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('support@nomoreloss.com')));
              }),
          const SizedBox(height: 24),
          Text('Danger Zone',
              style:
                  GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
          const SizedBox(height: 12),
          _buildTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              isDestructive: true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              }),
          _buildTile(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanent delete',
              isDestructive: true,
              onTap: () {
                _confirmDelete(context);
              }),
        ]),
      ),
    );
  }

  Widget _buildTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isDestructive ? const Color(0xFFEF4444) : Colors.black)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Delete Account?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Text(
                  'This action cannot be undone. All data will be permanently deleted.',
                  style: GoogleFonts.poppins()),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser!;
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                      final products = await FirebaseFirestore.instance
                          .collection('products')
                          .where('ownerId', isEqualTo: user.uid)
                          .get();
                      for (var doc in products.docs) {
                        await doc.reference.delete();
                      }
                      await user.delete();
                      Navigator.pop(context);
                    },
                    child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)))
              ],
            ));
  }
}
