import 'package:flutter/material.dart';
import '../constants.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final String? Function(String?)? validator;

  /// optional fixed width for the field
  final double? width;

  // default width when none specified (fall back to constant)
  static const double _defaultWidth = kFormElementWidth;

  /// if true the label is centered while the input text stays left-aligned
  final bool centerLabel;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.validator,
    this.width,
    this.centerLabel = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    Widget field = TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      // always left-align the input text
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        // center the label widget if requested; use floatingLabelAlignment as well
        label: widget.centerLabel
            ? Center(child: Text(widget.labelText))
            : Text(widget.labelText),
        floatingLabelAlignment: widget.centerLabel
            ? FloatingLabelAlignment.center
            : FloatingLabelAlignment.start,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              )
            : null,
      ),
    );
    final useWidth = widget.width ?? CustomTextField._defaultWidth;
    field = SizedBox(width: useWidth, child: field);
    return field;
  }
}
