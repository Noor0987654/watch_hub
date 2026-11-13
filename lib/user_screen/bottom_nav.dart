import 'package:flutter/material.dart';
import 'package:watch_hub/user_screen/home.dart';
import 'package:watch_hub/user_screen/user_profile.dart';
import 'home.dart';    
import 'brands_screen.dart'; 

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  // 🎨 Luxury Watch Theme - Black + Gold/Amber
  static const Color kLuxuryBlack = Color(0xFF121212);
  static const Color kSurfaceBlack = Color(0xFF1E1E1E);
  static const Color kGoldAccent = Color(0xFFD4AF37); // Classic gold

  // 🌍 Pure User-Side Screens ki List
  final List<Widget> _screens = [
    const UserHomePage(),
    const BrandsScreen(),
    const WishlistPage(),
    const UserProfileScreen(),
  ];

  // 📝 App Bar ke Titles
  final List<String> _titles = [
    "DISCOVER TIMEPIECES ",
    "WATCH BRANDS",
    "MY WISHLIST",
    "MY PROFILE"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurfaceBlack,
        elevation: 0,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: kGoldAccent, // Gold title - luxury feel
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: kLuxuryBlack,

      // Current selected screen display hogi
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: kSurfaceBlack,
        selectedItemColor: kGoldAccent, // Luxury gold highlight
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 8,

        // 🛒 Pure User Navigation Items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.watch), 
            label: "EXPLORE"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.branding_watermark_outlined), 
            label: "BRANDS"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), 
            activeIcon: Icon(Icons.favorite, color: kGoldAccent), // Active hone par gold heart
            label: "WISHLIST"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            label: "PROFILE"
          ),
        ],
      ),
    );
  }
}