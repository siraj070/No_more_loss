import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopRegistrationScreen extends StatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _shopNameController.text = data['name'] ?? '';
      _addressController.text = data['address'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _gstController.text = data['gst'] ?? '';
    }
  }

  Future<void> _saveShopInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(user.uid)
          .set({
        'name': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gst': _gstController.text.trim(),
        'ownerId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Shop information saved!'),
        backgroundColor: Color(0xFF10B981),
      ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Shop Registration',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Register or update your shop info to start selling',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Color(0xFF065F46)))),
              ]),
            ),
            const SizedBox(height: 24),
            _buildField(_shopNameController, 'Shop Name', Icons.store_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            _buildField(_addressController, 'Shop Address',
                Icons.location_on_outlined,
                maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'Contact Number', Icons.phone_outlined,
                keyboard: TextInputType.phone,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (v.length != 10) return 'Invalid';
                  return null;
                }),
            const SizedBox(height: 16),
            _buildField(_gstController, 'GST Number (Optional)',
                Icons.receipt_long_outlined),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveShopInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Save Shop Info',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator,
      int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF10B981), width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
      ),
    );
  }
}
