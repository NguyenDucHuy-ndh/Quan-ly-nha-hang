import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/menu_category.dart';

class FirestoreService {
  // FirestoreService class to handle Firestore operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to add a new user to the Firestore database
  Future<DocumentReference> addMenuCategory(MenuCategory menuCategory) async {
    try {
      return await _firestore
          .collection('menu_categories')
          .add(menuCategory.toMap());
    } catch (e) {
      print('Error adding menu category: $e');
      rethrow;
    }
  }

  Future<void> addMenuItem(
      String categoryId, Map<String, dynamic> menuItem) async {
    try {
      await _firestore
          .collection('menu_categories')
          .doc(categoryId)
          .collection('menu_items')
          .add(menuItem);
    } catch (e) {
      print('Error adding menu item: $e');
    }
  }
}
