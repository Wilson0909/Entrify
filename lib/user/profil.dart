import 'package:flutter/material.dart';
import 'package:expo/services/localization_service.dart';
import 'package:expo/user/daftar_kendaraan.dart';
import 'package:expo/user/notifikasi.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String _userName = "";
  String _phone = "-";
  String _address = "-";
  int _unverifiedCount = 0;
  int _verifiedCount = 0;

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
      // 1. Fetch User Profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      String name = tr('user');
      String phone = "-";
      String address = "-";
      if (userDoc.exists) {
        final data = userDoc.data();
        name = data?['nama'] ?? data?['username'] ?? tr('user');

        var hp = data?['no_hp'];
        if (hp != null && hp.toString().trim().isNotEmpty) {
          phone = hp.toString();
        }

        var addr = data?['alamat'];
        if (addr != null && addr.toString().trim().isNotEmpty) {
          address = addr.toString();
        }
      }

      // 2. Fetch Verified Count from 'plat_terdaftar'
      final verifiedSnap = await FirebaseFirestore.instance
          .collection('plat_terdaftar')
          .where('ownerId', isEqualTo: userId)
          .get();

      int verified = verifiedSnap.docs.length;

      // 3. Fetch Pending Count from 'kendaraan_request'
      final requestSnap = await FirebaseFirestore.instance
          .collection('kendaraan_request')
          .where('ownerId', isEqualTo: userId)
          .get();

      int unverified = 0;
      for (var doc in requestSnap.docs) {
        final data = doc.data();
        final rawStatus = data['status']?.toString().toLowerCase() ?? 'pending';

        // Only count as unverified if status is 'pending'
        // Ignore 'approved', 'verified', 'rejected'
        if (rawStatus != 'approved' &&
            rawStatus != 'verified' &&
            rawStatus != 'rejected') {
          unverified++;
        }
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _phone = phone;
          _address = address;
          _unverifiedCount = unverified;
          _verifiedCount = verified;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
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
                        color: Color(
                          0xFFF1F3F8,
                        ), // Background color for the card
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
                              const SizedBox(height: 80), // Space for avatar
                              _buildProfileInfo(),
                              const SizedBox(height: 20),
                              _buildStatsSection(context),
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
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  tr('tentang_saya'),
                                  style: const TextStyle(
                                    color: Color(0xFFFEFEFE),
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('notifications')
                                      .where(
                                        'userId',
                                        isEqualTo: GetStorage().read('userId'),
                                      )
                                      .where('isRead', isEqualTo: false)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    int unreadCount = 0;
                                    if (snapshot.hasData) {
                                      unreadCount = snapshot.data!.docs.length;
                                    }
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.notifications_none,
                                            color: Color(0xFFFEFEFE),
                                            size: 28,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const NotifikasiPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 11,
                                            top: 11,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 12,
                                                minHeight: 12,
                                              ),
                                              child: Text(
                                                '$unreadCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
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
          tr('penghuni'),
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF7A5AF8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('kendaraanku'),
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
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DaftarKendaraanPage(initialFilter: 0),
                        ),
                      ).then((_) => _fetchUserData());
                    },
                    child: _buildStatCard(
                      tr('unverified'),
                      _unverifiedCount.toString(),
                      Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DaftarKendaraanPage(initialFilter: 1),
                        ),
                      ).then((_) => _fetchUserData());
                    },
                    child: _buildStatCard(
                      tr('verified'),
                      _verifiedCount.toString(),
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
        color: const Color(0xFFDCDCDC), // Slightly darker grey for inner cards
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
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
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
        _buildListTile(Icons.phone, _phone, showBorder: false, fontSize: 14),
        _buildListTile(
          Icons.location_on,
          _address,
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
          onTap: () async {
            final storage = GetStorage();
            await storage.erase();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (Route<dynamic> route) => false,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildFormattedContent(content),
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
          if (hasArrow)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  List<Widget> _buildFormattedContent(String content) {
    List<Widget> widgets = [];
    List<String> lines = content.split('\n');
    final RegExp numberedListRegex = RegExp(r'^(\d+\.)\s+(.*)');

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      final match = numberedListRegex.firstMatch(line.trim());
      if (match != null) {
        // It's a numbered list item
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24, // Fixed width for number
                  child: Text(
                    match.group(1)!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.group(2)!,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Regular text
        bool isHeader =
            line.endsWith(':') ||
            line.contains('Visi:') ||
            line.contains('Misi:') ||
            line.contains('Vision:') ||
            line.contains('Mission:') ||
            line.contains('愿景：') ||
            line.contains('使命：');

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              line,
              textAlign: isHeader ? TextAlign.left : TextAlign.justify,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
