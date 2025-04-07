import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/user_model.dart';

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
                : const AssetImage('assets/images/default_avatar.png')
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
    switch (userModel.role) {
      case 'customer':
        return _buildCustomerProfile(context);
      case 'staff':
        return _buildStaffProfile(context);
      case 'manager':
        return _buildManagerProfile(context);
      default:
        return const Center(child: Text('Không tìm thấy thông tin'));
    }
  }

  Widget _buildCustomerProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Thông tin cá nhân',
            items: [
              _buildInfoItem(Icons.phone, 'Số điện thoại', 'Chưa cập nhật'),
              _buildInfoItem(Icons.cake, 'Ngày sinh', 'Chưa cập nhật'),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons([
            ActionButton(
              icon: Icons.history,
              label: 'Lịch sử đặt bàn',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.restaurant,
              label: 'Lịch sử gọi món',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.help_outline,
              label: 'Hỗ trợ khách hàng',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.edit,
              label: 'Cập nhật thông tin',
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

  Widget _buildStaffProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Thông tin nhân viên',
            items: [
              _buildInfoItem(Icons.badge, 'Mã nhân viên', userModel.uid),
              _buildInfoItem(Icons.work, 'Chức vụ', 'Nhân viên'),
              _buildInfoItem(Icons.access_time, 'Ca làm việc', 'Ca sáng'),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons([
            ActionButton(
              icon: Icons.calendar_today,
              label: 'Chấm công / Xem lịch làm',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.sync,
              label: 'Đăng ký đổi ca',
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
              icon: Icons.people,
              label: 'Quản lý nhân sự',
              onTap: () {},
            ),
            ActionButton(
              icon: Icons.bar_chart,
              label: 'Báo cáo doanh thu',
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
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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

  void _handleLogout(BuildContext context) {
    // TODO: Implement logout logic
    Navigator.pushReplacementNamed(context, '/');
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
