import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expo/widgets/button.dart';
import 'package:get_storage/get_storage.dart';

class SignInMergedPage extends StatefulWidget {
  const SignInMergedPage({super.key});

  @override
  State<SignInMergedPage> createState() => _SignInMergedPageState();
}

class _SignInMergedPageState extends State<SignInMergedPage> {
  bool _isSignInFormVisible = false;
  bool _showPassword = false;
  bool _rememberMe = true;

  // 🔥 Controller untuk login
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    final storage = GetStorage();
    final savedUsername = storage.read("remember_username");
    final savedPassword = storage.read("remember_password");

    if (savedUsername != null) {
      _emailController.text = savedUsername;
      setState(() {
        _rememberMe = true;
      });
    }

    if (savedUsername != null && savedPassword != null) {
      _passwordController.text = savedPassword;
      // Auto login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogin();
      });
    }
  }

  // 🔥 Login tanpa Firebase Auth (Firestore manual)
  Future<void> _handleLogin() async {
    setState(() => _loading = true);

    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan password wajib diisi")),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .where("password", isEqualTo: password) // langsung filter password
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email atau password salah")),
        );
        setState(() => _loading = false);
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();
      final userId = doc.id;

      // Simpan userId di GetStorage agar halaman lain bisa akses
      final storage = GetStorage();
      await storage.write("userId", userId);
      await storage.write("role", data["role"]);

      // cek role
      final String role = data["role"] ?? "user";

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, '/admin/homepage');
      } else {
        Navigator.pushReplacementNamed(context, '/user/homepage');
      }

      // Handle Remember Me
      if (_rememberMe) {
        await storage.write("remember_username", username);
        await storage.write("remember_password", password);
      } else {
        await storage.remove("remember_username");
        await storage.remove("remember_password");
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login berhasil")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  void _toggleView() {
    setState(() {
      _isSignInFormVisible = !_isSignInFormVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // --- SIZES FOR VIEW 1 ---
    final logoSize1 = min(width * 0.80, 400.0);
    final titleFont = min(width * 0.065, 30.0);
    final subtitleFont = min(width * 0.038, 17.0);
    final buttonWidth1 = min(width * 0.85, 420.0);

    // --- SIZES FOR VIEW 2 ---
    final logoWidth2 = min(width * 0.60, 245.0);
    final cardMaxWidth = min(width, 490.0);
    final buttonMaxWidth2 = min(width * 0.80, 420.0);
    final iconColor = const Color.fromARGB(255, 185, 156, 190);

    return Scaffold(
      body: Stack(
        children: [
          // =============== BACKGROUND ===============
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isSignInFormVisible
                    ? [
                        const Color(0xFF2E1A47),
                        const Color(0xFF1A0F29),
                        Colors.black,
                      ]
                    : [
                        const Color(0xFF8C6CCF),
                        const Color(0xFFA890D9),
                        Colors.white,
                      ],
              ),
            ),
          ),

          // ================= VIEW 1 =================
          AnimatedOpacity(
            opacity: _isSignInFormVisible ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 600),
            child: IgnorePointer(
              ignoring: _isSignInFormVisible,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        SizedBox(height: logoSize1 * 0.8),
                        const Spacer(flex: 4),

                        Column(
                          children: [
                            Text(
                              "Gate Smarter, Life Better",
                              style: TextStyle(
                                fontSize: titleFont,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: height * 0.012),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: min(width * 0.65, 500),
                              ),
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
                          width: buttonWidth1,
                          child: CustomButton(
                            text: "Sign In",
                            onPressed: _toggleView,
                          ),
                        ),

                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ========== LOGO MOVING ANIMATION ==========
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            top: _isSignInFormVisible ? height * 0.10 : height * 0.30,
            left: _isSignInFormVisible
                ? (width - logoWidth2) / 2
                : (width - logoSize1) / 2,
            width: _isSignInFormVisible ? logoWidth2 : logoSize1,
            height: _isSignInFormVisible ? logoWidth2 * 0.8 : logoSize1 * 0.8,
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),

          // ================= VIEW 2 FORM =================
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            bottom: _isSignInFormVisible ? 0 : -height * 0.7,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardMaxWidth),
                child: Container(
                  width: width,
                  height: height * 0.560,
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
                          "Username",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 🔥 EMAIL INPUT
                        _inputField(
                          icon: Icons.email_outlined,
                          hint: "Enter your username",
                          controller: _emailController,
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

                        // 🔥 PASSWORD INPUT
                        _passwordField(iconColor),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) =>
                                      setState(() => _rememberMe = val ?? true),
                                  activeColor: Colors.deepPurple,
                                ),
                                const Text(
                                  "Remember Me",
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: height * 0.025),

                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: buttonMaxWidth2,
                              minHeight: 52,
                            ),
                            child: CustomButton(
                              text: "Sign In",
                              onPressed: _loading ? null : () => _handleLogin(),
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
          ),
        ],
      ),
    );
  }

  /// TEXT FIELD COMPONENT
  Widget _inputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required Color iconColor,
  }) {
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
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black38),
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
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Enter your password",
                hintStyle: TextStyle(color: Colors.black38),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
