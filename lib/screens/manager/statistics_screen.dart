import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:quanly_nhahang/models/order_item.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thống kê'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Doanh thu'),
              Tab(text: 'Món ăn'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _onPeriodChanged,
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'week',
                  child: Text('7 ngày qua'),
                ),
                const PopupMenuItem(
                  value: 'month',
                  child: Text('30 ngày qua'),
                ),
                const PopupMenuItem(
                  value: 'year',
                  child: Text('365 ngày qua'),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildRevenueTab(),
            _buildMenuItemsTab(),
          ],
        ),
      ),
    );
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'week':
          _startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'month':
          _startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'year':
          _startDate = DateTime.now().subtract(const Duration(days: 365));
          break;
      }
      _endDate = DateTime.now();
    });
  }

  Widget _buildRevenueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('isPaid', isEqualTo: true) // Thay đổi điều kiện lọc
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;
        final totalRevenue = orders.fold<double>(
          0,
          (sum, order) => sum + (order.data() as Map)['totalAmount'],
        );

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildRevenueOverview(totalRevenue, orders.length),
              _buildRevenueChart(orders),
              _buildRecentOrders(orders),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueOverview(double totalRevenue, int orderCount) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final daysInPeriod = _endDate.difference(_startDate).inDays;
    final averageDaily = totalRevenue / daysInPeriod;
    final averageOrdersDaily = orderCount / daysInPeriod;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng doanh thu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(totalRevenue),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Trung bình/ngày',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(averageDaily),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng số đơn: $orderCount'),
                    const SizedBox(height: 4),
                    Text(
                      'Trung bình: ${averageOrdersDaily.toStringAsFixed(1)} đơn/ngày',
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Từ: ${DateFormat('dd/MM/yyyy').format(_startDate)}'),
                    Text('Đến: ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<QueryDocumentSnapshot> orders) {
    // Tạo map chứa doanh thu theo ngày
    final dailyRevenue = <DateTime, double>{};
    for (var order in orders) {
      try {
        final data = order.data() as Map;
        // Use updatedAt instead of completedAt and add null check
        if (data['updatedAt'] != null) {
          final date = (data['updatedAt'] as Timestamp).toDate();
          final dateKey = DateTime(date.year, date.month, date.day);
          final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
          dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + amount;
        }
      } catch (e) {
        print('Error processing order ${order.id}: $e');
        continue;
      }
    }

    // Sort the entries by date
    final sortedEntries = dailyRevenue.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.map((entry) {
      return FlSpot(
        entry.key.millisecondsSinceEpoch.toDouble(),
        entry.value,
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300, // Tăng chiều cao của chart
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60, // Tăng khoảng cách cho text bên trái
                    getTitlesWidget: (value, meta) {
                      // Format giá trị theo nghìn đồng
                      return Text(
                        '${(value / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35, // Tăng khoảng cách cho text bên dưới
                    interval: 24 * 60 * 60 * 1000, // 1 ngày
                    getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders(List<QueryDocumentSnapshot> orders) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Đơn hàng gần đây',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map;
              // Use updatedAt instead of completedAt and add null check
              final date = (order['updatedAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final amount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;

              return ListTile(
                title: Text('Đơn #${orders[index].id}'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
                trailing: Text(
                  currencyFormat.format(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    return FutureBuilder<List<OrderItem>>(
      future: _fetchAllOrderItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu món ăn'));
        }

        final allItems = snapshot.data!;
        print('Tìm thấy ${allItems.length} món ăn');

        final currencyFormat =
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
        double totalRevenue = 0;
        int totalQuantity = 0;
        final itemStats = <String, Map<String, dynamic>>{};

        // Xử lý từng món ăn
        for (var item in allItems) {
          final revenue = item.price * item.quantity;
          totalRevenue += revenue;
          totalQuantity += item.quantity;

          // Cập nhật thống kê cho món
          if (!itemStats.containsKey(item.menuItemId)) {
            itemStats[item.menuItemId] = {
              'quantity': 0,
              'revenue': 0.0,
              'name': item.name,
              'price': item.price,
            };
          }

          itemStats[item.menuItemId]!['quantity'] += item.quantity;
          itemStats[item.menuItemId]!['revenue'] += revenue;
        }

        // Sắp xếp món theo doanh thu
        final sortedItems = itemStats.entries.toList()
          ..sort((a, b) => (b.value['quantity'] as int)
              .compareTo(a.value['quantity'] as int));

        // Phần hiển thị giữ nguyên...
        return ListView(
          children: [
            // Card tổng quan
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng doanh thu:'),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(totalRevenue),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Tổng số món đã bán:'),
                            const SizedBox(height: 4),
                            Text(
                              '$totalQuantity món',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Card chi tiết từng món
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Chi tiết doanh thu theo món',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedItems.length,
                    itemBuilder: (context, index) {
                      final item = sortedItems[index];
                      final quantity = item.value['quantity'] as int;
                      final revenue = item.value['revenue'] as double;
                      final price = item.value['price'] as double;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          item.value['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giá: ${currencyFormat.format(price)}'),
                            Text('Số lượng đã bán: $quantity'),
                            Text(
                              'Doanh thu: ${currencyFormat.format(revenue)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

// Hàm mới để lấy tất cả OrderItem từ các orders
  Future<List<OrderItem>> _fetchAllOrderItems() async {
    // Lấy tất cả đơn hàng đã thanh toán
    final orderSnapshots = await _firestore
        .collection('orders')
        .where('isPaid', isEqualTo: true)
        .orderBy('updatedAt', descending: true) // Only one orderBy
        .get();

    final List<OrderItem> allItems = [];

    // Xử lý từng đơn hàng
    for (var orderDoc in orderSnapshots.docs) {
      try {
        // Lấy các OrderItem từ subcollection
        final itemsSnapshot = await _firestore
            .collection('orders')
            .doc(orderDoc.id)
            .collection('items')
            .get();

        for (var itemDoc in itemsSnapshot.docs) {
          try {
            final itemData = itemDoc.data();
            allItems.add(OrderItem.fromMap(itemData, itemDoc.id));
          } catch (e) {
            print('Lỗi khi xử lý món ${itemDoc.id}: $e');
            continue;
          }
        }
      } catch (e) {
        print('Lỗi khi xử lý đơn hàng ${orderDoc.id}: $e');
        continue;
      }
    }

    return allItems;
  }
}
