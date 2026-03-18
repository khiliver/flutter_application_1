import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// if true the button will expand to fill horizontal space
  final bool fullWidth;

  /// if true a bordered outline button is shown instead of a filled one
  final bool outlined;

  /// show a loading spinner instead of the label/icon
  final bool isLoading;

  /// optional leading icon widget
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
    this.outlined = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoading) {
      content = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      final children = <Widget>[];
      if (icon != null) {
        children.add(icon!);
        children.add(const SizedBox(width: 8));
      }
      children.add(Text(label));
      content = Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    final button = outlined
        ? OutlinedButton(onPressed: onPressed, child: content)
        : ElevatedButton(onPressed: onPressed, child: content);

    return SizedBox(width: fullWidth ? double.infinity : null, child: button);
  }
}
