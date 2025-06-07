import 'package:cloud_firestore/cloud_firestore.dart';

class TableMergeUtils {
  /// Gộp các bàn vào một bàn chính
  static Future<void> mergeTablesAndOrders(
      String mainTableId, List<String> tableIdsToMerge) async {
    final firestore = FirebaseFirestore.instance;

    // Lấy order chưa thanh toán của bàn chính (nếu có)
    QuerySnapshot mainOrderSnap = await firestore
        .collection('orders')
        .where('tableId', isEqualTo: mainTableId)
        .where('isPaid', isEqualTo: false)
        .limit(1)
        .get();

    String mainOrderId;
    if (mainOrderSnap.docs.isEmpty) {
      // Nếu chưa có order, tạo mới
      DocumentReference newOrder = await firestore.collection('orders').add({
        'tableId': mainTableId,
        'isPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      mainOrderId = newOrder.id;
    } else {
      mainOrderId = mainOrderSnap.docs.first.id;
    }

    // Lặp qua từng bàn phụ
    for (String tableId in tableIdsToMerge) {
      // Lấy order chưa thanh toán của bàn phụ
      QuerySnapshot subOrderSnap = await firestore
          .collection('orders')
          .where('tableId', isEqualTo: tableId)
          .where('isPaid', isEqualTo: false)
          .limit(1)
          .get();

      if (subOrderSnap.docs.isNotEmpty) {
        String subOrderId = subOrderSnap.docs.first.id;
        // Lấy các món trong order phụ
        QuerySnapshot itemsSnap = await firestore
            .collection('orders')
            .doc(subOrderId)
            .collection('items')
            .get();

        // Thêm từng món vào order bàn chính
        for (var itemDoc in itemsSnap.docs) {
          await firestore
              .collection('orders')
              .doc(mainOrderId)
              .collection('items')
              .add(itemDoc.data() as Map<String, dynamic>); // <-- SỬA DÒNG NÀY
        }

        // Xóa order phụ
        await firestore.collection('orders').doc(subOrderId).delete();
      }
    }

    // Cập nhật mergedTableIds như cũ
    await firestore.collection('tables').doc(mainTableId).update({
      'mergedTableIds': tableIdsToMerge,
      'status': 'occupied',
    });
    for (String id in tableIdsToMerge) {
      await firestore.collection('tables').doc(id).update({
        'status': 'merged',
        'currentOrderId': null,
      });
    }
    // Lấy lại danh sách món trong order bàn chính sau khi gộp
    final mainItemsSnap = await firestore
        .collection('orders')
        .doc(mainOrderId)
        .collection('items')
        .get();

    double mainTotalAmount = 0;
    for (var doc in mainItemsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      mainTotalAmount += (data['price'] as num) * (data['quantity'] as num);
    }

    // Cập nhật lại tổng tiền cho order bàn chính
    await firestore.collection('orders').doc(mainOrderId).update({
      'totalAmount': mainTotalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tách một bàn khỏi bàn chính
  static Future<void> splitTableWithItems({
    required String mainTableId,
    required String emptyTableId,
    required List<String> itemIdsToMove,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Lấy order chưa thanh toán của bàn chính
    QuerySnapshot mainOrderSnap = await firestore
        .collection('orders')
        .where('tableId', isEqualTo: mainTableId)
        .where('isPaid', isEqualTo: false)
        .limit(1)
        .get();

    if (mainOrderSnap.docs.isEmpty) return;
    String mainOrderId = mainOrderSnap.docs.first.id;

    // Tạo order mới cho bàn tách
    DocumentReference newOrder = await firestore.collection('orders').add({
      'tableId': emptyTableId,
      'isPaid': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    String newOrderId = newOrder.id;

    // Di chuyển các món đã chọn
    // Di chuyển các món đã chọn
    for (String itemId in itemIdsToMove) {
      DocumentSnapshot itemDoc = await firestore
          .collection('orders')
          .doc(mainOrderId)
          .collection('items')
          .doc(itemId)
          .get();

      if (itemDoc.exists) {
        // Thêm vào order mới với id tự sinh
        await firestore
            .collection('orders')
            .doc(newOrderId)
            .collection('items')
            .add(itemDoc.data() as Map<String, dynamic>);
        // Xóa khỏi order bàn chính
        await firestore
            .collection('orders')
            .doc(mainOrderId)
            .collection('items')
            .doc(itemId)
            .delete();
      }
    }

    // Lấy lại danh sách món còn lại trong order bàn chính
    final mainItemsSnap = await firestore
        .collection('orders')
        .doc(mainOrderId)
        .collection('items')
        .get();

    double mainTotalAmount = 0;
    for (var doc in mainItemsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      mainTotalAmount += (data['price'] as num) * (data['quantity'] as num);
    }

// Cập nhật lại tổng tiền cho order bàn chính
    await firestore.collection('orders').doc(mainOrderId).update({
      'totalAmount': mainTotalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Cập nhật trạng thái bàn
    await firestore.collection('tables').doc(emptyTableId).update({
      'status': 'occupied',
      'currentOrderId': newOrderId,
    });

    final itemsSnap = await firestore
        .collection('orders')
        .doc(newOrderId)
        .collection('items')
        .get();

    double totalAmount = 0;
    for (var doc in itemsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalAmount += (data['price'] as num) * (data['quantity'] as num);
    }

    await firestore.collection('orders').doc(newOrderId).update({
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
