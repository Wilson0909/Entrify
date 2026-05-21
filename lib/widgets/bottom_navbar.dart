import 'package:flutter/material.dart';

class UserBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const UserBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Background putih
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ), // Sedikit tambah padding vertikal karena teks hilang
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildNavItem(Icons.home, 0)),
                    Expanded(
                      child: _buildNavItem(Icons.announcement_outlined, 1),
                    ),
                    Expanded(child: _buildNavItem(Icons.list_alt_outlined, 2)),
                    Expanded(child: _buildNavItem(Icons.person_outline, 3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28, // Sedikit perbesar icon
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ],
      ),
    );
  }
}
