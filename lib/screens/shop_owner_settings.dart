import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopOwnerSettingsScreen extends StatelessWidget {
  const ShopOwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Shop Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🪩 Logo Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Image.asset('assets/logo.png', height: 90),
                  const SizedBox(height: 10),
                  Text("Near Expiry Market",
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("No More Loss • No More Waste",
                      style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ⚙️ Settings Options
            _buildSettingsTile(context, Icons.store_mall_directory, "My Shop Details"),
            _buildSettingsTile(context, Icons.inventory_2, "Manage Products"),
            _buildSettingsTile(context, Icons.add_circle_outline, "Add New Product"),
            _buildSettingsTile(context, Icons.notifications_active_outlined, "Notifications"),
            _buildSettingsTile(context, Icons.info_outline, "About App"),
            const SizedBox(height: 12),
            _buildSettingsTile(context, Icons.logout, "Logout", color: Colors.redAccent),

            const SizedBox(height: 30),
            Text("v1.0.0 • Shop Owner Edition",
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, {Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFF10B981)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
