import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewWatches extends StatefulWidget {
  const ViewWatches({super.key});
  static const String id = "ViewWatches";

  @override
  State<ViewWatches> createState() => _ViewWatchesState();
}

class _ViewWatchesState extends State<ViewWatches> {
  // ---- Theme colors (Luxury Black & Gold) ----
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kDarkGold = Color(0xFFB8960F);
  static const Color kLightGold = Color(0xFFF5E6A3);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kTextGold = Color(0xFFD4AF37);

  String searchQuery = '';
  String? selectedBrandFilter;

  // ========== FETCH ALL WATCHES (Simple query - no composite index needed) ==========
  Stream<QuerySnapshot> _fetchAllWatches() {
    return FirebaseFirestore.instance
        .collection('Watches')
        .orderBy('dateAdded', descending: true)
        .snapshots();
  }

  // ========== CLIENT-SIDE FILTERING ==========
  List<QueryDocumentSnapshot> _filterWatches(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final brand = (data['brand'] ?? '').toString().toLowerCase();
      final searchLower = searchQuery.toLowerCase().trim();

      // Brand filter
      if (selectedBrandFilter != null && selectedBrandFilter!.isNotEmpty) {
        if (brand != selectedBrandFilter!.toLowerCase()) {
          return false;
        }
      }

      // Name search
      if (searchLower.isNotEmpty) {
        if (!name.contains(searchLower)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ========== DELETE FUNCTION ==========
  Future<void> _deleteWatch(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Watches')
          .doc(docId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Watch successfully deleted!"),
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
  Future<void> _updateWatch(String docId, Map<String, dynamic> updatedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('Watches')
          .doc(docId)
          .update(updatedData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Watch successfully updated!"),
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
  Future<void> _showEditDialog(BuildContext context, String docId, Map<String, dynamic> watch) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: watch['name'] ?? '');
    final brandController = TextEditingController(text: watch['brand'] ?? '');
    final descriptionController =
        TextEditingController(text: watch['description'] ?? '');
    final priceController =
        TextEditingController(text: watch['price']?.toString() ?? '');

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
            "Edit Watch",
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
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: TextStyle(color: kPrimaryGold),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? "Name is required"
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
                      controller: brandController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Brand",
                        labelStyle: TextStyle(color: kPrimaryGold),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? "Brand is required"
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
                      controller: priceController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Price",
                        labelStyle: TextStyle(color: kPrimaryGold),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Price is required";
                        }
                        if (double.tryParse(value) == null) {
                          return "Enter a valid number";
                        }
                        return null;
                      },
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
        'name': nameController.text.trim(),
        'brand': brandController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.parse(priceController.text.trim()),
      };
      
      await _updateWatch(docId, updatedData);
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
                "Delete Product?",
                style: TextStyle(
                  color: kPrimaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                "Kya aap waqai is watch ko delete karna chahte hain? Ye action wapas nahi ho sakega.",
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
      await _deleteWatch(docId);
    }
  }

  // ========== BUILD UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text(
          "Available Watches",
          style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Watches').snapshots(),
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
                    '$count items',
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
          // --- SEARCH BAR WITH BRAND FILTER ---
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                // Search by Name
                Container(
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
                      hintText: "Search watches by name...",
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
                        searchQuery = value.toLowerCase().trim();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                
                // Brand Filter Dropdown
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Brands')
                            .orderBy('brandName')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: kCardBlack,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: kPrimaryGold.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final brandNames = docs
                              .map((doc) => (doc.data() as Map<String, dynamic>)['brandName'] as String?)
                              .where((name) => name != null && name.isNotEmpty)
                              .map((name) => name!)
                              .toList();

                          return Container(
                            decoration: BoxDecoration(
                              color: kCardBlack,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: kPrimaryGold.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBrandFilter,
                                isExpanded: true,
                                dropdownColor: kCardBlack,
                                style: const TextStyle(color: Colors.white),
                                icon: Icon(Icons.arrow_drop_down, color: kPrimaryGold),
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "Filter by Brand",
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        "All Brands",
                                        style: TextStyle(color: kPrimaryGold),
                                      ),
                                    ),
                                  ),
                                  ...brandNames.map((name) {
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(name),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedBrandFilter = value;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (selectedBrandFilter != null || searchQuery.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: kCardBlack,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              selectedBrandFilter = null;
                              searchQuery = '';
                            });
                          },
                          icon: Icon(Icons.clear_all, color: Colors.red.shade400),
                          tooltip: 'Clear all filters',
                        ),
                      ),
                  ],
                ),
                
                // Active Filters Display
                if (selectedBrandFilter != null || searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (selectedBrandFilter != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimaryGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kPrimaryGold.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Brand: $selectedBrandFilter",
                                  style: const TextStyle(
                                    color: kPrimaryGold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedBrandFilter = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: kPrimaryGold,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (searchQuery.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimaryGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kPrimaryGold.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Search: $searchQuery",
                                  style: const TextStyle(
                                    color: kPrimaryGold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: kPrimaryGold,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
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
                    "NAME",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "BRAND",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
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
                Expanded(
                  flex: 2,
                  child: Text(
                    "PRICE",
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

          // --- LIST VIEW WITH CLIENT-SIDE FILTERING ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchAllWatches(),
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
                      "Error fetching data: ${snapshot.error}",
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.watch_rounded,
                          size: 64, 
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No watches available yet!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 🔥 Client-side filtering
                final allDocs = snapshot.data!.docs;
                final filteredDocs = _filterWatches(allDocs);

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No watches found matching your filters",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                              selectedBrandFilter = null;
                            });
                          },
                          child: Text(
                            "Clear all filters",
                            style: TextStyle(color: kPrimaryGold),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var watchDoc = filteredDocs[index];
                    var watch = watchDoc.data() as Map<String, dynamic>;
                    String docId = watchDoc.id;

                    String name = watch['name'] ?? 'No Name';
                    String brand = watch['brand'] ?? 'Unknown Brand';
                    String description = watch['description'] ?? 'No description available.';

                    var rawPrice = watch['price'];
                    String price = rawPrice != null ? rawPrice.toString() : '0.0';

                    List<dynamic> rawImages = watch['images'] ?? [];
                    String? firstImage = rawImages.isNotEmpty ? rawImages.first.toString() : null;
                    Uint8List? imageBytes = _safeDecode(firstImage);

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
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 84,
                                height: 84,
                                child: imageBytes != null
                                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: Icon(
                                          Icons.watch_rounded,
                                          color: kPrimaryGold.withOpacity(0.4),
                                          size: 32,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Brand
                            Expanded(
                              flex: 2,
                              child: Text(
                                brand,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryGold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Description
                            Expanded(
                              flex: 4,
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

                            // Price
                            Expanded(
                              flex: 2,
                              child: Text(
                                "\$$price",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimaryGold,
                                ),
                                maxLines: 1,
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
                                          _showEditDialog(context, docId, watch),
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