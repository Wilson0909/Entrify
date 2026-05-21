import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:expo/widgets/page_header.dart';
import 'package:expo/widgets/button.dart';
import 'package:expo/services/localization_service.dart';

class TambahPenghuniAdminPage extends StatefulWidget {
  const TambahPenghuniAdminPage({super.key});

  @override
  State<TambahPenghuniAdminPage> createState() =>
      _TambahPenghuniAdminPageState();
}

class _TambahPenghuniAdminPageState extends State<TambahPenghuniAdminPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  // Controllers
  final TextEditingController _usernameController = TextEditingController(
    text: "",
  );
  final TextEditingController _passwordController = TextEditingController(
    text: "",
  );
  final TextEditingController _confirmPasswordController =
      TextEditingController(text: "");
  final TextEditingController _alamatController = TextEditingController(
    text: "",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "",
  );

  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String username = _usernameController.text.trim();

        // Check if Username already exists
        final usernameCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

        if (usernameCheck.docs.isNotEmpty) {
          throw tr('username_sudah_digunakan');
        }

        // Create user document with auto-generated ID
        await FirebaseFirestore.instance.collection('users').add({
          'nama': username, // Use username as name for compatibility
          'username': username,
          'password': _passwordController.text.trim(),
          'alamat': _alamatController.text.trim(),
          'no_hp': _phoneController.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('penghuni_berhasil_ditambahkan'))),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${tr('terjadi_kesalahan')}: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          PageHeader(title: tr('tambah_penghuni'), showBackButton: false),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(tr('username')),
                                _buildTextField(
                                  _usernameController,
                                  hintText: tr('hint_username'),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel(tr('password')),
                                _buildTextField(
                                  _passwordController,
                                  isPassword: true,
                                  hintText: tr('hint_password'),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel(tr('konfirmasi_password')),
                                _buildTextField(
                                  _confirmPasswordController,
                                  isPassword: true,
                                  hintText: tr('hint_konfirmasi_password'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return tr('field_tidak_boleh_kosong');
                                    }
                                    if (value != _passwordController.text) {
                                      return tr('password_tidak_sama');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildLabel(tr('alamat')),
                                _buildTextField(
                                  _alamatController,
                                  hintText: tr('hint_alamat'),
                                ),
                                const SizedBox(height: 16),
                                _buildLabel(tr('nomor_handphone')),
                                _buildTextField(
                                  _phoneController,
                                  isNumber: true,
                                  hintText: tr('hint_nomor_handphone'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: _isLoading ? tr('loading') : tr('submit'),
                            onPressed: _isLoading ? () {} : _submit,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF7C68BE),
                        size: 20,
                      ),
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    bool isPassword = false,
    bool isNumber = false,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return tr('field_tidak_boleh_kosong');
              }
              return null;
            },
      ),
    );
  }
}
