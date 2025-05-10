import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quanly_nhahang/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng ký
  Future<UserModel?> signUp(
      String email, String password, String displayName, String role) async {
    try {
      print('Đang đăng ký với role: $role');

      // Tạo user trong Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Tạo đối tượng UserModel ngay sau khi đăng ký thành công
        UserModel user = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          role: role,
        );

        // Lưu vào Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(user.toMap());

        print('Đã lưu user vào DB: ${user.toMap()}');
        return user; // Trả về đối tượng UserModel đã tạo
      }
      return null;
    } catch (e) {
      print('Lỗi trong quá trình đăng ký: $e');
      throw e; // Ném lại lỗi để RegisterScreen xử lý
    }
  }

  // Đăng nhập
  Future<UserModel?> logIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy thông tin user từ Firestore bao gồm role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        return UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          role: userDoc.data()!['role'] ?? 'user', // Lấy role từ Firestore
          createdAt: userCredential.user!.metadata.creationTime,
        );
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Đăng nhập bằng Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Implement Google Sign In logic here
      // Example: Use GoogleSignIn package to authenticate
      // After successful authentication, retrieve user details
      // and save them to Firestore if necessary.
      return null; // Placeholder
    } catch (e) {
      print("Error during Google Sign-In: ${e.toString()}");
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Kiểm tra trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Lấy thông tin chi tiết user
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error fetching user details: ${e.toString()}");
      return null;
    }
  }

  // Cập nhật profile
  Future<void> updateProfile(
      {String? displayName, String? photoUrl, String? role}) async {
    try {
      if (_auth.currentUser != null) {
        // Cập nhật trong Auth
        if (displayName != null) {
          await _auth.currentUser!.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await _auth.currentUser!.updatePhotoURL(photoUrl);
        }

        // Cập nhật trong Firestore
        Map<String, dynamic> updates = {};
        if (displayName != null) updates['displayName'] = displayName;
        if (photoUrl != null) updates['photoUrl'] = photoUrl;
        if (role != null) updates['role'] = role;

        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(updates);
      }
    } catch (e) {
      print("Error updating profile: ${e.toString()}");
    }
  }

  // Quên mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error sending password reset email: ${e.toString()}");
    }
  }

  // Xóa tài khoản
  Future<void> deleteAccount() async {
    try {
      String uid = _auth.currentUser!.uid;

      // Xóa trong Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Xóa trong Auth
      await _auth.currentUser!.delete();
    } catch (e) {
      print("Error deleting account: ${e.toString()}");
    }
  }
}
