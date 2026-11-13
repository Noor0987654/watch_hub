import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:watch_hub/Admin/Addproduct.dart';
import 'package:watch_hub/Admin/Admin_login.dart';
import 'package:watch_hub/Admin/OrderList.dart';
import 'package:watch_hub/Admin/Viewproduct.dart';
import 'package:watch_hub/Admin/add_brand.dart';
import 'package:watch_hub/Admin/dashboard.dart';
import 'package:watch_hub/Admin/review_list.dart';
import 'package:watch_hub/Admin/user_list.dart';
import 'package:watch_hub/Admin/view_brand.dart';

class WebMain extends StatefulWidget {
  static const String id = "web_main";
  const WebMain({super.key});

  @override
  State<WebMain> createState() => _WebMainState();
}

class _WebMainState extends State<WebMain> {
  // ---- Theme colors (Luxury Black & Gold) ----
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);

  Widget selectedScreen = const Dashboard();
  String selectedRoute = Dashboard.id;

  // Track expanded states for dropdowns
  bool _isProductsExpanded = false;
  bool _isBrandsExpanded = false;
  bool _isReviewsExpanded = false;

  void choosenScreen(String? route) {
    setState(() {
      selectedRoute = route ?? Dashboard.id;
      switch (route) {
        case Dashboard.id:
          selectedScreen = const Dashboard();
          break;
        case AddWatch.id:
          selectedScreen = const AddWatch();
          break;
        case ViewWatches.id:
          selectedScreen = const ViewWatches();
          break;
        case BrandFormPage.id:
          selectedScreen = const BrandFormPage();
          break;
        case ViewBrands.id:
          selectedScreen = const ViewBrands();
          break;
        case SimpleOrderList.id:
          selectedScreen = const SimpleOrderList();
          break;
        case AdminUsersPage.id:
          selectedScreen = const AdminUsersPage();
          break;
        case AdminReviewsList.id:
          selectedScreen = const AdminReviewsList();
          break;
        default:
          selectedScreen = const Dashboard();
      }
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kPrimaryGold.withOpacity(0.3), width: 1),
          ),
          title: const Text(
            'Logout Confirmation',
            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Custom sidebar with dropdown support
  Widget _buildCustomSidebar() {
    return Container(
      color: kBgBlack,
      width: 280,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: kPrimaryGold.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kPrimaryGold.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(Icons.admin_panel_settings, color: kPrimaryGold, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Admin Panel",
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Dashboard
                  _buildSidebarItem(
                    title: "Dashboard",
                    icon: Icons.dashboard,
                    route: Dashboard.id,
                    isActive: selectedRoute == Dashboard.id,
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  
                  // Products Dropdown
                  _buildDropdownItem(
                    title: "Products",
                    icon: Icons.inventory_2_outlined,
                    isExpanded: _isProductsExpanded,
                    children: [
                      {'title': 'Add Product', 'route': AddWatch.id, 'icon': Icons.add_box_outlined},
                      {'title': 'View Products', 'route': ViewWatches.id, 'icon': Icons.list_alt},
                    ],
                  ),
                  
                  // Brands Dropdown
                  _buildDropdownItem(
                    title: "Brands",
                    icon: Icons.branding_watermark_outlined,
                    isExpanded: _isBrandsExpanded,
                    children: [
                      {'title': 'Add Brand', 'route': BrandFormPage.id, 'icon': Icons.add_box_outlined},
                      {'title': 'View Brands', 'route': ViewBrands.id, 'icon': Icons.list_alt},
                    ],
                  ),
                  
                  // Reviews Dropdown
                  _buildDropdownItem(
                    title: "Reviews",
                    icon: Icons.star_outline,
                    isExpanded: _isReviewsExpanded,
                    children: [
                      {'title': 'All Reviews', 'route': AdminReviewsList.id, 'icon': Icons.list},
                    ],
                  ),
                  
                  // Orders
                  _buildSidebarItem(
                    title: "Orders",
                    icon: Icons.shopping_cart_outlined,
                    route: SimpleOrderList.id,
                    isActive: selectedRoute == SimpleOrderList.id,
                  ),
                  
                  // Users
                  _buildSidebarItem(
                    title: "Users",
                    icon: Icons.people_outline,
                    route: AdminUsersPage.id,
                    isActive: selectedRoute == AdminUsersPage.id,
                  ),
                  
                  const Divider(color: Colors.white12, height: 20),
                  
                  // Logout
                  _buildSidebarItem(
                    title: "Logout",
                    icon: Icons.logout,
                    route: "logout",
                    isActive: false,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required String title,
    required IconData icon,
    required String route,
    required bool isActive,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : (isActive ? kPrimaryGold : Colors.white54),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : (isActive ? kPrimaryGold : Colors.white70),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      tileColor: isActive ? kPrimaryGold.withOpacity(0.15) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        if (isLogout) {
          _logout();
        } else {
          choosenScreen(route);
        }
      },
    );
  }

  Widget _buildDropdownItem({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required List<Map<String, dynamic>> children,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white54, size: 22),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white54,
            size: 20,
          ),
          onTap: () {
            setState(() {
              if (title == "Products") {
                _isProductsExpanded = !_isProductsExpanded;
                _isBrandsExpanded = false;
                _isReviewsExpanded = false;
              } else if (title == "Brands") {
                _isBrandsExpanded = !_isBrandsExpanded;
                _isProductsExpanded = false;
                _isReviewsExpanded = false;
              } else if (title == "Reviews") {
                _isReviewsExpanded = !_isReviewsExpanded;
                _isProductsExpanded = false;
                _isBrandsExpanded = false;
              }
            });
          },
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: children.map((child) {
                final childRoute = child['route'] as String;
                final isChildActive = selectedRoute == childRoute;

                return ListTile(
                  leading: Icon(
                    child['icon'] as IconData,
                    color: isChildActive ? kPrimaryGold : Colors.white38,
                    size: 20,
                  ),
                  title: Text(
                    child['title'] as String,
                    style: TextStyle(
                      color: isChildActive ? kPrimaryGold : Colors.white60,
                      fontWeight: isChildActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  tileColor: isChildActive ? kPrimaryGold.withOpacity(0.1) : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    choosenScreen(childRoute);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: kBgBlack,
        elevation: 2,
        shadowColor: kPrimaryGold.withOpacity(0.2),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimaryGold.withOpacity(0.3), width: 1),
              ),
              child: Icon(Icons.admin_panel_settings, color: kPrimaryGold, size: 26),
            ),
            const SizedBox(width: 12),
            const Text(
              "ADMIN MANAGEMENT",
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: kPrimaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: kPrimaryGold.withOpacity(0.2), width: 1),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none, color: kPrimaryGold),
              onPressed: () {},
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: kPrimaryGold.withOpacity(0.1),
              child: Icon(Icons.person, color: kPrimaryGold, size: 20),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kPrimaryGold.withOpacity(0.2)),
        ),
      ),
      body: Row(
        children: [
          // Custom Sidebar
          _buildCustomSidebar(),
          // Main Content
          Expanded(
            child: selectedScreen,
          ),
        ],
      ),
    );
  }
}