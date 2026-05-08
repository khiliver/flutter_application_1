import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLogoPressed;

  const AppHeader({
    super.key,
    this.showBack = false,
    this.title = '',
    this.actions,
    this.onProfilePressed,
    this.onLogoPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? const BackButton()
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: onLogoPressed,
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/AskRisaheader.png', height: 50),
              ),
            ),
      centerTitle: true,
      title: Text(title, style: const TextStyle(fontSize: 20)),
      actions: [
        if (actions != null) ...actions!,
        IconButton(icon: const Icon(Icons.person), onPressed: onProfilePressed),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
