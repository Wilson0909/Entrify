import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? rightIcon;
  final double height;
  final bool showBackButton;
  final List<Color>? colors;
  final double? titleTopPadding;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.rightIcon,
    this.height = 200,
    this.showBackButton = true,
    this.colors,
    this.titleTopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [const Color(0xFF795FFC), const Color(0xFF7155FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Back Button (Left)
                  if (showBackButton)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          behavior: HitTestBehavior.translucent,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEFEFE),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Color(0xFF7A5AF8),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Title (Center)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: titleTopPadding ?? 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFEFEFE),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 3. Right Icon (Right)
                  if (rightIcon != null)
                    Align(alignment: Alignment.topRight, child: rightIcon!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
