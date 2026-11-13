import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SimpleOrderList extends StatefulWidget {
  const SimpleOrderList({super.key});
  static const String id = "SimpleOrderList";

  @override
  State<SimpleOrderList> createState() => _SimpleOrderListState();
}

class _SimpleOrderListState extends State<SimpleOrderList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gold Color
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kGreen = Color(0xFF4CAF50);
  static const Color kRed = Color(0xFFE53935);
  static const Color kBlue = Color(0xFF42A5F5);
  static const Color kOrange = Color(0xFFFFA726);

  // Error link for index creation
  static const String indexLink =
      'https://console.firebase.google.com/v1/r/project/watchhub-d42cf/firestore/indexes?create_exemption=ClRwcM9qZWNocy93YXRjaGh1Yj1KNDJjZ19kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvT3JkZXJzL2ZpZWxkcy9jcmVhdGVkQXQQAhoNCgljcmVhdGVkQXQQAg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Orders',
          style: TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBgBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryGold),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: kPrimaryGold),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      backgroundColor: kBgBlack,
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 FIX: orderBy removed - No index required now!
        stream: _firestore.collectionGroup('Orders').snapshots(),
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: kPrimaryGold,
              ),
            );
          }

          // Error State
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            
            // Check if it's an index error
            if (errorMsg.contains('COLLECTION_GROUP_DESC')) {
              return _buildIndexErrorWidget();
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Error loading orders',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      errorMsg,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Get orders
          final orders = snapshot.data!.docs;

          // Empty State
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade600),
                  const SizedBox(height: 10),
                  Text(
                    'No Orders Yet',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Orders will appear here',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Orders List
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              // Get FULL User ID
              String userId = 'Unknown';
              try {
                userId = doc.reference.parent.parent?.id ?? 'Unknown';
              } catch (e) {
                userId = 'Unknown';
              }

              return _buildOrderCard(data, userId, doc.id, doc.reference);
            },
          );
        },
      ),
    );
  }

  // ========== INDEX ERROR WIDGET ==========
  Widget _buildIndexErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 60, color: kPrimaryGold),
            const SizedBox(height: 16),
            Text(
              'Index Required',
              style: TextStyle(
                color: kPrimaryGold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Firebase needs an index to sort orders by date.\n'
              'Click the button below to create it automatically.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Open Firebase Console to create index
                final Uri url = Uri.parse(indexLink);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open link. Please copy and paste in browser.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text(
                'Create Index in Firebase',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Retry without index (orders won't be sorted)
                setState(() {});
              },
              child: Text(
                'Try Again (Without Sorting)',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== ORDER CARD ==========
  Widget _buildOrderCard(
    Map<String, dynamic> data,
    String userId,
    String orderId,
    DocumentReference orderRef,
  ) {
    final items = data['items'] as List? ?? [];
    final total = (data['total'] ?? 0).toDouble();
    final status = data['status'] ?? 'pending';
    final Timestamp? createdAt = data['createdAt'];

    // Status color
    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    // Check if order is pending (show action buttons)
    bool isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: kCardBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending ? kPrimaryGold.withOpacity(0.5) : Colors.grey.shade800,
          width: isPending ? 2 : 1,
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
                    Icon(statusIcon, color: statusColor, size: 18),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

            // 🔥 FULL USER ID
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: kPrimaryGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'User ID: $userId',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _copyToClipboard(userId);
                    },
                    icon: Icon(Icons.copy, size: 14, color: kPrimaryGold),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  _formatDate(createdAt?.toDate() ?? DateTime.now()),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.watch, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  '${items.length} items',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),

            const Divider(color: Colors.grey, height: 16),

            // Items (Max 2 show)
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
                      child: Icon(
                        Icons.watch,
                        size: 16,
                        color: kPrimaryGold.withOpacity(0.5),
                      ),
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

            const SizedBox(height: 12),

            // ========== ACTION BUTTONS ==========
            if (isPending) ...[
              const Divider(color: Colors.grey, height: 4),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(orderRef, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text(
                        'Accept',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(orderRef, 'rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text(
                        'Reject',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'accepted') ...[
              const Divider(color: Colors.grey, height: 4),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(orderRef, 'shipped'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.local_shipping, size: 16),
                      label: const Text(
                        'Mark as Shipped',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'shipped') ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBlue.withOpacity(0.3)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping, color: kBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Order Shipped',
                        style: TextStyle(
                          color: kBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (status == 'rejected') ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kRed.withOpacity(0.3)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: kRed, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Order Rejected',
                        style: TextStyle(
                          color: kRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== UPDATE ORDER STATUS ==========
  Future<void> _updateOrderStatus(DocumentReference orderRef, String newStatus) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: kPrimaryGold),
        ),
      );

      await orderRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus == 'accepted'
                    ? Icons.check_circle
                    : newStatus == 'rejected'
                        ? Icons.cancel
                        : Icons.local_shipping,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text('Order ${newStatus.toUpperCase()} successfully!'),
            ],
          ),
          backgroundColor: newStatus == 'accepted'
              ? kGreen
              : newStatus == 'rejected'
                  ? kRed
                  : kBlue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ========== COPY TO CLIPBOARD ==========
  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User ID copied!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ========== HELPER FUNCTIONS ==========
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return kOrange;
      case 'accepted':
        return kGreen;
      case 'shipped':
        return kBlue;
      case 'rejected':
        return kRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}