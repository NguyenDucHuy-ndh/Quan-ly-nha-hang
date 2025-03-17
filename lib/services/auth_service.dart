import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final DocumentSnapshot documentSnapshot = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      return UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw e.message!;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getCurrentUser() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw 'User not found';
    }

    final DocumentSnapshot documentSnapshot =
        await _firestore.collection('users').doc(user.uid).get();

    return UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
  }
}
