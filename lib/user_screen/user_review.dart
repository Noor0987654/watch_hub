// ============================================================
// ================= REVIEWS PAGE ==============================
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  bool _isSubmitting = false;

  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  User? get _currentUser => _auth.currentUser;

  // ========== SUBMIT REVIEW ==========
  Future<void> _submitReview() async {
    if (_currentUser == null) {
      _showSnackBar('Please login first', isError: true);
      return;
    }
    if (_rating == 0) {
      _showSnackBar('Please select a rating', isError: true);
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar('Please write a review', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
   final userDoc = await _firestore
    .collection('Users')
    .doc(_currentUser!.uid)
    .get();

String userName = userDoc.data()?['name'] ?? 'Anonymous';

await _firestore.collection('Reviews').add({
  'userId': _currentUser!.uid,
  'userName': userName,
  'userEmail': _currentUser!.email ?? '',
  'rating': _rating,
  'comment': _commentController.text.trim(),
  'createdAt': FieldValue.serverTimestamp(),
});

      _commentController.clear();
      setState(() => _rating = 0);

      _showSnackBar('Review submitted successfully 🎉');
    } catch (e) {
      _showSnackBar('Error submitting review', isError: true);
      print('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : kPrimaryGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        title: const Text('Reviews', style: TextStyle(color: kPrimaryGold)),
        backgroundColor: kBgBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReviewForm(),
          const SizedBox(height: 26),
          const Text(
            'What people are saying',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: kPrimaryGold,
            ),
          ),
          const SizedBox(height: 12),
          _buildReviewsList(),
        ],
      ),
    );
  }

  // ========== REVIEW FORM ==========
  Widget _buildReviewForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryGold.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: kPrimaryGold.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share your experience with WatchHub',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),

          // ---- Star Rating Picker ----
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() => _rating = starIndex);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: kPrimaryGold,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _rating == 0 ? 'Tap to rate' : '$_rating / 5',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Comment Field ----
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryGold.withOpacity(0.25), width: 1),
            ),
            child: TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tell us about your experience...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Submit Button ----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== REVIEWS LIST ==========
  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No reviews yet. Be the first!',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildReviewCard(data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data) {
    int rating = data['rating'] ?? 0;
    String userName = data['userName'] ?? 'Anonymous';
    String comment = data['comment'] ?? '';
    Timestamp? createdAt = data['createdAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: kPrimaryGold.withOpacity(0.2),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(color: kPrimaryGold, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: kPrimaryGold,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(color: Colors.grey.shade300, fontSize: 13, height: 1.4),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatDate(createdAt.toDate()),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}