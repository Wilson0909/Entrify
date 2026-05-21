import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;

  /// Bisa menerima:
  /// - void Function()
  /// - Future<void> Function()
  final Function()? onPressed;

  const CustomButton({super.key, required this.text, required this.onPressed});

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double buttonWidth =
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0)
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width * 0.8;

        return GestureDetector(
          onTapDown: (_) {
            if (!_loading && widget.onPressed != null) {
              setState(() => _pressed = true);
            }
          },
          onTapCancel: () {
            if (!_loading) {
              setState(() => _pressed = false);
            }
          },
          onTapUp: (_) async {
            if (_loading || widget.onPressed == null) return;

            setState(() => _pressed = false);

            final result = widget.onPressed!();

            // Kalau function return Future → tunggu
            if (result is Future) {
              setState(() => _loading = true);
              await result;
              if (mounted) setState(() => _loading = false);
            }
          },
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: SizedBox(
              width: buttonWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _pressed
                        ? [
                            const Color(0xFF6744D6), // Darker shade of 7A5AF8
                            const Color(0xFF5433B8),
                          ]
                        : [
                            const Color(0xFF7A5AF8), // Main requested color
                            const Color(0xFF6744D6),
                          ],
                  ),
                  boxShadow: _pressed
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            offset: const Offset(2, 2),
                            blurRadius: 6,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            offset: const Offset(-2, -2),
                            blurRadius: 6,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(4, 4),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            offset: const Offset(-4, -4),
                            blurRadius: 8,
                          ),
                        ],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFFFEFEFE),
                          ),
                        )
                      : Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFEFEFE),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
