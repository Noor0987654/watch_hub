// ============================================================
// =================== AI STYLIST SCREEN ======================
// ============================================================
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIStylistScreen extends StatefulWidget {
  const AIStylistScreen({super.key});

  @override
  State<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends State<AIStylistScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  String selectedCategory = 'All'; // 'All', 'Male', 'Female'
  String selectedOccasion = 'All'; // 'All', 'Formal / Wedding', 'Casual / Daily', 'Sport'

  final List<String> categories = ['All', 'Male', 'Female'];
  final List<String> occasions = ['All', 'Formal / Wedding', 'Casual / Daily', 'Sport'];

  // Theme Colors
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kBgBlack = Color(0xFF0A0A0A);

  // ========== DECODE IMAGE ==========
  Uint8List? _safeDecode(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kPrimaryGold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= WISHLIST LOGIC =================
  Future<bool> _isInWishlist(String watchId) async {
    if (_currentUser == null) return false;
    try {
      final doc = await _firestore
          .collection('Users')
          .doc(_currentUser!.uid)
          .collection('Wishlist')
          .doc(watchId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addToWishlist(Map<String, dynamic> watch, String watchId) async {
    if (_currentUser == null) {
      _showSnackBar('Please login first');
      return;
    }
    try {
      await _firestore
          .collection('Users')
          .doc(_currentUser!.uid)
          .collection('Wishlist')
          .doc(watchId)
          .set({
        'watchId': watchId,
        'name': watch['name'] ?? 'No Name',
        'brand': watch['brand'] ?? 'Unknown',
        'price': watch['price'] ?? 0,
        'images': watch['images'] ?? [],
        'addedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('Added to wishlist ❤️');
    } catch (e) {
      _showSnackBar('Error adding to wishlist');
    }
  }

  Future<void> _removeFromWishlist(String watchId) async {
    if (_currentUser == null) return;
    try {
      await _firestore
          .collection('Users')
          .doc(_currentUser!.uid)
          .collection('Wishlist')
          .doc(watchId)
          .delete();
      _showSnackBar('Removed from wishlist');
    } catch (e) {
      _showSnackBar('Error removing from wishlist');
    }
  }

  void _toggleWishlist(Map<String, dynamic> watch, String watchId) async {
    bool inWishlist = await _isInWishlist(watchId);
    if (inWishlist) {
      await _removeFromWishlist(watchId);
    } else {
      await _addToWishlist(watch, watchId);
    }
    setState(() {});
  }

  // ================= CART LOGIC =================
  Future<void> _addToCart(Map<String, dynamic> watch, String watchId) async {
    if (_currentUser == null) {
      _showSnackBar('Please login first');
      return;
    }
    try {
      final cartDoc = await _firestore
          .collection('Users')
          .doc(_currentUser!.uid)
          .collection('Cart')
          .doc(watchId)
          .get();

      if (cartDoc.exists) {
        int currentQty = cartDoc.data()?['quantity'] ?? 0;
        await _firestore
            .collection('Users')
            .doc(_currentUser!.uid)
            .collection('Cart')
            .doc(watchId)
            .update({'quantity': currentQty + 1});
      } else {
        await _firestore
            .collection('Users')
            .doc(_currentUser!.uid)
            .collection('Cart')
            .doc(watchId)
            .set({
          'watchId': watchId,
          'name': watch['name'] ?? 'No Name',
          'brand': watch['brand'] ?? 'Unknown',
          'price': watch['price'] ?? 0,
          'images': watch['images'] ?? [],
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      _showSnackBar('Added to cart 🛒');
    } catch (e) {
      _showSnackBar('Error adding to cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text(
          "AI Watch Stylist & Occasion Matcher",
          style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: kBgBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryGold),
      ),
      body: Column(
        children: [
          // Filter Chips Section (Category & AI Occasion)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Gender Category:",
                  style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((cat) {
                      bool isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: kPrimaryGold,
                          backgroundColor: kCardBlack,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? kPrimaryGold : kPrimaryGold.withOpacity(0.3),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "AI Occasion Matcher:",
                  style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: occasions.map((occ) {
                      bool isSelected = selectedOccasion == occ;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(occ),
                          selected: isSelected,
                          selectedColor: kPrimaryGold,
                          backgroundColor: kCardBlack,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? kPrimaryGold : kPrimaryGold.withOpacity(0.3),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              selectedOccasion = occ;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Firebase StreamBuilder with Smart AI Filtering & Responsive Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Watches')
                  .orderBy('dateAdded', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryGold),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading watches",
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No watches available in Firebase",
                      style: TextStyle(color: Colors.white.withOpacity(0.54)),
                    ),
                  );
                }

                var watchDocs = snapshot.data!.docs;

                // 1. Filter by Category (Male / Female)
                if (selectedCategory != 'All') {
                  watchDocs = watchDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String cat = (data['category'] ?? '').toString();
                    return cat.toLowerCase() == selectedCategory.toLowerCase();
                  }).toList();
                }

                // 2. AI Occasion Filtering Logic based on Watch Name/Brand keywords
                if (selectedOccasion != 'All') {
                  watchDocs = watchDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    String brand = (data['brand'] ?? '').toString().toLowerCase();

                    if (selectedOccasion == 'Formal / Wedding') {
                      return name.contains('classic') || 
                             name.contains('gold') || 
                             name.contains('leather') || 
                             name.contains('luxury') ||
                             brand.contains('rolex');
                    } else if (selectedOccasion == 'Casual / Daily') {
                      return name.contains('simple') || 
                             name.contains('casual') || 
                             name.contains('steel') ||
                             !name.contains('sport');
                    } else if (selectedOccasion == 'Sport') {
                      return name.contains('sport') || 
                             name.contains('chronograph') || 
                             name.contains('rubber') ||
                             name.contains('digital');
                    }
                    return true;
                  }).toList();
                }

                if (watchDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 60, color: kPrimaryGold.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          "No AI matches found for this filter",
                          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.54)),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.of(context).size.width < 360 ? 165 : 195,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.68, // Exact matching aspect ratio from AllWatchesPage
                  ),
                  itemCount: watchDocs.length,
                  itemBuilder: (context, index) {
                    var watchDoc = watchDocs[index];
                    var watch = watchDoc.data() as Map<String, dynamic>;
                    String watchId = watchDoc.id;

                    return _buildWatchCard(watch, watchId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchCard(Map<String, dynamic> watch, String watchId) {
    String name = watch['name'] ?? 'No Name';
    String brand = watch['brand'] ?? 'Unknown';
    String category = watch['category'] ?? 'Unisex';
    var rawPrice = watch['price'];
    String price = rawPrice != null ? rawPrice.toString() : '0.0';

    // Get image from images array
    List<dynamic> rawImages = watch['images'] ?? [];
    String? firstImage = rawImages.isNotEmpty ? rawImages.first.toString() : null;
    Uint8List? imageBytes = _safeDecode(firstImage);

    // Category icon
    IconData categoryIcon = category == 'Male'
        ? Icons.male
        : category == 'Female'
            ? Icons.female
            : Icons.person_outline;

    return Container(
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ IMAGE SECTION WITH WISHLIST + PRICE + CATEGORY
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey.shade800,
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackImage();
                            },
                          )
                        : _buildFallbackImage(),
                  ),
                ),
                // Category Badge (Top Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: category == 'Male'
                            ? Colors.blue.withOpacity(0.5)
                            : category == 'Female'
                                ? Colors.pink.withOpacity(0.5)
                                : kPrimaryGold.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcon,
                          color: category == 'Male'
                              ? Colors.blue
                              : category == 'Female'
                                  ? Colors.pink
                                  : kPrimaryGold,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: category == 'Male'
                                ? Colors.blue
                                : category == 'Female'
                                    ? Colors.pink
                                    : kPrimaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Price Tag (Bottom Left)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimaryGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "\$$price",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                // Wishlist Icon (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: FutureBuilder<bool>(
                    future: _isInWishlist(watchId),
                    builder: (context, snap) {
                      bool isFavorite = snap.data ?? false;
                      return GestureDetector(
                        onTap: () => _toggleWishlist(watch, watchId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // ✅ DETAILS SECTION WITH ADD TO CART BUTTON
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        brand,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(watch, watchId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(
          Icons.watch_rounded,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }
}