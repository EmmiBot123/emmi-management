import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import '../../../../Model/Bill.dart';
import '../../../../Providers/BillProvider.dart';

class AddBillPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AddBillPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'Travel';
  final List<String> _types = ['Travel', 'Food', 'Stay', 'Other'];

  File? _imageFile;
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    // TODO: Replace with your actual Cloudinary credentials
    final cloudinary =
        CloudinaryPublic('dx69jhzba', 'bill_upload', cache: false);
    CloudinaryResponse response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(image.path,
          resourceType: CloudinaryResourceType.Image),
    );
    return response.secureUrl;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      // 1. Upload Image (Only if selected)
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      // 2. Create Bill
      final bill = Bill(
        userId: widget.userId,
        userName: widget.userName,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        description: _descController.text,
        imageUrl: imageUrl, // Can be null now
        createdAt: DateTime.now(),
      );

      await context.read<BillProvider>().addBill(bill);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Bill")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Gallery'),
                              onTap: () {
                                _pickImage(ImageSource.gallery);
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Camera'),
                              onTap: () {
                                _pickImage(ImageSource.camera);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.grey),
                              Text("Attach Receipt",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter amount' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                              SizedBox(width: 8),
                              Text("Uploading..."),
                            ],
                          )
                        : const Text("Submit Bill"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
