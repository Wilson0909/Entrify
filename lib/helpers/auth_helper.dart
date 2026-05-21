import 'package:cloud_firestore/cloud_firestore.dart';

class AuthHelper {
  final _db = FirebaseFirestore.instance;

  /// Login manual tanpa Firebase Auth
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final query = await _db
        .collection("users")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null; // user tidak ada
    }

    final data = query.docs.first.data();

    if (data["password"] != password) {
      return null; // password salah
    }

    // return data user
    return {
      "id": query.docs.first.id,
      "username": data["username"],
      "role": data["role"],
    };
  }

  /// Create user manual
  Future<void> createUser({
    required String username,
    required String password,
    required String role,
    required String name,
  }) async {
    await _db.collection("users").add({
      "username": username,
      "password": password,
      "role": role,
    });
  }
}
