import 'package:cloud_firestore/cloud_firestore.dart';

class AIWatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List> getFilteredWatches({
    required String selectedCategory,
    required String selectedOccasion,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Watches').get();
      
      var allWatches = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>);
        data['watchId'] = doc.id;
        return data;
      }).toList();

      // 1. Category Filter
      var filteredList = allWatches.where((watch) {
        if (selectedCategory == 'All') return true;
        String category = (watch['category'] ?? '').toString();
        return category.toLowerCase() == selectedCategory.toLowerCase();
      }).toList();

      // 2. AI Occasion Filter
      if (selectedOccasion != 'All') {
        filteredList = filteredList.where((watch) {
          String name = (watch['name'] ?? '').toString().toLowerCase();
          String brand = (watch['brand'] ?? '').toString().toLowerCase();

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

      return filteredList;
    } catch (e) {
      print('AI Filtering Error: $e');
      return [];
    }
  }
}