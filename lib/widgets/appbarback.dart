import 'package:flutter/material.dart';

class AppBarBack extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onPressed;
  final double height;
  final Color backgroundColor;
  final Color titleColor;
  final Color iconColor;
  final Color? iconBackgroundColor;
  final Gradient? gradient;

  const AppBarBack({
    super.key,
    required this.title,
    this.onPressed,
    this.height = 80,
    this.backgroundColor = const Color(0xFF7C68BE),
    this.titleColor = Colors.white,
    this.iconColor = Colors.white,
    this.iconBackgroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 70,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Center(
          child: GestureDetector(
            onTap: onPressed ?? () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new, color: iconColor, size: 20),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
