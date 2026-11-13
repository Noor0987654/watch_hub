import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart' show VideoPlayerController, VideoPlayer;
import 'package:watch_hub/user_screen/Bestwatches_screen.dart';
import 'package:watch_hub/user_screen/NewArrival_screen.dart';
import 'package:watch_hub/user_screen/ai_stylist_screen.dart';
import 'package:watch_hub/user_screen/all_watches.dart' show AllWatchesPage;
import 'package:watch_hub/user_screen/brands_screen.dart';
import 'package:watch_hub/user_screen/order_history.dart';
import 'package:watch_hub/user_screen/user_login.dart';
import 'package:watch_hub/user_screen/user_review.dart';
import 'package:watch_hub/user_screen/watch_category_screen.dart';

import 'package:watch_hub/main.dart' show routeObserver;  // apna actual main.dart path daalna

// ============================================================
// ================= USER HOME PAGE ===========================
// ============================================================
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});
  static const String id = "UserHomePage";

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> with RouteAware, WidgetsBindingObserver {
  
  String searchQuery = '';
  String? selectedBrand;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ScrollController _bestSellersScrollController = ScrollController();
  final ScrollController _femaleScrollController = ScrollController();
 final ScrollController _maleScrollController = ScrollController();

 late VideoPlayerController _videoController;
 bool _isVideoInitialized = false;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _videoController = VideoPlayerController.asset('assesst/videos/promo_video.mp4')
    ..initialize().then((_) {
      if (mounted) {
        setState(() => _isVideoInitialized = true);
        _videoController.setLooping(true);
        _videoController.setVolume(0); // muted for autoplay to work reliably
        _videoController.play();
      }
    });
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    if (_isVideoInitialized && !_videoController.value.isPlaying) {
      _videoController.play();
    }
  } else if (state == AppLifecycleState.paused) {
    if (_isVideoInitialized) {
      _videoController.pause();
    }
  }
}

@override
void didPopNext() {
  if (_isVideoInitialized && !_videoController.value.isPlaying) {
    _videoController.play();
  }
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  routeObserver.unsubscribe(this);
  _bestSellersScrollController.dispose();
  _femaleScrollController.dispose();
  _maleScrollController.dispose();
  _videoController.dispose();
  super.dispose();
}
  // Current user
  User? get _currentUser => _auth.currentUser;

  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kDarkGold = Color(0xFFB8960F);
  static const Color kLightGold = Color(0xFFF5E6A3);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kTextGold = Color(0xFFD4AF37);

// ========== LOGIN REQUIRED DIALOG ==========
  void _showLoginDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: kPrimaryGold.withOpacity(0.3))),
        title: const Text('Login Required', style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserLogin()), 
              );
              // Yahan aap apni Login screen ka route ya push de sakte hain
            },
            child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ========== WISHLIST FUNCTIONS ==========

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
      print('Error checking wishlist: $e');
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
      print('Error: $e');
    }
  }
