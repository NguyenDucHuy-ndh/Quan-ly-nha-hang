import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/user_model.dart';
import 'package:quanly_nhahang/screens/manager/edit_menu_screen.dart';
import 'package:quanly_nhahang/screens/manager/statistics_screen.dart';
import 'package:quanly_nhahang/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel userModel;

  const ProfileScreen({Key? key, required this.userModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildProfileContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: userModel.photoUrl != null
                ? NetworkImage(userModel.photoUrl!)
                : const AssetImage('images/default_avatar.png')
                    as ImageProvider,
          ),
          const SizedBox(height: 16),
          Text(
            userModel.displayName ?? 'Chưa có tên',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userModel.email,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    // Thêm logging chi tiết hơn
    print('Building profile content');
    print('User data:');
    print('UID: ${userModel.uid}');
    print('Email: ${userModel.email}');
    print('Role: ${userModel.role}');
    print('DisplayName: ${userModel.displayName}');

    // Chuẩn hóa role để tránh lỗi do chữ hoa/thường
    final role = userModel.role.toLowerCase().trim();

    // Chỉ phân biệt 2 loại: manager và staff (bao gồm cashier, kitchen, staff)
    switch (role) {
      case 'manager':
        return _buildManagerProfile(context);
      case 'waiter':
      case 'kitchen':
      case 'cashier':
        return _buildStaffProfile(context);
      default:
        print('Unhandled role: $role');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy thông tin cho vai trò: $role',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStaffProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Thông tin nhân viên',
            items: [
              _buildInfoItem(Icons.badge, 'Mã nhân viên', userModel.uid),
              _buildInfoItem(
                  Icons.work, 'Chức vụ', _getRoleDisplay(userModel.role)),
              _buildInfoItem(Icons.access_time, 'Ca làm việc', 'Ca sáng'),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons([
            if (userModel.role.toLowerCase() == 'kitchen')
              ActionButton(
                icon: Icons.restaurant_menu,
                label: 'Xem đơn món',
                onTap: () {},
              ),
            if (userModel.role.toLowerCase() == 'cashier')
              ActionButton(
                icon: Icons.payment,
                label: 'Xử lý thanh toán',
                onTap: () {},
              ),
            ActionButton(
              icon: Icons.calendar_today,
              label: 'Xem lịch làm việc',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.edit,
              label: 'Cập nhật thông tin',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.lock,
              label: 'Đổi mật khẩu',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.logout,
              label: 'Đăng xuất',
              onTap: () => _handleLogout(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildManagerProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Thông tin quản lý',
            items: [
              _buildInfoItem(
                  Icons.admin_panel_settings, 'Mã quản lý', userModel.uid),
              _buildInfoItem(Icons.email, 'Email', userModel.email),
              _buildInfoItem(Icons.circle, 'Trạng thái', 'Đang hoạt động'),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons([
            ActionButton(
              icon: Icons.menu,
              label: 'Chỉnh sửa menu',
              onTap: () => _navigateToEditMenu(context),
            ),
            ActionButton(
              icon: Icons.bar_chart,
              label: 'Báo cáo doanh thu',
              onTap: () => _navigateToStatistics(context),
            ),
            ActionButton(
              icon: Icons.edit,
              label: 'Cập nhật thông tin',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.lock,
              label: 'Đổi mật khẩu',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.logout,
              label: 'Đăng xuất',
              onTap: () => _handleLogout(context),
            ),
          ]),
        ],
      ),
    );
  }

  void _navigateToEditMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditMenuScreen(),
      ),
    );
  }

  void _navigateToStatistics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // Căn đầu dòng
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                    overflow:
                        TextOverflow.ellipsis, // Thêm dấu ... nếu text quá dài
                    maxLines: 1, // Giới hạn 1 dòng
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(List<ActionButton> buttons) {
    return Column(
      children: buttons
          .map((button) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: button.onTap,
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Icon(button.icon, color: Colors.blue),
                  title: Text(button.label),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ))
          .toList(),
    );
  }

  void _handleLogout(BuildContext context) async {
    try {
      // Hiển thị dialog xác nhận
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final authService = AuthService();
        await authService.signOut();

        if (context.mounted) {
          // Chuyển về màn hình login và xóa stack navigation
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

String _getRoleDisplay(String role) {
  switch (role.toLowerCase().trim()) {
    case 'manager':
      return 'Quản lý';
    case 'kitchen':
      return 'Đầu bếp';
    case 'cashier':
      return 'Thu ngân';
    case 'staff':
      return 'Nhân viên';
    default:
      return role;
  }
}

class ActionButton {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
