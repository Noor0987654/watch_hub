import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/user_screen/user_login.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kBgBlack = Color(0xFF0A0A0A);

  Stream<QuerySnapshot> _fetchBrands() {
    return FirebaseFirestore.instance
        .collection('Brands')
        .orderBy('brandName')
        .snapshots();
  }

  Uint8List? _safeDecode(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text(
          "Watch Brands",
          style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBgBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryGold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchBrands(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading brands",
                    style: TextStyle(color: Colors.red.shade400, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.branding_watermark_rounded, size: 64, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  Text(
                    "No brands available",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: MediaQuery.of(context).size.width < 360 ? 165 : 195,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final brandData = docs[index].data() as Map<String, dynamic>;
              final brandName = brandData['brandName'] ?? 'Unknown';
              final brandId = docs[index].id;
              
              String? brandLogo = brandData['Logo'] as String?;
              if (brandLogo == null) {
                brandLogo = brandData['logo'] as String?;
              }
              
              Uint8List? logoBytes = _safeDecode(brandLogo);

              return Container(
                decoration: BoxDecoration(
                  color: kCardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kPrimaryGold.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGold.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BrandWatchesScreen(
                            brandName: brandName,
                            brandId: brandId,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kPrimaryGold.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: logoBytes != null
                                    ? Image.memory(
                                        logoBytes,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildFallbackLogo();
                                        },
                                      )
                                    : _buildFallbackLogo(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              brandName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryGold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.collections_bookmark_rounded,
                                  color: Colors.black,
                                  size: 10,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  "View Collection",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Icon(
          Icons.branding_watermark_rounded,
          color: kPrimaryGold.withOpacity(0.5),
          size: 35,
        ),
      ),
    );
  }
}

/// ============================================================
// ================= BRAND WATCHES SCREEN ====================
// ============================================================
class BrandWatchesScreen extends StatefulWidget {
  final String brandName;
  final String brandId;

  const BrandWatchesScreen({
    super.key,
    required this.brandName,
    required this.brandId,
  });

  @override
  State<BrandWatchesScreen> createState() => _BrandWatchesScreenState();
}

class _BrandWatchesScreenState extends State<BrandWatchesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get _currentUser => _auth.currentUser;

  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kBgBlack = Color(0xFF0A0A0A);

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

  // ========== LOGIN REQUIRED DIALOG ==========
  void _showLoginDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: kPrimaryGold.withOpacity(0.3)),
        ),
        title: const Text(
          'Login Required',
          style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context); // Dialog band karein
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserLogin()), 
              );
            },
            child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
      _showLoginDialog('Please login to add items to your wishlist.');
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
      _showLoginDialog('Please login to add items to your cart.');
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
        backgroundColor: kBgBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.brandName,
          style: const TextStyle(
            color: kPrimaryGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Watches')
            .where('brand', isEqualTo: widget.brandName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading watches",
                    style: TextStyle(color: Colors.red.shade400, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
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
                    "No watches available for ${widget.brandName}",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: MediaQuery.of(context).size.width < 360 ? 165 : 195,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final watchId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildWatchCard(data, watchId);
            },
          );
        },
      ),
    );
  }

  Widget _buildWatchCard(Map<String, dynamic> watch, String watchId) {
    String name = watch['name'] ?? 'No Name';
    String brand = watch['brand'] ?? 'Unknown';
    String category = watch['category'] ?? 'Unisex';
    var rawPrice = watch['price'];
    String price = rawPrice != null ? rawPrice.toString() : '0.0';

    List<dynamic> rawImages = watch['images'] ?? [];
    String? firstImage = rawImages.isNotEmpty ? rawImages.first.toString() : null;
    Uint8List? imageBytes = _safeDecode(firstImage);

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