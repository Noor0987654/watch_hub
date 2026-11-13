import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub/Admin/Add_brand.dart';
import 'package:watch_hub/Admin/Addproduct.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  static const String id = "dashboard";

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // ---- Theme colors (Luxury Black & Gold) ----
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);

  // ---- Stats Values ----
  int _totalWatches = 0;
  int _totalBrands = 0;
  int _totalUsers = 0;
  int _totalOrders = 0;
  int _todayOrders = 0;

  // ---- Chart Data ----
  List<FlSpot> _salesData = [];
  List<PieChartSectionData> _categoryData = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final watches = await FirebaseFirestore.instance.collection('Watches').get();
      final brands = await FirebaseFirestore.instance.collection('Brands').get();
      final users = await FirebaseFirestore.instance.collection('Users').get();
      final orders = await FirebaseFirestore.instance.collection('Orders').get();

      setState(() {
        _totalWatches = watches.docs.length;
        _totalBrands = brands.docs.length;
        _totalUsers = users.docs.length;
        _totalOrders = orders.docs.length;

        int todayCount = 0;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        for (var doc in orders.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final date = createdAt.toDate();
            final orderDate = DateTime(date.year, date.month, date.day);
            if (orderDate == today) {
              todayCount++;
            }
          }
        }
        _todayOrders = todayCount;
      });

      _fetchCategoryData();
      _fetchSalesData();
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  Future<void> _fetchCategoryData() async {
    try {
      final watches = await FirebaseFirestore.instance.collection('Watches').get();
      Map<String, int> categoryCount = {};
      for (var doc in watches.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] ?? 'Unisex';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      final colors = [kPrimaryGold, Colors.blue, Colors.pink, Colors.green, Colors.orange];
      int index = 0;
      setState(() {
        _categoryData = categoryCount.entries.map((entry) {
          final color = colors[index % colors.length];
          index++;
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.key}\n${entry.value}',
            color: color,
            radius: 80,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        }).toList();
      });
    } catch (e) {
      print('Error fetching category data: $e');
    }
  }

  Future<void> _fetchSalesData() async {
    try {
      final orders = await FirebaseFirestore.instance
          .collection('Orders')
          .orderBy('createdAt', descending: false)
          .get();

      Map<String, double> dailySales = {};
      final now = DateTime.now();

      for (var i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(date);
        dailySales[key] = 0.0;
      }

      for (var doc in orders.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          final key = DateFormat('yyyy-MM-dd').format(date);
          if (dailySales.containsKey(key)) {
            dailySales[key] = (dailySales[key] ?? 0) + (data['total'] ?? 0).toDouble();
          }
        }
      }

      final entries = dailySales.entries.toList();
      setState(() {
        _salesData = entries.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.value);
        }).toList();
      });
    } catch (e) {
      print('Error fetching sales data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),

              // ---- STATS ----
              _buildQuickStats(),
              const SizedBox(height: 20),

              // ---- CHARTS ROW ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildSalesChart(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildCategoryPieChart(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildRecentOrders(),
              const SizedBox(height: 20),

              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kPrimaryGold,
              ),
            ),
            Text(
              'Welcome back, Admin 👋',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCardBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryGold.withOpacity(0.2)),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: kPrimaryGold,
            size: 26,
          ),
        ),
      ],
    );
  }

  // ==================== QUICK STATS ====================
  Widget _buildQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _statCard('Total Watches', _totalWatches, Icons.watch_rounded, Colors.blue),
        _statCard('Total Brands', _totalBrands, Icons.storefront_rounded, Colors.green),
        _statCard('Total Users', _totalUsers, Icons.people_alt_rounded, Colors.orange),
        _statCard('Total Orders', _totalOrders, Icons.shopping_bag_rounded, Colors.purple),
        _statCard('Today Orders', _todayOrders, Icons.today_rounded, Colors.teal),
      ],
    );
  }

  Widget _statCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 44),
              const Spacer(),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SALES CHART ====================
  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Sales Overview (Last 7 Days)',
            style: TextStyle(
              color: kPrimaryGold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _salesData.isEmpty
              ? Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: const Text(
                    'No sales data',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _salesData,
                          isCurved: true,
                          color: kPrimaryGold,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: kPrimaryGold.withOpacity(0.15),
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

  // ==================== CATEGORY PIE CHART ====================
  Widget _buildCategoryPieChart() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Categories',
            style: TextStyle(
              color: kPrimaryGold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _categoryData.isEmpty
              ? Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const Text(
                    'No data',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: _categoryData,
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ==================== RECENT ORDERS ====================
  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📦 Recent Orders',
                style: TextStyle(
                  color: kPrimaryGold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(color: kPrimaryGold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Orders')
                .orderBy('createdAt', descending: true)
                .limit(5)
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

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text(
                  'No orders yet',
                  style: TextStyle(color: Colors.grey.shade500),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final items = data['items'] as List? ?? [];
                  final total = (data['total'] ?? 0).toDouble();
                  final status = data['status'] ?? 'pending';
                  final createdAt = data['createdAt'] as Timestamp?;

                  Color statusColor = status == 'pending'
                      ? Colors.orange
                      : status == 'shipped'
                          ? Colors.blue
                          : Colors.green;

                  return _orderItem(
                    'Order #${doc.id.substring(0, 8)}',
                    '${items.length} items',
                    '\$${total.toStringAsFixed(2)}',
                    status,
                    statusColor,
                    createdAt != null
                        ? DateFormat('dd MMM, hh:mm a').format(createdAt.toDate())
                        : 'Just now',
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _orderItem(String id, String items, String total, String status, Color statusColor, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              id,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              items,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              total,
              style: const TextStyle(color: kPrimaryGold, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS ====================
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Quick Actions',
            style: TextStyle(
              color: kPrimaryGold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionButton(
                Icons.add_box_rounded,
                'Add Watch',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddWatch()),
                  );
                },
              ),
              const SizedBox(width: 12),
              _actionButton(
                Icons.branding_watermark_rounded,
                'Add Brand',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BrandFormPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: kPrimaryGold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryGold.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: kPrimaryGold, size: 34),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}