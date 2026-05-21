import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:expo/widgets/admin_bottom_navbar.dart';
import 'package:expo/admin/admin_pengumuman.dart';
import 'package:expo/admin/riwayat_kendaraan_admin.dart';

import 'package:expo/admin/profil_admin.dart';
import 'package:expo/admin/detail_pengumuman.dart';
import 'package:expo/services/localization_service.dart';
import 'package:intl/intl.dart';

class AdminHomePage extends StatefulWidget {
  final int initialIndex;
  const AdminHomePage({super.key, this.initialIndex = 0});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHomeContent(),
          const AdminPengumumanPage(),
          const RiwayatKendaraanAdminPage(),
          const ProfilAdminPage(),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        _buildHeader(),
        Positioned.fill(
          child: Column(
            children: [
              const SizedBox(height: 130),
              _buildMenuUtama(context),
              const SizedBox(height: 20),
              Expanded(child: _buildPengumuman(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double maxContentWidth = 600;
        double defaultPadding = 16;
        double horizontalPadding = (screenWidth - maxContentWidth) / 2;

        if (horizontalPadding < defaultPadding) {
          horizontalPadding = defaultPadding;
        }

        return Container(
          width: double.infinity,
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF795FFC), Color(0xFF7155FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: 60,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            child: SizedBox(
              width: screenWidth < maxContentWidth
                  ? screenWidth - horizontalPadding * 2
                  : maxContentWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${tr('halo')}, ${tr('admin')}!",
                          style: const TextStyle(
                            color: Color(0xFFFEFEFE),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          tr('selamat_datang'),
                          style: const TextStyle(
                            color: Color(0xFFFEFEFE),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-10, -10),
                    child: Image.asset(
                      "assets/logo.png",
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuUtama(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 30, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFFFEFEFE),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  tr('menu_utama'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _menuItem(
                    icon: Icons.people,
                    title: tr('kelola_penghuni'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/daftar_penghuni');
                    },
                  ),
                  _menuItem(
                    icon: Icons.directions_car,
                    title: tr('kelola_kendaraan'),
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/daftar_kendaraan');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: Colors.blueGrey),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPengumuman(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFFEFEFE),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('pengumuman'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _onItemTapped(1); // Switch to Pengumuman tab
                    },
                    child: Text(
                      tr('see_more'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr('info_pengumuman'),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pengumuman')
                      .where(
                        'tanggal_kegiatan',
                        isGreaterThanOrEqualTo: DateTime.now(),
                      )
                      .orderBy('tanggal_kegiatan')
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(tr('error_loading_announcements')),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(tr('tidak_ada_pengumuman')));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var data =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        return _pengumumanItem(data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pengumumanItem(Map<String, dynamic> data) {
    String title = data['judul'] ?? tr('no_title');
    Timestamp? timestamp = data['tanggal_kegiatan'] as Timestamp?;
    String dateStr = timestamp != null
        ? DateFormat(
            'd/M/yyyy',
            LocalizationService().localeNotifier.value.languageCode,
          ).format(timestamp.toDate())
        : "-";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPengumumanPage(data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                (data['gambar'] != null && data['gambar'].toString().isNotEmpty)
                    ? data['gambar']
                    : 'assets/gotongroyong.png',
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/gotongroyong.png',
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