// Remove from wishlist
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
      print('Error: $e');
    }
  }

  // Toggle wishlist
  void _toggleWishlist(Map<String, dynamic> watch, String watchId) async {
    bool inWishlist = await _isInWishlist(watchId);
    if (inWishlist) {
      await _removeFromWishlist(watchId);
    } else {
      await _addToWishlist(watch, watchId);
    }
    setState(() {});
  }
  // ========== CART FUNCTIONS ==========
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
            .update({
          'quantity': currentQty + 1,
        });
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
      print('Error: $e');
    }
  }

  // ================= TOP BAR =================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kPrimaryGold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                _showMenuDrawer();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: kCardBlack,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimaryGold.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryGold.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search watches, brands ,categories...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: kPrimaryGold),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value.trim());
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Wishlist Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kCardBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryGold.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGold.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.favorite_border, color: kPrimaryGold),
                  onPressed: () {
                    _navigateToWishlist();
                  },
                ),
              ),
              // Wishlist count badge
              Positioned(
                top: 6,
                right: 6,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _currentUser != null
                      ? _firestore
                          .collection('Users')
                          .doc(_currentUser!.uid)
                          .collection('Wishlist')
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    int count = snapshot.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: kPrimaryGold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(width: 4),
          // Cart Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kCardBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryGold.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGold.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.shopping_cart_outlined, color: kPrimaryGold),
                  onPressed: () {
                    _navigateToCart();
                  },
                ),
              ),
              // Cart count badge
              Positioned(
                top: 6,
                right: 6,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _currentUser != null
                      ? _firestore
                          .collection('Users')
                          .doc(_currentUser!.uid)
                          .collection('Cart')
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    int count = snapshot.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: kPrimaryGold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== HELPER FUNCTIONS ==========
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kPrimaryGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  // ========== FETCH: SEARCH RESULTS (WITH CATEGORY) ==========
Future<List<QueryDocumentSnapshot>> _fetchSearchResults() async {
  if (searchQuery.isEmpty) return [];

  try {
    final allDocs = <QueryDocumentSnapshot>[];
    final seenIds = <String>{};

    // 1️⃣ Search by Name
    final nameQuery = await FirebaseFirestore.instance
        .collection('Watches')
        .where('name', isGreaterThanOrEqualTo: searchQuery)
        .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .orderBy('name')
        .get();

    for (final doc in nameQuery.docs) {
      if (!seenIds.contains(doc.id)) {
        seenIds.add(doc.id);
        allDocs.add(doc);
      }
    }

    // 2️⃣ Search by Brand
    final brandQuery = await FirebaseFirestore.instance
        .collection('Watches')
        .where('brand', isGreaterThanOrEqualTo: searchQuery)
        .where('brand', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .orderBy('brand')
        .get();

    for (final doc in brandQuery.docs) {
      if (!seenIds.contains(doc.id)) {
        seenIds.add(doc.id);
        allDocs.add(doc);
      }
    }

    // 3️⃣ 👇 NEW: Search by Category
    final searchLower = searchQuery.toLowerCase();
  final search = searchQuery.trim().toLowerCase();

if ([
  'male',
  'man',
  'men',
  'female',
  'woman',
  'women',
  'lady',
  'ladies',
  'unisex',
  'both'
].contains(search)) {

  String category = '';

  if (['male', 'man', 'men'].contains(search)) {
    category = 'Male';
  } else if (['female', 'woman', 'women', 'lady', 'ladies']
      .contains(search)) {
    category = 'Female';
  } else {
    category = 'Unisex';
  }

  final query = await FirebaseFirestore.instance
      .collection('Watches')
      .where('category', isEqualTo: category)
      .get();

  return query.docs;
}
    return allDocs;
  } catch (e) {
    print('Search error: $e');
    return [];
  }
}

  // ========== FETCH: NEW ARRIVALS ==========
  Stream<QuerySnapshot> _fetchNewArrivals() {
    Query query = FirebaseFirestore.instance
        .collection('Watches')
        .orderBy('dateAdded', descending: true);

    if (selectedBrand != null) {
      query = FirebaseFirestore.instance
          .collection('Watches')
          .where('brand', isEqualTo: selectedBrand)
          .orderBy('dateAdded', descending: true);
    }
    return query.limit(4).snapshots();
  }

  // ========== FETCH: BEST SELLERS ==========
  Stream<QuerySnapshot> _fetchBestSellers() {
    return FirebaseFirestore.instance
        .collection('Watches')
        .orderBy('price', descending: true)
        .limit(6)
        .snapshots();
  }

  // ========== FETCH: BRANDS ==========
  Stream<QuerySnapshot> _fetchBrands() {
    return FirebaseFirestore.instance
        .collection('Brands')
        .orderBy('brandName')
        .snapshots();
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

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: kBgBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: isSearching ? _buildSearchResults() : _buildHomeContent(),
            ),
          ],
        ),
      ),
    );
  }

 // ================= MENU DRAWER =================
  void _showMenuDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kPrimaryGold.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.person_outline, color: kPrimaryGold),
                    title: Text(
                      _currentUser?.displayName ?? 'Guest User',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _currentUser?.email ?? 'Not logged in',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: Icon(Icons.favorite_border, color: kPrimaryGold),
                    title: const Text('Wishlist', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToWishlist();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.shopping_cart_outlined, color: kPrimaryGold),
                    title: const Text('Cart', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToCart();
                    },
                  ),
                  // ========== 🔥 NEW: MY ORDERS OPTION ==========
                  ListTile(
                    leading: Icon(Icons.history_outlined, color: kPrimaryGold),
                    title: const Text('My Orders', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMyOrders();
                    },
                  ),
                  // ========== 🔥 NEW: REVIEWS OPTION ==========
                  ListTile(
                    leading: Icon(Icons.star_border_rounded, color: kPrimaryGold),
                    title: const Text('Reviews', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToReviews();
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: Icon(Icons.logout_outlined, color: Colors.red.shade400),
                    title: Text('Logout', style: TextStyle(color: Colors.red.shade400)),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= NAVIGATION FUNCTIONS =================
  void _navigateToWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WishlistPage()),
    );
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  // ========== 🔥 NEW: NAVIGATE TO MY ORDERS ==========
  void _navigateToMyOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserOrderHistory()),
    );
  }

  // ========== 🔥 NEW: NAVIGATE TO REVIEWS ==========
  void _navigateToReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReviewsPage()),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    _showSnackBar('Logged out successfully');
  }

