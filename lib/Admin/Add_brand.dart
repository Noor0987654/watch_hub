import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class BrandFormPage extends StatefulWidget {
  const BrandFormPage({super.key});
  static const String id = "BrandFormPage";

  @override
  State<BrandFormPage> createState() => _BrandFormPageState();
}

class _BrandFormPageState extends State<BrandFormPage> {
  // ---- Theme colors (Luxury Black & Gold) ----
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kDarkGold = Color(0xFFB8960F);
  static const Color kLightGold = Color(0xFFF5E6A3);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kTextGold = Color(0xFFD4AF37);

  final _formKey = GlobalKey<FormState>();

  // Controllers for Brand properties
  TextEditingController brandNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final imagePicker = ImagePicker();
  XFile? logoImage;
  Uint8List? logoBytes;
  String? logoBase64;
  bool isLoading = false;

  // Pick a single logo image for the brand
  Future<void> pickLogoImage() async {
    try {
      final XFile? pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage != null) {
        final Uint8List bytes = await pickedImage.readAsBytes();
        setState(() {
          logoImage = pickedImage;
          logoBytes = bytes;
        });
        _showSnackBar("Logo selected!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Error picking logo: $e", Colors.red);
    }
  }

  Future<void> uploadLogo() async {
    if (logoBytes != null) {
      logoBase64 = base64Encode(logoBytes!);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: kPrimaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: const Text(
            "✅ Success",
            style: TextStyle(
              color: kPrimaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Brand Added Successfully!",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGold,
                foregroundColor: Colors.black,
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    brandNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text(
          "Add New Brand",
          style: TextStyle(
            color: kPrimaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBgBlack,
        elevation: 2,
        shadowColor: kPrimaryGold.withOpacity(0.2),
        iconTheme: const IconThemeData(color: kPrimaryGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: kPrimaryGold.withOpacity(0.2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // Brand Name Field
                Container(
                  decoration: BoxDecoration(
                    color: kCardBlack,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kPrimaryGold.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: brandNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Brand Name (e.g., Rolex, Casio, Seiko)",
                      labelStyle: TextStyle(color: kPrimaryGold),
                      hintText: "Enter brand name",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.branding_watermark, color: kPrimaryGold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Please enter brand name" : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Brand Description Field
                Container(
                  decoration: BoxDecoration(
                    color: kCardBlack,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kPrimaryGold.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Brand Description (optional)",
                      labelStyle: TextStyle(color: kPrimaryGold),
                      hintText: "Enter brand description",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.description, color: kPrimaryGold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Logo Preview Section
                if (logoImage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Selected Logo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryGold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                logoImage = null;
                                logoBytes = null;
                              });
                              _showSnackBar("Logo removed", Colors.orange);
                            },
                            child: const Text(
                              "Remove",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kCardBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: kPrimaryGold.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            logoBytes!,
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey,
                              width: 130,
                              height: 130,
                              child: const Icon(Icons.image, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),

                // Pick Logo Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: pickLogoImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCardBlack,
                      foregroundColor: kPrimaryGold,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: kPrimaryGold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: Icon(Icons.image_outlined, color: kPrimaryGold),
                    label: Text(
                      logoImage == null ? "Select Brand Logo" : "Change Brand Logo",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "💡 Tip: A clean, square logo image works best.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 25),

                // Submit Button
                isLoading
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (logoBytes == null) {
                                _showSnackBar("Please select a brand logo", Colors.orange);
                                return;
                              }

                              setState(() => isLoading = true);

                              try {
                                await uploadLogo();

                                await FirebaseFirestore.instance
                                    .collection('Brands')
                                    .add({
                                  'brandName': brandNameController.text.trim(),
                                  'description': descriptionController.text.trim(),
                                  'dateAdded': DateTime.now(),
                                  'logo': logoBase64,
                                });

                                setState(() {
                                  isLoading = false;
                                  logoImage = null;
                                  logoBytes = null;
                                  logoBase64 = null;
                                  brandNameController.clear();
                                  descriptionController.clear();
                                });

                                showSuccessDialog(context);
                                _showSnackBar("✅ Brand added to WatchHub!", Colors.green);

                              } catch (firebaseError) {
                                setState(() => isLoading = false);
                                _showSnackBar(
                                  "Error: ${firebaseError.toString()}",
                                  Colors.red,
                                );
                                print("FIREBASE ERROR: $firebaseError");
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Insert Brand",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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