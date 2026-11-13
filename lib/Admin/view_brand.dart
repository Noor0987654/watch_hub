import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewBrands extends StatefulWidget {
  const ViewBrands({super.key});
  static const String id = "ViewBrands";

  @override
  State<ViewBrands> createState() => _ViewBrandsState();
}

class _ViewBrandsState extends State<ViewBrands> {
  // ---- Theme colors (Luxury Black & Gold) ----
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kDarkGold = Color(0xFFB8960F);
  static const Color kLightGold = Color(0xFFF5E6A3);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kTextGold = Color(0xFFD4AF37);

  String searchQuery = '';

  // ========== FETCH FUNCTION WITH SEARCH ==========
  Stream<QuerySnapshot> _fetchBrands() {
    if (searchQuery.isEmpty) {
      return FirebaseFirestore.instance
          .collection('Brands')
          .orderBy('dateAdded', descending: true)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('Brands')
        .where('brandName', isGreaterThanOrEqualTo: searchQuery)
        .where('brandName', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .orderBy('brandName')
        .snapshots();
  }

  // ========== DELETE FUNCTION ==========
  Future<void> _deleteBrand(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Brands')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Brand successfully deleted!"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // ========== UPDATE FUNCTION ==========
  Future<void> _updateBrand(String docId, Map<String, dynamic> updatedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('Brands')
          .doc(docId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Brand successfully updated!"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // ========== DECODE IMAGE ==========
  Uint8List? _safeDecode(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  // ========== SHOW EDIT DIALOG ==========
  Future<void> _showEditDialog(BuildContext context, String docId, Map<String, dynamic> brand) async {
    final formKey = GlobalKey<FormState>();
    final brandNameController = TextEditingController(text: brand['brandName'] ?? '');
    final descriptionController =
        TextEditingController(text: brand['description'] ?? '');

    bool? saved = await showDialog<bool>(
      context: context,
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
            "Edit Brand",
            style: TextStyle(
              color: kPrimaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: kBgBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kPrimaryGold.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: brandNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Brand Name",
                        labelStyle: TextStyle(color: kPrimaryGold),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? "Brand name is required"
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: kBgBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kPrimaryGold.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: TextStyle(color: kPrimaryGold),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      Map<String, dynamic> updatedData = {
        'brandName': brandNameController.text.trim(),
        'description': descriptionController.text.trim(),
      };

      await _updateBrand(docId, updatedData);
    }
  }

  // ========== SHOW DELETE CONFIRMATION ==========
  Future<void> _showDeleteConfirmation(BuildContext context, String docId) async {
    bool confirmDelete = await showDialog(
          context: context,
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
                "Delete Brand?",
                style: TextStyle(
                  color: kPrimaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                "Kya aap waqai is brand ko delete karna chahte hain? Ye action wapas nahi ho sakega.\n\nNote: Agar is brand ke naam se watches add ho chuki hain, unka brand field 'Unknown Brand' show karega.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      await _deleteBrand(docId);
    }
  }

  // ========== BUILD UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text(
          "Available Brands",
          style: TextStyle(
            color: kPrimaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
        actions: [
          // Total brands count
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Brands').snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.data?.docs.length ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: kPrimaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kPrimaryGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count brands',
                    style: const TextStyle(
                      color: kPrimaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Container(
              decoration: BoxDecoration(
                color: kCardBlack,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kPrimaryGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search brands by name...",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: kPrimaryGold),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: kPrimaryGold),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
              ),
            ),
          ),

          // --- HEADER ROW ---
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(
              children: [
                const SizedBox(width: 84),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    "BRAND NAME",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    "DESCRIPTION",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),
          Container(
            height: 1,
            color: kPrimaryGold.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),

          // --- LIST VIEW ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchBrands(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error fetching data",
                      style: TextStyle(
                          color: Colors.red.shade400, fontWeight: FontWeight.w500),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isEmpty
                              ? Icons.branding_watermark_rounded
                              : Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? "No brands available yet!"
                              : "No brands found for '$searchQuery'",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                            child: Text(
                              "Clear search",
                              style: TextStyle(color: kPrimaryGold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final brandDocs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                  itemCount: brandDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var brandDoc = brandDocs[index];
                    var brand = brandDoc.data() as Map<String, dynamic>;
                    String docId = brandDoc.id;

                    String brandName = brand['brandName'] ?? 'Unnamed Brand';
                    String description = brand['description'] ?? 'No description available.';
                    String? logoBase64 = brand['logo'];
                    Uint8List? logoBytes = _safeDecode(logoBase64);

                    return Container(
                      decoration: BoxDecoration(
                        color: kCardBlack,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: kPrimaryGold.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryGold.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 84,
                                height: 84,
                                child: logoBytes != null
                                    ? Image.memory(logoBytes, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: Icon(
                                          Icons.branding_watermark_rounded,
                                          color: kPrimaryGold.withOpacity(0.4),
                                          size: 32,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Brand name
                            Expanded(
                              flex: 3,
                              child: Text(
                                brandName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Description
                            Expanded(
                              flex: 5,
                              child: Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                  height: 1.2,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Actions
                            SizedBox(
                              width: 56,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () => _showDeleteConfirmation(context, docId),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red.shade400,
                                        size: 20,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: kPrimaryGold.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kPrimaryGold.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () =>
                                          _showEditDialog(context, docId, brand),
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: kPrimaryGold,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}