import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kAccountsKey = 'risa_accounts_v1';

class Account {
  final String email;
  final String password;
  final String name;
  final String role;
  final String? userType;

  Account({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.userType,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
    'role': role,
    if (userType != null) 'userType': userType,
  };

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      userType: json['userType'] as String?,
    );
  }
}

class AccountStorage {
  AccountStorage._();

  static final AccountStorage instance = AccountStorage._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Account>> getAccounts() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_kAccountsKey);
    if (raw == null) return [];
    return raw
        .map((s) => Account.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAccounts(List<Account> accounts) async {
    final prefs = await _prefs;
    final values = accounts.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_kAccountsKey, values);
  }

  Future<Account?> findByEmail(String email) async {
    final accounts = await getAccounts();
    for (final a in accounts) {
      if (a.email.toLowerCase() == email.toLowerCase()) {
        return a;
      }
    }
    return null;
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
    final accounts = await getAccounts();
    accounts.add(account);
    await _saveAccounts(accounts);
    return true;
  }

  Future<bool> canCreateSuperAdmin({String? exceptEmail}) async {
    final accounts = await getAccounts();
    final normalizedExcept = exceptEmail?.toLowerCase();
    final hasSuperAdmin = accounts.any((a) {
      if (a.role.toLowerCase() != 'super admin') return false;
      if (normalizedExcept == null) return true;
      return a.email.toLowerCase() != normalizedExcept;
    });
    return !hasSuperAdmin;
  }

  Future<bool> updateAccountRole(
    String email,
    String role, {
    required String actingUserRole,
  }) async {
    if (actingUserRole.toLowerCase() != 'super admin') {
      return false;
    }

    final accounts = await getAccounts();
    final targetIndex = accounts.indexWhere(
      (a) => a.email.toLowerCase() == email.toLowerCase(),
    );

    if (targetIndex == -1) {
      return false;
    }

    final current = accounts[targetIndex];
    final normalizedRole = role.toLowerCase();

    // Super Admin role is protected and cannot be assigned from user management.
    if (!{'user', 'librarian', 'admin'}.contains(normalizedRole)) {
      return false;
    }

    accounts[targetIndex] = Account(
      email: current.email,
      password: current.password,
      name: current.name,
      role: role,
      userType: normalizedRole == 'user'
          ? (current.userType ?? 'Student')
          : null,
    );

    await _saveAccounts(accounts);
    return true;
  }

  Future<bool> removeAccount(String email) async {
    final accounts = await getAccounts();
    final targetIndex = accounts.indexWhere(
      (a) => a.email.toLowerCase() == email.toLowerCase(),
    );
    if (targetIndex == -1) {
      return false;
    }

    final target = accounts[targetIndex];
    if (target.role.toLowerCase() == 'super admin') {
      final superAdminCount = accounts
          .where((a) => a.role.toLowerCase() == 'super admin')
          .length;
      if (superAdminCount <= 1) {
        return false;
      }
    }

    accounts.removeAt(targetIndex);
    await _saveAccounts(accounts);
    return true;
  }
}
