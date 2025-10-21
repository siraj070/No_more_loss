import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checkout_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doorController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _doorController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _proceedToCheckout() {
    if (_formKey.currentState!.validate()) {
      final address = {
        'door': _doorController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CheckoutScreen(address: address)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Delivery Address',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please provide your delivery address',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildField(_doorController, 'House/Flat No.',
                  Icons.home_outlined, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),

              _buildField(_streetController, 'Street Address',
                  Icons.location_on_outlined, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),

              _buildField(_cityController, 'City',
                  Icons.location_city_outlined, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),

              _buildField(_pincodeController, 'Pincode',
                  Icons.markunread_mailbox_outlined,
                  keyboard: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (v.length != 6) return 'Invalid';
                    return null;
                  }),
              const SizedBox(height: 16),

              _buildField(_phoneController, 'Phone Number',
                  Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (v.length != 10) return 'Invalid';
                    return null;
                  }),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Proceed to Payment',
                    style:
                        GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}
