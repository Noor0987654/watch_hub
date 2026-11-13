import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddWatch extends StatefulWidget {
  const AddWatch({super.key});
  static const String id = "Addwatch";

  @override
  State<AddWatch> createState() => _AddWatchState();
}

class _AddWatchState extends State<AddWatch> {
  // ---- Theme colors (Luxury Black & Gold) ----
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kDarkGold = Color(0xFFB8960F);
  static const Color kLightGold = Color(0xFFF5E6A3);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kTextGold = Color(0xFFD4AF37);

  final _formKey = GlobalKey<FormState>();

  // Controllers for Watch properties
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // Selected brand (comes from the Brands collection dropdown)
  String? selectedBrand;

  // 👇 NEW: Category selection
  String? selectedCategory;
  final List<String> _categories = ['Male', 'Female', 'Unisex'];

  final imagePicker = ImagePicker();
  List<XFile> images = [];
  List<Uint8List> imageBytesList = [];
  List<String> imageBase64List = [];
  bool isLoading = false;

  // Multiple image selection
  Future<void> pickImages() async {
    try {
      final List<XFile>? pickedImages = await imagePicker.pickMultiImage();

      if (pickedImages != null && pickedImages.isNotEmpty) {
        await _addPickedImages(pickedImages);
        _showSnackBar("${pickedImages.length} images selected!", Colors.green);
      } else {
        _showSnackBar("Select images one by one", Colors.orange);
        await _pickImagesOneByOne();
      }
    } catch (e) {
      print("Error picking images: $e");
      await _pickImagesOneByOne();
    }
  }

  // Fallback method to pick images one by one
  Future<void> _pickImagesOneByOne() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        await _addPickedImages([image]);
        _showSnackBar("Image added! Select more if needed.", Colors.blue);

        bool addMore = await _showAddMoreDialog();
        if (addMore) {
          await _pickImagesOneByOne();
        }
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  // Reads bytes for each picked image immediately so previews work on Web too
  Future<void> _addPickedImages(List<XFile> pickedImages) async {
    final List<Uint8List> bytesList = [];
    for (var img in pickedImages) {
      bytesList.add(await img.readAsBytes());
    }
    setState(() {
      images.addAll(pickedImages);
      imageBytesList.addAll(bytesList);
    });
  }

  Future<bool> _showAddMoreDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: kPrimaryGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: const Text(
          "Add More Images?",
          style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Do you want to select another image?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "No, I'm done",
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text("Yes, add more"),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> uploadImages() async {
    imageBase64List.clear();
    for (var bytes in imageBytesList) {
      imageBase64List.add(base64Encode(bytes));
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
            style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Watch Product Added Successfully!",
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
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text(
          "Add New Watch",
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

                // Watch Name Field
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
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Watch Name",
                      labelStyle: TextStyle(color: kPrimaryGold),
                      hintText: "Enter watch name",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.watch, color: kPrimaryGold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Please enter watch name" : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Watch Brand Dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Brands')
                      .orderBy('brandName')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        "Error loading brands",
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCardBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: kPrimaryGold.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Loading brands...",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCardBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "No brands found. Please add a brand first from the 'Add Brand' screen.",
                                style: TextStyle(color: Colors.orange, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final brandNames = docs
                        .map((doc) => (doc.data() as Map<String, dynamic>)['brandName'] as String?)
                        .where((name) => name != null && name.isNotEmpty)
                        .map((name) => name!)
                        .toSet()
                        .toList();

                    if (selectedBrand != null && !brandNames.contains(selectedBrand)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => selectedBrand = null);
                      });
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: kCardBlack,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kPrimaryGold.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedBrand,
                        isExpanded: true,
                        dropdownColor: kCardBlack,
                        style: const TextStyle(color: Colors.white),
                        icon: Icon(Icons.arrow_drop_down, color: kPrimaryGold),
                        decoration: InputDecoration(
                          labelText: "Select Brand",
                          labelStyle: TextStyle(color: kPrimaryGold),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.branding_watermark, color: kPrimaryGold),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: brandNames
                            .map((name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name, style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedBrand = value);
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? "Please select a brand" : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Watch Price Field
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
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Price (\$)",
                      labelStyle: TextStyle(color: kPrimaryGold),
                      hintText: "Enter watch price",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.attach_money, color: kPrimaryGold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Please enter watch price" : null,
                  ),
                ),
                const SizedBox(height: 20),

                // 👇 NEW: Category Field (Price ke neechay)
                Container(
                  decoration: BoxDecoration(
                    color: kCardBlack,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kPrimaryGold.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    dropdownColor: kCardBlack,
                    style: const TextStyle(color: Colors.white),
                    icon: Icon(Icons.arrow_drop_down, color: kPrimaryGold),
                    decoration: InputDecoration(
                      labelText: "Category *",
                      labelStyle: TextStyle(color: kPrimaryGold),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.category, color: kPrimaryGold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              category == 'Male'
                                  ? Icons.male
                                  : category == 'Female'
                                      ? Icons.female
                                      : Icons.person_outline,
                              color: kPrimaryGold,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              category,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Watch Description Field
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
                      labelText: "Description / Specifications",
                      labelStyle: TextStyle(color: kPrimaryGold),
                      hintText: "Enter watch description",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.description, color: kPrimaryGold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Please enter watch description" : null,
                  ),
                ),
                const SizedBox(height: 30),

                // Selected Images Preview Section
                if (images.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Selected Images (${images.length})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryGold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                images.clear();
                                imageBytesList.clear();
                              });
                              _showSnackBar("All images removed", Colors.orange);
                            },
                            child: const Text(
                              "Clear All",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 130,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: kCardBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: kPrimaryGold.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      imageBytesList[index],
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey,
                                        width: 110,
                                        height: 110,
                                        child: const Icon(Icons.image, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        images.removeAt(index);
                                        imageBytesList.removeAt(index);
                                      });
                                      _showSnackBar("Image removed", Colors.orange);
                                    },
                                    child: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.red,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),

                // Pick Images Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: pickImages,
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
                    icon: Icon(Icons.photo_library, color: kPrimaryGold),
                    label: Text(
                      images.isEmpty ? "Select Watch Images" : "Add More Images (${images.length})",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "💡 Tip: High-quality images allow users to zoom in on details.",
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
                              // 👇 Category validation
                              if (selectedCategory == null || selectedCategory!.isEmpty) {
                                _showSnackBar("Please select a category", Colors.orange);
                                return;
                              }
                              if (imageBytesList.isEmpty) {
                                _showSnackBar("Please select at least one watch image", Colors.orange);
                                return;
                              }

                              setState(() => isLoading = true);

                              try {
                                await uploadImages();

                                await FirebaseFirestore.instance
                                    .collection('Watches')
                                    .add({
                                  'name': nameController.text.trim(),
                                  'brand': selectedBrand,
                                  'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                                  'category': selectedCategory, // 👈 NEW: Category field added to Firestore
                                  'description': descriptionController.text.trim(),
                                  'dateAdded': DateTime.now(),
                                  'images': imageBase64List,
                                });

                                setState(() {
                                  isLoading = false;
                                  images.clear();
                                  imageBytesList.clear();
                                  imageBase64List.clear();
                                  nameController.clear();
                                  priceController.clear();
                                  descriptionController.clear();
                                  selectedBrand = null;
                                  selectedCategory = null; // 👈 NEW: Reset category
                                });

                                showSuccessDialog(context);
                                _showSnackBar("✅ Watch product added to WatchHub!", Colors.green);

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
                            "Insert Product",
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