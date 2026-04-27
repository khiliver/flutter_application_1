import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../services/account_storage.dart';

class UserManagementSection extends StatelessWidget {
  const UserManagementSection({
    super.key,
    required this.accountsFuture,
    required this.isSuperAdmin,
    required this.onEditRole,
    required this.onDeleteAccount,
  });

  final Future<List<Account>> accountsFuture;
  final bool isSuperAdmin;
  final Future<void> Function(Account account) onEditRole;
  final Future<void> Function(Account account) onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Account>>(
      future: accountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final accounts = snapshot.data ?? [];
        final visibleAccounts = isSuperAdmin
            ? accounts
            : accounts.where((account) {
                final role = account.role.toLowerCase();
                return role != 'over all admin' && role != 'super admin';
              }).toList();

        if (visibleAccounts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No created accounts yet.'),
          );
        }

        return Column(
          children: visibleAccounts
              .map(
                (account) => _AccountTile(
                  account: account,
                  showActions: isSuperAdmin,
                  onEditRole: () => onEditRole(account),
                  onDeleteAccount: () => onDeleteAccount(account),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.showActions,
    required this.onEditRole,
    required this.onDeleteAccount,
  });

  final Account account;
  final bool showActions;
  final VoidCallback onEditRole;
  final VoidCallback onDeleteAccount;

  String _subtitleText() {
    final roleText = account.role;
    final roleKey = roleText.toLowerCase();
    final canHaveUnit = roleKey == 'admin' || roleKey == 'librarian';
    final unit = account.unit?.trim();

    if (canHaveUnit && unit != null && unit.isNotEmpty) {
      final label = roleKey == 'librarian' ? 'Library' : 'Unit';
      return '$roleText • $label: $unit';
    }

    if (account.userType != null && account.userType!.isNotEmpty) {
      return '$roleText • ${account.userType}';
    }

    return roleText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(account.name),
          subtitle: Text(_subtitleText()),
          trailing: showActions
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShadButton.ghost(
                      onPressed: onEditRole,
                      child: const Icon(Icons.edit, color: Colors.blueAccent),
                    ),
                    ShadButton.ghost(
                      onPressed: onDeleteAccount,
                      child: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}
