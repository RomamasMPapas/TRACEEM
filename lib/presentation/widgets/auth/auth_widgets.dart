import 'package:flutter/material.dart';

Widget buildCustomTextField(
  String label,
  TextEditingController controller, {
  bool isPassword = false,
  TextInputAction textInputAction = TextInputAction.next,
  VoidCallback? onSubmitted,
}) {
  return _CustomTextField(
    label: label,
    controller: controller,
    isPassword: isPassword,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
  );
}

class _CustomTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  const _CustomTextField({
    required this.label,
    required this.controller,
    required this.isPassword,
    required this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<_CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        textInputAction: widget.textInputAction,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF4C8CFF),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4C8CFF), width: 1.5),
          ),
        ),
      ),
    );
  }
}

Widget buildLandingButton(
  String text,
  Color bgColor,
  Color textColor,
  VoidCallback onTap,
) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1.1,
        ),
      ),
    ),
  );
}

Widget buildSocialIcon(IconData icon, Color color) {
  return Container(
    width: 45,
    height: 45,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Icon(icon, color: color),
  );
}