// ================= HOME CONTENT =================
Widget _buildHomeContent() {
  return ListView(
    padding: const EdgeInsets.only(bottom: 20),
    children: [
      _buildQuickNav(),
      const SizedBox(height: 20),
      _buildPromoBanner(),
      const SizedBox(height: 26),
      
      // Best Selling
      _sectionHeader(
        "Best Selling Watches",
        onViewAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WatchesScreen()),
          );
        },
      ),
      const SizedBox(height: 12),
      _buildBestSellers(),
      const SizedBox(height: 26),
      
         // Browse by Brand (SAB SE NICHE)
   _sectionHeader(
  "Browse by Brand",
  onViewAll: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BrandsScreen()),
    );
  },
),
const SizedBox(height: 12),
_buildBrandChips(),

      // 👇 NEW ARRIVALS (UPAR)
      _sectionHeader(
        selectedBrand == null ? "New Arrivals" : "New Arrivals · $selectedBrand",
        onViewAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewArrivalsScreen()),
          );
        },
      ),
      const SizedBox(height: 12),
      _buildNewArrivals(),
      const SizedBox(height: 26),

       // 👇 NAYA VIDEO SECTION (New Arrivals ke neeche)
      _buildVideoSection(),
      const SizedBox(height: 26),
      
      // 👇 FEMALE WATCHES (NEW ARRIVALS KE NICHE)
      _sectionHeader(
        " Women's Watches",
        onViewAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryWatchesScreen(category: 'Female'),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      _buildFemaleWatches(),
      const SizedBox(height: 26),
      
      // 👇 MALE WATCHES (FEMALE KE NICHE)
      _sectionHeader(
        " Men's Watches",
        onViewAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryWatchesScreen(category: 'Male'),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      _buildMaleWatches(),
      const SizedBox(height: 26),
      
   
    ],
  );
}

// ========== FETCH: FEMALE WATCHES ==========
Stream<QuerySnapshot> _fetchFemaleWatches() {
  return FirebaseFirestore.instance
      .collection('Watches')
      .where('category', isEqualTo: 'Female')
      .limit(6)
      .snapshots();
}

// ========== FETCH: MALE WATCHES ==========
Stream<QuerySnapshot> _fetchMaleWatches() {
  return FirebaseFirestore.instance
      .collection('Watches')
      .where('category', isEqualTo: 'Male')
      .limit(6)
      .snapshots();
}

