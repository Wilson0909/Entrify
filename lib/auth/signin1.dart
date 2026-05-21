import 'dart:math';
import 'package:flutter/material.dart';
import 'package:expo/widgets/button.dart';

class SignInOnePage extends StatelessWidget {
  const SignInOnePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final logoSize = min(width * 0.80, 400.0);

    final titleFont = min(width * 0.065, 30.0); 
    final subtitleFont = min(width * 0.038, 17.0); 
    final buttonWidth = min(width * 0.85, 420.0); 

    return Scaffold(
      body: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8C6CCF),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Column(
              children: [
                const Spacer(flex: 1),

                /// LOGO (size controlled by max)
                SizedBox(
                  width: logoSize,
                  height: logoSize * 0.8,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(flex: 4),

                /// TITLE + SLOGAN
                Column(
                  children: [
                    Text(
                      "Gate Smarter, Life Better.",
                      style: TextStyle(
                        fontSize: titleFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: height * 0.012),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: min(width * 0.65, 500)),
                      child: Text(
                        "Optimalisasi keamanan dan efisiensi dengan sistem akses otomatis.",
                        style: TextStyle(
                          fontSize: subtitleFont,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.04),

                SizedBox(
                  width: buttonWidth,
                  child: CustomButton(
                    text: "Sign In",
                    onPressed: () {
                      Navigator.pushNamed(context, '/signin2');
                    },
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
