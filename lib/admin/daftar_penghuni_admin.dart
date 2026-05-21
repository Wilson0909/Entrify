import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:expo/admin/detail_penghuni_admin.dart';
import 'package:expo/services/localization_service.dart';

class DaftarPenghuniAdminPage extends StatefulWidget {
  const DaftarPenghuniAdminPage({super.key});

  @override
  State<DaftarPenghuniAdminPage> createState() =>
      _DaftarPenghuniAdminPageState();
}

class _DaftarPenghuniAdminPageState extends State<DaftarPenghuniAdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFF1F3F8)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'user')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(tr('error_loading_vehicles')),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data!.docs;

                      // Filter based on search query
                      final filteredData = data.where((doc) {
                        final userData = doc.data() as Map<String, dynamic>;
                        final name =
                            userData['username']?.toString().toLowerCase() ??
                            '';
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();

                      if (filteredData.isEmpty) {
                        return Center(child: Text(tr('no_residents_found')));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          return _buildResidentCard(filteredData[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Color(0xFFFEFEFE),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7A5AF8), Color(0xFF6744D6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/tambah_penghuni');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                tr('tambah_penghuni'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double maxContentWidth = 600;
        double defaultPadding = 20;
        double horizontalPadding = (screenWidth - maxContentWidth) / 2;

        if (horizontalPadding < defaultPadding) {
          horizontalPadding = defaultPadding;
        }

        double topPadding = MediaQuery.of(context).padding.top + 10;
        if (topPadding < 40) topPadding = 40;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            30,
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
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
                          color: Color(0xFF7A5AF8),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    tr('daftar_penghuni'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Image.asset(
                    'assets/icon-clock.png',
                    width: 40,
                    height: 40,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0), // Light grey background
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.left,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: tr('search_resident_placeholder'),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.search, color: Colors.black54),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResidentCard(DocumentSnapshot doc) {
    final resident = doc.data() as Map<String, dynamic>;
    resident['id'] = doc.id; // Add ID to map
    final String name = resident['username'] ?? tr('no_name');
    final String address = resident['alamat'] ?? tr('no_address');
    final String userId = doc.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8), // Light grey card background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('nama_penghuni'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tr('alamat_penghuni'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // FutureBuilder to count vehicles
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('plat_terdaftar')
                    .where('ownerId', isEqualTo: userId)
                    .get(),
                builder: (context, snapshot) {
                  int vehicleCount = 0;
                  if (snapshot.hasData) {
                    vehicleCount = snapshot.data!.docs.length;
                  }
                  return Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${tr('jumlah_kendaraan')} : $vehicleCount",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailPenghuniAdminPage(resident: resident),
                    ),
                  );
                },
                child: Text(
                  tr('lihat_detail'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