// ============================== FEMALE WATCHES SECTION ==============================
Widget _buildFemaleWatches() {
  return StreamBuilder<QuerySnapshot>(
    stream: _fetchFemaleWatches(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
            ),
          ),
        );
      }
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            "No Women's watches available",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        );
      }
      return Stack(
        children: [
          SizedBox(
            height: 230,
            child: ListView.separated(
              controller: _femaleScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final watch = docs[index].data() as Map<String, dynamic>;
                return SizedBox(
                  width: 150,
                  child: _watchMiniCard(watch, docs[index].id, isGrid: false),
                );
              },
            ),
          ),
          if (docs.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _scrollLeft(_femaleScrollController),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryGold.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: kPrimaryGold,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _scrollRight(_femaleScrollController),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryGold.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: kPrimaryGold,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
// ========== MALE WATCHES SECTION ==========
Widget _buildMaleWatches() {
  return StreamBuilder<QuerySnapshot>(
    stream: _fetchMaleWatches(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
            ),
          ),
        );
      }
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            "No Men's watches available",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        );
      }
      return Stack(
        children: [
          SizedBox(
            height: 230,
            child: ListView.separated(
              controller: _maleScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final watch = docs[index].data() as Map<String, dynamic>;
                return SizedBox(
                  width: 150,
                  child: _watchMiniCard(watch, docs[index].id, isGrid: false),
                );
              },
            ),
          ),
          if (docs.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _scrollLeft(_maleScrollController),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryGold.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: kPrimaryGold,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _scrollRight(_maleScrollController),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryGold.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: kPrimaryGold,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

  // ---- Quick Nav ----
Widget _buildQuickNav() {
  final items = [
    ("Best Sellers", Icons.emoji_events_outlined, WatchesScreen()),
    ("New Arrivals", Icons.fiber_new_outlined, NewArrivalsScreen()),
    ("Brands", Icons.branding_watermark_outlined, BrandsScreen()),
  ];

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: BoxDecoration(
      color: kCardBlack,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kPrimaryGold.withOpacity(0.2), width: 1),
      boxShadow: [
        BoxShadow(
          color: kPrimaryGold.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.$3),
            );
          },
          borderRadius: BorderRadius.circular(16), // optional, ripple effect shape
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryGold.withOpacity(0.2), width: 1),
                ),
                child: Icon(item.$2, color: kPrimaryGold, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                item.$1,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

  // ---- Promo Banner ----
// ---- Promo Banner ----
  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kPrimaryGold.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: kPrimaryGold.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Watch Stylist",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Find your perfect match for any occasion",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPrimaryGold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "AIMATCH",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIStylistScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.auto_awesome, 
                    color: Colors.black, 
                    size: 20,
                  ),
                  label: const Text(
                    "Try AI Stylist",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGold,
                    foregroundColor: Colors.black,
                    elevation: 6,
                    shadowColor: kPrimaryGold.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ✅ AI Stylist Right-Side Glowing Icon (Replacing the gift box)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: kPrimaryGold.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryGold.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: kPrimaryGold,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
  // ---- Section Header ----
Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimaryGold),
        ),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "View all",
                  style: TextStyle(color: kPrimaryGold, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, color: kPrimaryGold, size: 12),
              ],
            ),
          ),
      ],
    ),
  );
}

