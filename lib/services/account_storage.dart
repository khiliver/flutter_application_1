import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class Account {
  final String email;
  final String password;
  final String name;
  final String role;
  final String? userType;
  final String? avatarPath;

  Account({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.userType,
    this.avatarPath,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
    'role': role,
    if (userType != null) 'userType': userType,
    if (avatarPath != null) 'avatarPath': avatarPath,
  };

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      userType: json['userType'] as String?,
      avatarPath: json['avatarPath'] as String?,
    );
  }
}

class AccountStorage {
  AccountStorage._();

  static final AccountStorage instance = AccountStorage._();

  CollectionReference<Map<String, dynamic>>? get _db {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance.collection('accounts');
  }

  bool get isReady => _db != null;

  String _docIdForEmail(String email) => email.trim().toLowerCase();

  Future<List<Account>> getAccounts() async {
    if (_db == null) {
      return [];
    }
    final snapshot = await _db!.get();
    final accounts = <Account>[];
    for (final doc in snapshot.docs) {
      try {
        accounts.add(Account.fromJson(doc.data()));
      } catch (_) {
        // Ignore malformed entries and continue loading valid accounts.
      }
    }
    return accounts;
  }

  Future<void> _upsertAccount(Account account) async {
    if (_db == null) {
      throw StateError('Firebase is not initialized for account writes.');
    }
    final data = account.toJson()..['updatedAt'] = FieldValue.serverTimestamp();
    await _db!.doc(_docIdForEmail(account.email)).set(data);
  }

  Future<Account?> findByEmail(String email) async {
    if (_db == null) {
      throw StateError('Firebase is not initialized for account reads.');
    }
    final snapshot = await _db!.doc(_docIdForEmail(email)).get();
    if (!snapshot.exists) {
      return null;
    }
    try {
      return Account.fromJson(snapshot.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<int> _superAdminCount({String? exceptEmail}) async {
    final all = await getAccounts();
    final normalizedExcept = exceptEmail?.toLowerCase();
    return all.where((a) {
      if (a.role.toLowerCase() != 'super admin') return false;
      if (normalizedExcept == null) return true;
      return a.email.toLowerCase() != normalizedExcept;
    }).length;
  }

  Future<bool> authenticate(String email, String password) async {
    final account = await findByEmail(email);
    return account != null && account.password == password;
  }

  Future<bool> addAccount(Account account) async {
    if (account.role.toLowerCase() == 'super admin') {
      final canCreate = await canCreateSuperAdmin();
      if (!canCreate) return false;
    }

    final existing = await findByEmail(account.email);
    if (existing != null) return false;
    await _upsertAccount(account);
    return true;
  }

  Future<bool> canCreateSuperAdmin({String? exceptEmail}) async {
    return (await _superAdminCount(exceptEmail: exceptEmail)) == 0;
  }

  Future<bool> updateAccountRole(
    String email,
    String role, {
    required String actingUserRole,
  }) async {
    if (actingUserRole.toLowerCase() != 'super admin') {
      return false;
    }

    final current = await findByEmail(email);
    if (current == null) {
      return false;
    }

    final normalizedRole = role.toLowerCase();

    // Super Admin role is protected and cannot be assigned from user management.
    if (!{'user', 'librarian', 'admin'}.contains(normalizedRole)) {
      return false;
    }

    final updated = Account(
      email: current.email,
      password: current.password,
      name: current.name,
      role: role,
      userType: normalizedRole == 'user'
          ? (current.userType ?? 'Student')
          : null,
      avatarPath: current.avatarPath,
    );

    await _upsertAccount(updated);
    return true;
  }

  Future<bool> updateAccountProfile({
    required String email,
    required String name,
    String? avatarPath,
  }) async {
    final current = await findByEmail(email);
    if (current == null) {
      return false;
    }

    final updated = Account(
      email: current.email,
      password: current.password,
      name: name,
      role: current.role,
      userType: current.userType,
      avatarPath: avatarPath,
    );

    await _upsertAccount(updated);
    return true;
  }

  Future<bool> removeAccount(String email) async {
    final account = await findByEmail(email);
    if (account == null) {
      return false;
    }

    if (account.role.toLowerCase() == 'super admin') {
      final superAdminCount = await _superAdminCount();
      if (superAdminCount <= 1) {
        return false;
      }
    }

    if (_db == null) {
      throw StateError('Firebase is not initialized for account writes.');
    }

    await _db!.doc(_docIdForEmail(email)).delete();
    return true;
  }
}
