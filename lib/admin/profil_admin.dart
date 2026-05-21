import 'package:flutter/material.dart';
import 'package:expo/user/notifikasi.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expo/auth/signin_merged.dart';
import 'package:expo/services/localization_service.dart';

class ProfilAdminPage extends StatefulWidget {
  const ProfilAdminPage({super.key});

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  String _userName = "";
  int _totalUsers = 0;
  int _totalVehicles = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final storage = GetStorage();
    final userId = storage.read("userId");

    if (userId == null) return;

    try {
      // 1. Fetch Admin Profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      String name = "Admin";
      if (userDoc.exists) {
        final data = userDoc.data();
        name = data?['nama'] ?? data?['username'] ?? "Admin";
      }

      // 2. Fetch Total Users
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
      int totalUsers = usersSnap.docs.length;

      // 3. Fetch Total Vehicles
      final vehiclesSnap = await FirebaseFirestore.instance
          .collection('plat_terdaftar')
          .get();
      int totalVehicles = vehiclesSnap.docs.length;

      if (mounted) {
        setState(() {
          _userName = name;
          _totalUsers = totalUsers;
          _totalVehicles = totalVehicles;
        });
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF795FFC), Color(0xFF7155FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _fetchUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Stack(
              children: [
                // 1. Content Body (White part)
                Column(
                  children: [
                    const SizedBox(height: 190), // Space for header
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 160,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F3F8), // Match User Profile color
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 80,
                              ), // Increased space for avatar
                              _buildProfileInfo(),
                              const SizedBox(height: 20),
                              // Stats section (Dashboard)
                              _buildStatsSection(),
                              const SizedBox(height: 20),
                              _buildContactSection(),
                              const SizedBox(height: 20),
                              _buildSettingsSection(context),
                              const SizedBox(height: 30), // Bottom padding
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. Header Content (Text & Notif)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                tr('profil_admin'),
                                style: const TextStyle(
                                  color: Color(0xFFFEFEFE),
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Avatar (Positioned absolute)
                Positioned(
                  top: 120, // Adjusted to overlap correctly (160 - 70 = 90)
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0A4D8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text(
          _userName.isEmpty ? tr('loading') : _userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('admin'),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF7A5AF8), // Match User Profile color
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('ringkasan'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8), // Same as user profile
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/admin/daftar_penghuni',
                      ).then((_) => _fetchUserData());
                    },
                    child: _buildStatCard(
                      tr('total_user'),
                      _totalUsers.toString(),
                      Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/admin/daftar_kendaraan',
                      ).then((_) => _fetchUserData());
                    },
                    child: _buildStatCard(
                      tr('jumlah_kendaraan'),
                      _totalVehicles.toString(),
                      Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDCDC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSectionContainer(
      title: tr('kontak'),
      children: [
        _buildListTile(
          Icons.email,
          "admin@expo.com",
          showBorder: false,
          fontSize: 14,
        ),
        _buildListTile(
          Icons.location_on,
          tr('kantor_pengelola'),
          showBorder: false,
          fontSize: 14,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return _buildSectionContainer(
      title: tr('pengaturan'),
      children: [
        GestureDetector(
          onTap: () {
            _showContentBottomSheet(
              context,
              tr('visi_misi'),
              tr('visi_misi_content'),
            );
          },
          child: _buildListTile(
            Icons.visibility,
            tr('visi_misi'),
            hasArrow: true,
            isFirst: true,
          ),
        ),
        GestureDetector(
          onTap: () {
            _showContentBottomSheet(
              context,
              tr('ketentuan_privasi'),
              tr('ketentuan_privasi_content'),
            );
          },
          child: _buildListTile(
            Icons.privacy_tip,
            tr('ketentuan_privasi'),
            hasArrow: true,
          ),
        ),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25.0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr('pilih_bahasa'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildLanguageOption(
                            context,
                            'id',
                            'Bahasa Indonesia',
                            'https://flagcdn.com/w40/id.png',
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageOption(
                            context,
                            'en',
                            'English (Beta)',
                            'https://flagcdn.com/w40/us.png',
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageOption(
                            context,
                            'zh',
                            'Mandarin (Beta)',
                            'https://flagcdn.com/w40/cn.png',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ).then((_) => setState(() {}));
          },
          child: _buildListTile(Icons.language, tr('bahasa'), hasArrow: true),
        ),
        GestureDetector(
          onTap: () {
            // Clear storage
            final storage = GetStorage();
            storage.remove("userId");
            storage.remove("role");
            storage.remove("remember_password"); // Prevent auto-login
            // Navigate to login
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SignInMergedPage()),
              (route) => false,
            );
          },
          child: _buildListTile(
            Icons.logout,
            tr('keluar'),
            hasArrow: false,
            isLast: true,
            showBorder: false,
            iconColor: Colors.red,
            textColor: Colors.red,
          ),
        ),
      ],
    );
  }

  void _showContentBottomSheet(
    BuildContext context,
    String title,
    String content,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(thickness: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  content,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A5AF8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    tr('tutup'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String code,
    String name,
    String flagUrl,
  ) {
    final isSelected =
        LocalizationService().localeNotifier.value.languageCode == code;
    return GestureDetector(
      onTap: () {
        LocalizationService().changeLocale(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7A5AF8).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7A5AF8) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7A5AF8).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                flagUrl,
                width: 32,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF7A5AF8) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF7A5AF8),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    bool hasArrow = false,
    bool isFirst = false,
    bool isLast = false,
    bool isSingle = false,
    bool showBorder = true,
    double fontSize = 16,
    Color? iconColor,
    Color? textColor,
    String? trailingText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: (showBorder && !isLast && !isSingle)
            ? const Border(bottom: BorderSide(color: Colors.black12))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF7A5AF8)).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? const Color(0xFF7A5AF8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailingText != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                trailingText,
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor ?? Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (hasArrow)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