// ========== SCROLL HELPER METHODS ==========  <-- PUT THEM HERE
  void _scrollLeft(ScrollController controller) {
  if (controller.hasClients) {
    double currentOffset = controller.offset;
    double newOffset = currentOffset - 160;
    if (newOffset < 0) newOffset = 0;
    controller.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

void _scrollRight(ScrollController controller) {
  if (controller.hasClients) {
    double maxOffset = controller.position.maxScrollExtent;
    double currentOffset = controller.offset;
    double newOffset = currentOffset + 160;
    if (newOffset > maxOffset) newOffset = maxOffset;
    controller.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

  // ---- Best Sellers ----
Widget _buildBestSellers() {
  return StreamBuilder<QuerySnapshot>(
    stream: _fetchBestSellers(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold),
          ),
        );
      }
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) {
        return Center(
          child: Text(
            "No watches yet",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        );
      }
      
      return Stack(
        children: [
          // Horizontal ListView
          SizedBox(
            height: 220,
            child: ListView.separated(
              controller: _bestSellersScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final watch = docs[index].data() as Map<String, dynamic>;
                return SizedBox(
                  width: 140,
                  child: _watchMiniCard(watch, docs[index].id, isGrid: false),
                );
              },
            ),
          ),
          
          // Left Arrow Button
          if (docs.length > 1)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _scrollLeft(_bestSellersScrollController);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryGold.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: kPrimaryGold,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          
          // Right Arrow Button
          if (docs.length > 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _scrollRight(_bestSellersScrollController);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryGold.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: kPrimaryGold,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

  // ========== UPDATED: Watch Card with Wishlist & Cart ==========
Widget _watchMiniCard(Map<String, dynamic> watch, String watchId, {bool isGrid = false}) {
  String name = watch['name'] ?? 'No Name';
  String brand = watch['brand'] ?? 'Unknown';
  String category = watch['category'] ?? 'Unisex';
  var rawPrice = watch['price'];
  String price = rawPrice != null ? rawPrice.toString() : '0.0';
  List<dynamic> rawImages = watch['images'] ?? [];
  String? firstImage = rawImages.isNotEmpty ? rawImages.first.toString() : null;
  Uint8List? imageBytes = _safeDecode(firstImage);

double screenWidth = MediaQuery.of(context).size.width;
  bool isSmallScreen = screenWidth < 360;

  double imageHeight = isGrid ? (isSmallScreen ? 130 : 160) : 115;
  double cardWidth = isGrid ? double.infinity : (screenWidth * 0.38).clamp(130, 170);

  IconData categoryIcon = category == 'Male'
      ? Icons.male
      : category == 'Female'
          ? Icons.female
          : Icons.person_outline;

return Container(
  width: cardWidth,
  decoration: BoxDecoration(
    color: kCardBlack,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: kPrimaryGold.withOpacity(0.2), width: 1),
    boxShadow: [
      BoxShadow(color: kPrimaryGold.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // ✅ IMAGE - ab Expanded/flexible hai, fixed height nahi
      Expanded(
        flex: isGrid ? 3 : 2,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Container(
            width: double.infinity,
            color: Colors.grey.shade800,
            child: imageBytes != null
                ? Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackImage();
                    },
                  )
                : _buildFallbackImage(),
          ),
        ),
      ),
        // Details Section
        Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    categoryIcon,
                    color: category == 'Male'
                        ? Colors.blue
                        : category == 'Female'
                            ? Colors.pink
                            : kPrimaryGold,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: category == 'Male'
                          ? Colors.blue
                          : category == 'Female'
                              ? Colors.pink
                              : kPrimaryGold,
                    ),
                  ),
                  const Spacer(),
                  // Wishlist Button
                  FutureBuilder<bool>(
                    future: _isInWishlist(watchId),
                    builder: (context, snapshot) {
                      bool isFavorite = snapshot.data ?? false;
                      return GestureDetector(
                        onTap: () {
                          _toggleWishlist(watch, watchId);
                        },
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isFavorite ? Colors.red : kPrimaryGold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                brand,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "\$$price",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryGold,
                    ),
                  ),
                  const Spacer(),
                  // Add to Cart Button
                  SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () {
                        _addToCart(watch, watchId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

//   ==========          ==========//
  // ========== Brand Chips ==========
Widget _buildBrandChips() {
  return SizedBox(
    height: 92,
    child: StreamBuilder<QuerySnapshot>(
      stream: _fetchBrands(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("No brands added yet", style: TextStyle(color: Colors.grey.shade500)),
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final brand = docs[index].data() as Map<String, dynamic>;
            String brandName = brand['brandName'] ?? 'Brand';
            String brandId = docs[index].id;   // 👈 add kiya
            Uint8List? logoBytes = _safeDecode(brand['logo']);

            return GestureDetector(
              onTap: () {
                // 👇 ab filter set nahi karega, seedha navigate karega
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
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: kCardBlack,   // 👈 ab hamesha kCardBlack (koi "selected" state nahi)
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kPrimaryGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: logoBytes != null
                          ? Image.memory(logoBytes, fit: BoxFit.contain)
                          : Icon(Icons.branding_watermark_rounded,
                              color: kPrimaryGold, size: 24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 64,
                    child: Text(
                      brandName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

  // ---- New Arrivals ----
  Widget _buildNewArrivals() {
  return StreamBuilder<QuerySnapshot>(
    stream: _fetchNewArrivals(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGold))),
        );
      }
      if (snapshot.hasError) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Error fetching data", style: TextStyle(color: Colors.red)),
        );
      }
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Text("No watches found", style: TextStyle(color: Colors.grey.shade500)),
        );
      }

      double screenWidth = MediaQuery.of(context).size.width;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: docs.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: screenWidth < 360 ? 160 : 190, // chhoti screen pe zyada tight
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
        childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final watch = docs[index].data() as Map<String, dynamic>;
          return _watchMiniCard(watch, docs[index].id, isGrid: true);
        },
      );
    },
  );
}
  
  // ================= PROMO VIDEO SECTION =================
Widget _buildVideoSection() {
  final screenWidth = MediaQuery.of(context).size.width;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: screenWidth < 600 ? 300 : 380,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: kPrimaryGold.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: kPrimaryGold.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [

          //================ VIDEO =================
          _isVideoInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                )
              : Container(
                  color: kCardBlack,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        kPrimaryGold,
                      ),
                    ),
                  ),
                ),

          //================ GRADIENT =================
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),

          //================ TEXT =================
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
                        colors: [
                          Color(0xFFF5E6A3),
                          Color(0xFFD4AF37),
                        ],
                      ).createShader(bounds),
                  child: Text(
                    "Crafted for Elegance",
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Explore timepieces that define your style",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth < 600 ? 10 : 12,
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllWatchesPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGold,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 600 ? 16 : 22,
                      vertical: screenWidth < 600 ? 8 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "Shop Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
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
  );
}


  // ---- Search Results ----
  Widget _buildSearchResults() {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchSearchResults(),
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
              style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w500),
            ),
          );
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No watches found for '$searchQuery'",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try searching by watch name or brand",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final watch = docs[index].data() as Map<String, dynamic>;
            return _watchMiniCard(watch, docs[index].id, isGrid: true);
          },
        );
      },
    );
  }
}
// ============================================================
// ================= WISHLIST PAGE ============================
// ============================================================
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text('Wishlist', style: TextStyle(color: kPrimaryGold)),
        backgroundColor: kBgBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? _buildNotLoggedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('Users')
                  .doc(user.uid)
                  .collection('Wishlist')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyWishlist();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildWishlistItem(data, docs[index].id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Please login to view wishlist',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding your favorite watches!',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> data, String docId) {
    Uint8List? imageBytes;
    try {
      List<dynamic> images = data['images'] ?? [];
      if (images.isNotEmpty) {
        imageBytes = base64Decode(images.first.toString());
      }
    } catch (e) {
      imageBytes = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageBytes != null
                ? Image.memory(imageBytes, fit: BoxFit.cover)
                : Icon(Icons.watch, color: kPrimaryGold.withOpacity(0.3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  data['brand'] ?? 'Unknown',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                Text(
                  '\$${data['price']?.toString() ?? '0.0'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await _firestore
                  .collection('Users')
                  .doc(_auth.currentUser!.uid)
                  .collection('Wishlist')
                  .doc(docId)
                  .delete();
            },
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ================= CART PAGE ================================
// ============================================================
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text('Shopping Cart', style: TextStyle(color: kPrimaryGold)),
        backgroundColor: kBgBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? _buildNotLoggedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('Users')
                  .doc(user.uid)
                  .collection('Cart')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyCart();
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return _buildCartItem(data, docs[index].id);
                        },
                      ),
                    ),
                    _buildCheckoutButton(docs),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Please login to view cart',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Start shopping now!',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> data, String docId) {
    Uint8List? imageBytes;
    try {
      List<dynamic> images = data['images'] ?? [];
      if (images.isNotEmpty) {
        imageBytes = base64Decode(images.first.toString());
      }
    } catch (e) {
      imageBytes = null;
    }

    int quantity = data['quantity'] ?? 1;
    double price = (data['price'] ?? 0).toDouble();
    double total = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageBytes != null
                ? Image.memory(imageBytes, fit: BoxFit.cover)
                : Icon(Icons.watch, color: kPrimaryGold.withOpacity(0.3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  data['brand'] ?? 'Unknown',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                Row(
                  children: [
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${quantity}x)',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  if (quantity > 1) {
                    await _firestore
                        .collection('Users')
                        .doc(_auth.currentUser!.uid)
                        .collection('Cart')
                        .doc(docId)
                        .update({'quantity': quantity - 1});
                  } else {
                    await _firestore
                        .collection('Users')
                        .doc(_auth.currentUser!.uid)
                        .collection('Cart')
                        .doc(docId)
                        .delete();
                  }
                },
                icon: Icon(Icons.remove_circle_outline, color: kPrimaryGold),
              ),
              Text(
                '$quantity',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              IconButton(
                onPressed: () async {
                  await _firestore
                      .collection('Users')
                      .doc(_auth.currentUser!.uid)
                      .collection('Cart')
                      .doc(docId)
                      .update({'quantity': quantity + 1});
                },
                icon: Icon(Icons.add_circle_outline, color: kPrimaryGold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['price'] ?? 0).toDouble() * (data['quantity'] ?? 1);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBlack,
        border: Border(top: BorderSide(color: kPrimaryGold.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGold,
                  ),
                ),
                Text(
                  '${docs.length} items',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _showCheckoutDialog(total);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBlack,
        title: const Text('Confirm Order', style: TextStyle(color: kPrimaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Items will be delivered to your address.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _placeOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartDocs = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Cart')
          .get();

      if (cartDocs.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty!')),
        );
        return;
      }

      List<Map<String, dynamic>> items = [];
      double total = 0;
      for (var doc in cartDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double price = (data['price'] ?? 0).toDouble();
        int quantity = data['quantity'] ?? 1;
        items.add({
          'watchId': doc.id,
          'name': data['name'] ?? 'No Name',
          'brand': data['brand'] ?? 'Unknown',
          'price': price,
          'quantity': quantity,
        });
        total += price * quantity;
      }

      // Save order
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('Orders')
          .add({
        'items': items,
        'total': total,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear cart
      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }
}

// ============================================================
// ================= OLD ORDER HISTORY PAGE ===================
// ============================================================
// Note: Replace this with UserOrderHistory (above)
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(color: kPrimaryGold)),
        backgroundColor: kBgBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? _buildNotLoggedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('Users')
                  .doc(user.uid)
                  .collection('Orders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyOrders();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildOrderItem(data, docs[index].id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Please login to view orders',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Start shopping to see your orders here!',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> data, String docId) {
    List items = data['items'] ?? [];
    String status = data['status'] ?? 'pending';
    double total = (data['total'] ?? 0).toDouble();
    Timestamp? createdAt = data['createdAt'];

    Color statusColor = status == 'pending'
        ? Colors.orange
        : status == 'shipped'
            ? Colors.blue
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${docId.substring(0, 8)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${items.length} items',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          if (createdAt != null)
            Text(
              _formatDate(createdAt.toDate()),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          const Divider(color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}