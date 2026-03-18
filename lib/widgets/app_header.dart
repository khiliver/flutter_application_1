import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final String title;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    this.showBack = false,
    this.title = '',
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      leading: showBack ? const BackButton() : null,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // increase logo size for visibility
          Image.asset('assets/Risa_logo.png', height: 50),
          if (title.isNotEmpty) ...[
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontSize: 20)),
          ],
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
