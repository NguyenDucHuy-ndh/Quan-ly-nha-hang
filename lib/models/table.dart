class Table {
  final String id;
  final int tableNumber;
  final int capacity;
  final String status; // 'empty', 'occupied', 'reserved'
  final String? currentOrderId;

  Table({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.currentOrderId,
  });

  // Từ Firestore sang đối tượng
  factory Table.fromMap(Map<String, dynamic> map, String id) {
    return Table(
      id: id,
      tableNumber: map['tableNumber'],
      capacity: map['capacity'],
      status: map['status'],
      currentOrderId: map['currentOrderId'],
    );
  }

  // Từ đối tượng sang Firestore
  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'status': status,
      'currentOrderId': currentOrderId,
    };
  }
}
