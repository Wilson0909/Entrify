import 'package:flutter/material.dart';
import 'package:expo/services/localization_service.dart';
import 'package:expo/widgets/button.dart';
import 'package:expo/user/tambah_kendaraan.dart';
import 'package:expo/user/detail_kendaraan_view.dart';
import 'package:expo/widgets/page_header.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DaftarKendaraanPage extends StatefulWidget {
  final int initialFilter;
  const DaftarKendaraanPage({super.key, this.initialFilter = 0});

  @override
  State<DaftarKendaraanPage> createState() => _DaftarKendaraanPageState();
}

class _DaftarKendaraanPageState extends State<DaftarKendaraanPage> {
  late int _selectedFilter;
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final storage = GetStorage();
    final userId = storage.read("userId");

    if (userId == null) {
      print("❌ userId tidak ditemukan di GetStorage");
      return;
    }

    try {
      List<Map<String, dynamic>> allVehicles = [];

      // 1. Fetch Verified Vehicles from 'plat_terdaftar'
      final verifiedSnap = await FirebaseFirestore.instance
          .collection('plat_terdaftar')
          .where('ownerId', isEqualTo: userId)
          .get();

      final verifiedData = verifiedSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'licensePlate': d['plat'] ?? tr('unknown'),
          'status': 'Verified',
          'statusColor': Colors.green,
          'ownerName': d['merk'] ?? '-', // Merk as owner name placeholder
          'address': d['jenis'] ?? '-',
          'type': d['jenis'] ?? '-',
          'arrivalDate': d['createdAt'] != null
              ? (d['createdAt'] as Timestamp).toDate().toString()
              : '-',
          'kategori': d['kategori'] ?? 'Penghuni', // Added category
        };
      }).toList();

      allVehicles.addAll(verifiedData);

      // 2. Fetch Pending Requests from 'kendaraan_request'
      final requestSnap = await FirebaseFirestore.instance
          .collection('kendaraan_request')
          .where('ownerId', isEqualTo: userId)
          .get();

      final requestData = requestSnap.docs
          .map((doc) {
            final d = doc.data();
            String rawStatus =
                d['status']?.toString().toLowerCase() ?? 'pending';
            String normalizedStatus = 'Pending';
            String plate = d['plat'] ?? tr('unknown');

            // Check for expired Tamu vehicles
            if (d['kategori'] == 'Tamu' && d['createdAt'] != null) {
              final createdAt = (d['createdAt'] as Timestamp).toDate();
              final now = DateTime.now();
              if (now.difference(createdAt).inHours >= 24) {
                // Lazy delete
                FirebaseFirestore.instance
                    .collection('kendaraan_request')
                    .doc(doc.id)
                    .delete();
                return null; // Skip adding to list
              }
            }

            // STRICTLY IGNORE APPROVED/VERIFIED/REJECTED from requests
            if (rawStatus == 'approved' ||
                rawStatus == 'verified' ||
                rawStatus == 'rejected') {
              return null;
            }

            return {
              'id': doc.id,
              'licensePlate': plate,
              'status': normalizedStatus,
              'statusColor': _getStatusColor(normalizedStatus),
              'ownerName': d['merk'] ?? '-',
              'address': d['jenis'] ?? '-',
              'type': d['jenis'] ?? '-',
              'arrivalDate': d['createdAt'] != null
                  ? (d['createdAt'] as Timestamp).toDate().toString()
                  : '-',
              'kategori':
                  d['kategori'], // Pass kategori for filtering if needed
            };
          })
          .where((e) => e != null)
          .cast<Map<String, dynamic>>()
          .toList();

      allVehicles.addAll(requestData);

      // 3. Fetch Rejected from 'plat_ditolak'
      final rejectedSnap = await FirebaseFirestore.instance
          .collection('plat_ditolak')
          .where('ownerId', isEqualTo: userId)
          .get();

      final rejectedData = rejectedSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'licensePlate': d['plat'] ?? tr('unknown'),
          'status': 'Rejected',
          'statusColor': Colors.red,
          'ownerName': d['merk'] ?? '-',
          'address': d['jenis'] ?? '-',
          'type': d['jenis'] ?? '-',
          'arrivalDate': d['rejectedAt'] != null
              ? (d['rejectedAt'] as Timestamp).toDate().toString()
              : '-',
          'kategori': d['kategori'] ?? '',
        };
      }).toList();

      allVehicles.addAll(rejectedData);

      setState(() {
        _vehicles = allVehicles;
        _loading = false;
      });
    } catch (e) {
      print("🔥 ERROR GET VEHICLES: $e");
    }
  }

  Color _getStatusColor(String? s) {
    switch (s) {
      case "Verified":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange; // Pending / Unverified
    }
  }

  List<Map<String, dynamic>> get _filteredVehicles {
    final filterStatus = ['Pending', 'Verified', 'Rejected'][_selectedFilter];
    return _vehicles.where((v) => v['status'] == filterStatus).toList();
  }

  int get _pendingCount =>
      _vehicles.where((v) => v['status'] == 'Pending').length;
  int get _verifiedCount =>
      _vehicles.where((v) => v['status'] == 'Verified').length;
  int get _rejectedCount =>
      _vehicles.where((v) => v['status'] == 'Rejected').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      body: Column(
        children: [
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: PageHeader(
                  title: tr('kendaraanku'),
                  titleTopPadding: 16,
                  showBackButton: true,
                  rightIcon: Image.asset(
                    'assets/icon-list.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 120), // Adjusted for header height
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          children: [
                            _buildStatsSection(),
                            const SizedBox(height: 20),
                            _buildFilterSection(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildVehicleList(),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return _responsiveBox(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('daftar_kendaraan'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    tr('pending'),
                    _pendingCount.toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    tr('verified'),
                    _verifiedCount.toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildFilterSection() {
    return _responsiveBox(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Color(0xFFFEFEFE),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(child: _buildFilterChip(tr('pending'), 0, _pendingCount)),
            const SizedBox(width: 6),
            Expanded(
              child: _buildFilterChip(tr('verified'), 1, _verifiedCount),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildFilterChip(tr('rejected'), 2, _rejectedCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7A5AF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? (index == 1
                          ? Colors.green
                          : const Color.fromARGB(255, 241, 144, 87))
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _filteredVehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    String displayStatus = tr(vehicle['status'].toString().toLowerCase());
    if (vehicle['status'] == 'Verified' &&
        vehicle['kategori'] != null &&
        vehicle['kategori'].toString().isNotEmpty) {
      displayStatus = tr(vehicle['kategori'].toString().toLowerCase());
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailKendaraanViewPage(vehicleId: vehicle['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFEFEFE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon Container
            Builder(
              builder: (context) {
                bool isCar =
                    (vehicle['type'] ?? '').toString().toLowerCase() == 'mobil';
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCar
                        ? const Color(0xFFE0E7FF) // Light Indigo for Car
                        : const Color(0xFFDCFCE7), // Light Green for Bike
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCar ? Icons.directions_car_filled : Icons.two_wheeler,
                    color: isCar
                        ? const Color(0xFF4338CA) // Indigo for Car
                        : const Color(0xFF15803D), // Green for Bike
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['licensePlate'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: vehicle['statusColor'],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: vehicle['statusColor'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: CustomButton(
          text: tr('tambah_kendaraan'),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TambahKendaraanPage(),
              ),
            );
            _loadVehicles();
          },
        ),
      ),
    );
  }

  Widget _responsiveBox({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double maxContentWidth = 600;
        double defaultPadding = 20;
        double horizontalPadding = (screenWidth - maxContentWidth) / 2;

        if (horizontalPadding < defaultPadding) {
          horizontalPadding = defaultPadding;
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        );
      },
    );
  }
}
