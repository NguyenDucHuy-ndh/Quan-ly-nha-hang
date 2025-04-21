import 'package:flutter/material.dart';
import 'package:quanly_nhahang/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String _email = '';
  String _password = '';
  String _name = '';
  String _role = 'waiter'; // Mặc định là staff
  bool _isLoading = false;
  String _errorMessage = '';

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      _formKey.currentState!.save();

      try {
        print("Bắt đầu đăng ký với: Email: $_email, Role: $_role");

        final user = await _authService.signUp(
          _email,
          _password,
          _name,
          _role,
        );

        print("Kết quả đăng ký: $user");

        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          // Truyền tham số user vào route /home
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: user,
          );
        } else {
          setState(() {
            _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
          });
        }
      } catch (e) {
        print("Lỗi trong quá trình đăng ký: $e");
        setState(() {
          _isLoading = false;
          _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Họ tên
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _email = value!;
                  },
                ),
                const SizedBox(height: 16),

                // Mật khẩu
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
                const SizedBox(height: 16),

                // Vai trò
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(),
                  ),
                  value: _role,
                  items: const [
                    DropdownMenuItem(
                      value: 'manager',
                      child: Text('Quản lý'),
                    ),
                    DropdownMenuItem(
                      value: 'cashier',
                      child: Text('Cashier'),
                    ),
                    DropdownMenuItem(
                      value: 'waiter',
                      child: Text('Waiter'),
                    ),
                    DropdownMenuItem(
                      value: 'kitchen',
                      child: Text('Kitchen'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _role = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Thông báo lỗi
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Nút đăng ký
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Đăng ký'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Liên kết đến màn hình đăng nhập
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
