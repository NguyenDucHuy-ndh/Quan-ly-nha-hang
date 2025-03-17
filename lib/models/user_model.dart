class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      role: data['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
    };
  }
}
