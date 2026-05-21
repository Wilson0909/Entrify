import 'dart:math';
import 'package:flutter/material.dart';
import 'package:expo/widgets/button.dart';

class SignIn2Page extends StatefulWidget {
  const SignIn2Page({super.key});

  @override
  State<SignIn2Page> createState() => _SignIn2PageState();
}

class _SignIn2PageState extends State<SignIn2Page> {
  bool _showPassword = false;
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    /// Max size config (sama seperti halaman sebelumnya)
    final logoWidth = min(width * 0.60, 245.0);     
    final cardMaxWidth = min(width, 490.0);  
    final buttonMaxWidth = min(width * 0.80, 420.0);

    final iconColor = const Color.fromARGB(255, 185, 156, 190);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1F2233),
                  Color(0xFF252737),
                  Color(0xFF1A1C27),
                ],
              ),
            ),
          ),

          /// LOGO ATAS pakai max constraint
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: height * 0.10),
              child: SizedBox(
                width: logoWidth,
                child: Image.asset(
                  "assets/logo.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          /// CARD FORM
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardMaxWidth),
              child: Container(
                width: width,
                height: height * 0.52,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(42),
                    topRight: Radius.circular(42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.04),

                      const Center(
                        child: Column(
                          children: [
                            Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Sign in to my account",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.035),

                      const Text(
                        "Email",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // EMAIL FIELD
                      _inputField(
                        icon: Icons.email_outlined,
                        hint: "My Email",
                        iconColor: iconColor,
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // PASSWORD FIELD
                      _passwordField(iconColor),

                      const SizedBox(height: 12),

                      // REMEMBER ME
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                activeColor: Colors.deepPurple,
                              ),
                              const Text(
                                "Remember Me",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const Text(
                            "Forgot Password",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: height * 0.025),

                      // SIGN IN BUTTON
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: buttonMaxWidth, minHeight: 52),
                          child: CustomButton(
                            text: "Sign In",
                            onPressed: () {
                              Navigator.pushNamed(context, '/user/homepage');
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// TEXT FIELD COMPONENT
  Widget _inputField({required IconData icon, required String hint, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.3),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "My Email",
                hintStyle: TextStyle(color: Colors.black38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PASSWORD FIELD
  Widget _passwordField(Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.3),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "My Password",
                hintStyle: TextStyle(color: Colors.black38),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
