import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();

  String _selectedCategory = 'Dairy';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  File? _pickedImage;
  Uint8List? _imageBytes;
  String? _imageUrl;
  String? _imageName;

  final List<String> _categories = [
    'Dairy', 'Snacks', 'Beverages', 'Bakery', 'Fruits', 'Vegetables', 'Frozen', 'Other'
  ];

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _originalPriceController.text = widget.product!.originalPrice.toString();
      _discountedPriceController.text = widget.product!.discountedPrice.toString();
      _selectedCategory = widget.product!.category;
      _selectedDate = widget.product!.expiryDate;
      _imageUrl = widget.product!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageName = result.files.first.name;
          if (kIsWeb) {
            _imageBytes = result.files.first.bytes;
          } else {
            _pickedImage = File(result.files.first.path!);
          }
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<String?> _uploadImage() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final filename = _imageName ?? 'product-image';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('$userId-${DateTime.now().millisecondsSinceEpoch}-$filename');

      UploadTask uploadTask;
      if (kIsWeb && _imageBytes != null) {
        uploadTask = storageRef.putData(_imageBytes!);
      } else if (_pickedImage != null) {
        uploadTask = storageRef.putFile(_pickedImage!);
      } else {
        return _imageUrl ?? '';
      }

      print('Uploading image...');
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image url uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e, st) {
      print("Image upload failed: $e");
      print("Stack: $st");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e'), backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    print('Starting product add/update...');
    setState(() => _isLoading = true);

    try {
      String? imageUrlToUse = _imageUrl;

      if (kIsWeb ? _imageBytes != null : _pickedImage != null) {
        print('Preparing to upload image...');
        final url = await _uploadImage();
        print('Image upload finished.');
        if (url != null) imageUrlToUse = url;
      }

      final user = FirebaseAuth.instance.currentUser;

      // ✅ Ensure full product model matches Firestore expectations
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: 'No description provided',
        category: _selectedCategory,
        originalPrice: double.parse(_originalPriceController.text.trim()),
        discountedPrice: double.parse(_discountedPriceController.text.trim()),
        quantity: 1,
        imageUrl: imageUrlToUse ?? '',
        ownerId: user?.uid ?? '', // ✅ This ensures visibility for the right owner
        expiryDate: _selectedDate,
      );

      if (widget.product == null) {
        print('Adding product...');
        await _productService.addProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product added successfully!'),
          backgroundColor: Color(0xFF10B981),
        ));
      } else {
        print('Updating product...');
        await _productService.updateProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ));
      }

      print('Navigating back...');
      Navigator.pop(context);
    } catch (e, st) {
      print('Exception during add/update: $e');
      print('Stack: $st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add/update product: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      setState(() => _isLoading = false);
      print('Loading state set to false');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (kIsWeb && _imageBytes != null) {
      imageWidget = Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity, height: 180);
    } else if (_pickedImage != null) {
      imageWidget = Image.file(_pickedImage!, fit: BoxFit.cover, width: double.infinity, height: 180);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      imageWidget = Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 180);
    } else {
      imageWidget = Center(child: Text('Tap to add product image', style: GoogleFonts.poppins(color: Colors.grey[700])));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: imageWidget,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Product Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (value) => value!.isEmpty ? 'Please enter product name' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                  decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originalPriceController,
                  decoration: InputDecoration(labelText: 'Original Price', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter original price';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountedPriceController,
                  decoration: InputDecoration(labelText: 'Discounted Price', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter discounted price';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Expiry Date: ${_selectedDate.toLocal().toString().split(' ')[0]}', style: GoogleFonts.poppins(fontSize: 16)),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF10B981))),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.product == null ? 'Add Product' : 'Update Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
