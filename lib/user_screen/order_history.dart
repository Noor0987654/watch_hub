import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserOrderHistory extends StatefulWidget {
  const UserOrderHistory({super.key});

  @override
  State<UserOrderHistory> createState() => _UserOrderHistoryState();
}

class _UserOrderHistoryState extends State<UserOrderHistory> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gold Color
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBgBlack,
        elevation: 0,
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: kPrimaryGold,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
                        const SizedBox(height: 10),
                        Text(
                          'Error loading orders',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return _buildEmptyOrders();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildOrderCard(data, doc.id);
                  },
                );
              },
            ),
    );
  }

  // ========== NOT LOGGED IN ==========
  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Please Login First',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Login to view your orders',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // ========== EMPTY ORDERS ==========
  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start shopping to see your orders here!',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  // ========== ORDER CARD ==========
  Widget _buildOrderCard(Map<String, dynamic> data, String orderId) {
    final items = data['items'] as List? ?? [];
    final total = (data['total'] ?? 0).toDouble();
    final status = data['status'] ?? 'pending';
    final Timestamp? createdAt = data['createdAt'];

    // Status Color
    Color statusColor = status == 'pending'
        ? Colors.orange
        : status == 'accepted'
            ? Colors.green
            : status == 'shipped'
                ? Colors.blue
                : status == 'delivered'
                    ? Colors.purple
                    : status == 'rejected'
                        ? Colors.red
                        : Colors.grey;

    String statusIcon = status == 'pending'
        ? '⏳'
        : status == 'accepted'
            ? '✅'
            : status == 'shipped'
                ? '📦'
                : status == 'delivered'
                    ? '🏠'
                    : status == 'rejected'
                        ? '❌'
                        : '❓';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: kCardBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == 'pending' ? kPrimaryGold.withOpacity(0.3) : Colors.grey.shade800,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      statusIcon,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Order #${orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
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
            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  _formatDate(createdAt?.toDate() ?? DateTime.now()),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.watch, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  '${items.length} items',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
            const Divider(color: Colors.grey, height: 16),
            // Items (Max 2 show karein)
            ...items.take(2).map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.watch, size: 16, color: kPrimaryGold.withOpacity(0.5)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${item['quantity'] ?? 1}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: kPrimaryGold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            // Show more items text
            if (items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${items.length - 2} more items',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            const Divider(color: Colors.grey, height: 16),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kPrimaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== FORMAT DATE ==========
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}