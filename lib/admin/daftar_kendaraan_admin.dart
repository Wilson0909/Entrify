import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:expo/admin/detail_kendaraan_approval_admin.dart';
import 'package:expo/widgets/page_header.dart';
import 'package:intl/intl.dart';
import 'package:expo/services/localization_service.dart';

class DaftarKendaraanAdminPage extends StatefulWidget {
  final String? initialStatus;
  const DaftarKendaraanAdminPage({super.key, this.initialStatus});

  @override
  State<DaftarKendaraanAdminPage> createState() =>
      _DaftarKendaraanAdminPageState();
}

class _DaftarKendaraanAdminPageState extends State<DaftarKendaraanAdminPage> {
  String _selectedStatus = 'Pending'; // default Menunggu (Review)
  bool _loading = true;

  List<Map<String, dynamic>> _allVehicles = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _selectedStatus = widget.initialStatus!;
    }
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      List<Map<String, dynamic>> allVehicles = [];

      // 1. Fetch Verified from 'plat_terdaftar'
      final verifiedSnap = await FirebaseFirestore.instance
          .collection('plat_terdaftar')
          .orderBy('createdAt', descending: true)
          .get();

      // 2. Fetch Requests from 'kendaraan_request'
      final requestSnap = await FirebaseFirestore.instance
          .collection('kendaraan_request')
          .orderBy('createdAt', descending: true)
          .get();

      // 3. Fetch Rejected from 'plat_ditolak'
      final rejectedSnap = await FirebaseFirestore.instance
          .collection('plat_ditolak')
          .orderBy('rejectedAt', descending: true)
          .get();

      // Collect all owner IDs from requests, rejected AND verified
      final Set<String> ownerIds = {};

      for (var doc in requestSnap.docs) {
        final id = doc.data()['ownerId'] as String?;
        if (id != null && id.isNotEmpty) ownerIds.add(id);
      }

      for (var doc in rejectedSnap.docs) {
        final id = doc.data()['ownerId'] as String?;
        if (id != null && id.isNotEmpty) ownerIds.add(id);
      }

      for (var doc in verifiedSnap.docs) {
        final id = doc.data()['ownerId'] as String?;
        if (id != null && id.isNotEmpty) ownerIds.add(id);
      }

      final Map<String, String> ownerNames = {};
      if (ownerIds.isNotEmpty) {
        for (var id in ownerIds) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .get();
          if (userDoc.exists) {
            final data = userDoc.data();
            ownerNames[id] =
                data?['nama'] ?? data?['username'] ?? tr('unknown');
          }
        }
      }

      final verifiedVehicles = verifiedSnap.docs.map((doc) {
        final d = doc.data();
        final ownerId = d['ownerId'] ?? '';
        final ownerName = ownerNames[ownerId] ?? tr('unknown');

        return {
          'id': doc.id,
          'plate': d['plat'] ?? '',
          'owner': ownerName,
          'vehicleName': d['merk'] ?? '',
          'color': "N/A",
          'type': d['jenis'] ?? '',
          'status': 'Approved',
          'date': d['createdAt'] != null
              ? (d['createdAt'] as Timestamp).toDate()
              : null,
          'kategori': d['kategori'] ?? '',
          'keterangan': d['kategori'] ?? '',
          'foto': d['fotoUrl'] ?? 'assets/car.png',
          'ownerId': ownerId,
          'submittedDate': d['createdAt'] != null
              ? (d['createdAt'] as Timestamp).toDate().toString()
              : '',
          'createdAt': d['createdAt'] != null
              ? DateFormat(
                  'd MMM yyyy, HH:mm',
                  LocalizationService().localeNotifier.value.languageCode,
                ).format((d['createdAt'] as Timestamp).toDate())
              : '-',
        };
      }).toList();

      allVehicles.addAll(verifiedVehicles);

      // 2. Fetch Requests from 'kendaraan_request' (Already done above but flow logic changed)
      // We moved ownerId collection up. So we just proceed to processing.

      // Process Pending Requests
      final requestVehicles = requestSnap.docs
          .map((doc) {
            final d = doc.data();
            String rawStatus =
                d['status']?.toString().toLowerCase() ?? 'pending';

            // STRICTLY IGNORE APPROVED/VERIFIED/REJECTED from requests
            if (rawStatus == 'approved' ||
                rawStatus == 'verified' ||
                rawStatus == 'rejected') {
              return null;
            }

            final ownerId = d['ownerId'] ?? '';
            final ownerName = ownerNames[ownerId] ?? tr('unknown_user');

            return {
              'id': doc.id,
              'plate': d['plat'] ?? '',
              'owner': ownerName,
              'vehicleName': d['merk'] ?? '',
              'color': "N/A",
              'type': d['jenis'] ?? '',
              'status': 'Pending',
              'date': d['createdAt'] != null
                  ? (d['createdAt'] as Timestamp).toDate()
                  : null,
              'kategori': d['kategori'] ?? '',
              'kedatangan': d['kedatangan'],
              'keterangan': d['kategori'] ?? '',
              'foto': 'assets/car.png',
              'ownerId': ownerId,
              'submittedDate': d['createdAt'] != null
                  ? (d['createdAt'] as Timestamp).toDate().toString()
                  : '',
              'createdAt': d['createdAt'] != null
                  ? DateFormat(
                      'd MMM yyyy, HH:mm',
                      LocalizationService().localeNotifier.value.languageCode,
                    ).format((d['createdAt'] as Timestamp).toDate())
                  : '-',
            };
          })
          .where((e) => e != null)
          .cast<Map<String, dynamic>>()
          .toList();

      allVehicles.addAll(requestVehicles);

      // Process Rejected Vehicles
      final rejectedVehicles = rejectedSnap.docs.map((doc) {
        final d = doc.data();
        final ownerId = d['ownerId'] ?? '';
        final ownerName = ownerNames[ownerId] ?? tr('unknown_user');

        return {
          'id': doc.id,
          'plate': d['plat'] ?? '',
          'owner': ownerName,
          'vehicleName': d['merk'] ?? '',
          'color': "N/A",
          'type': d['jenis'] ?? '',
          'status': 'Rejected',
          'date': d['rejectedAt'] != null
              ? (d['rejectedAt'] as Timestamp).toDate()
              : null,
          'kategori': d['kategori'] ?? '',
          'kedatangan': d['kedatangan'],
          'keterangan': d['kategori'] ?? '',
          'foto': d['fotoUrl'] ?? 'assets/car.png',
          'ownerId': ownerId,
          'submittedDate': d['rejectedAt'] != null
              ? (d['rejectedAt'] as Timestamp).toDate().toString()
              : '',
          'createdAt': d['rejectedAt'] != null
              ? DateFormat(
                  'd MMM yyyy, HH:mm',
                  LocalizationService().localeNotifier.value.languageCode,
                ).format((d['rejectedAt'] as Timestamp).toDate())
              : '-',
        };
      }).toList();

      allVehicles.addAll(rejectedVehicles);

      // Sort by date descending
      allVehicles.sort((a, b) {
        DateTime? dateA = a['date'];
        DateTime? dateB = b['date'];
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        _allVehicles = allVehicles;
        _loading = false;
      });

      print("🔥 Data Loaded: ${allVehicles.length}");
    } catch (e) {
      print("ERROR LOAD VEHICLES: $e");
    }
  }

  Future<void> approveRequest(String docId, Map<String, dynamic> data) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1️⃣ Update status di kendaraan_request
      await firestore.collection('kendaraan_request').doc(docId).update({
        'status': 'Approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Masukkan data ke collection plat_terdaftar (pakai field yg BENER)
      await firestore.collection('plat_terdaftar').add({
        'plat': data['plate'], // dari _loadVehicles
        'merk': data['vehicleName'], // merk = vehicleName (brand) not owner
        'jenis': data['type'], // jenis kendaraan
        'ownerId': data['ownerId'], // ownerId asli
        'createdAt': data['date'], // tanggal submit
        'approvedAt': FieldValue.serverTimestamp(),
        'keterangan': data['kategori'],
      });

      print("⭐ APPROVED & DIPINDAHKAN ke plat_terdaftar");

      // optional: refresh UI
      await _loadVehicles();
      setState(() {});
    } catch (e) {
      print("🔥 ERROR APPROVE: $e");
    }
  }

  List<Map<String, dynamic>> get _filteredVehicles {
    return _allVehicles.where((v) {
      return v['status'] == _selectedStatus;
    }).toList();
  }

  int get _totalCount => _allVehicles.length;
  int get _reviewCount =>
      _allVehicles.where((v) => v['status'] == 'Pending').length;
  int get _verifiedCount =>
      _allVehicles.where((v) => v['status'] == 'Approved').length;
  int get _rejectedCount =>
      _allVehicles.where((v) => v['status'] == 'Rejected').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      body: Stack(
        children: [
          PageHeader(
            title: tr('daftar_kendaraan').replaceAll('\n', ' '),
            rightIcon: null,
            titleTopPadding: 16.0,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildStatsSection(),
                                const SizedBox(height: 20),
                                _buildStatusTabs(),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      100,
                                    ),
                                    itemCount: _filteredVehicles.length,
                                    itemBuilder: (context, index) {
                                      return _buildVehicleCard(
                                        _filteredVehicles[index],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
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

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('daftar_kendaraan').replaceAll('\n', ' '),
            style: const TextStyle(
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
                  tr('semua'),
                  _totalCount.toString(),
                  const Color(0xFF7A5AF8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  tr('pending'),
                  _reviewCount.toString(),
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
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabItem(tr('pending'), "Pending", _reviewCount, Colors.orange),
          _buildTabItem(
            tr('approved'),
            "Approved",
            _verifiedCount,
            Colors.green,
          ),
          _buildTabItem(tr('rejected'), "Rejected", _rejectedCount, Colors.red),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    String label,
    String statusValue,
    int count,
    Color badgeColor,
  ) {
    final isSelected = _selectedStatus == statusValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedStatus = statusValue);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black87 : Colors.black54,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    Color statusColor;
    String statusText;
    // Normalize status to lowercase for comparison
    String status = vehicle['status']?.toString().toLowerCase() ?? 'pending';

    switch (status) {
      case "approved":
      case "verified":
        statusColor = Colors.green;
        statusText = tr('approved');
        break;
      case "rejected":
        statusColor = Colors.red;
        statusText = tr('rejected');
        break;
      default:
        statusColor = Colors.orange;
        statusText = tr('pending');
    }

    String formattedDate = "";
    if (vehicle['date'] != null && vehicle['date'] is DateTime) {
      formattedDate = DateFormat(
        'd MMM yyyy',
        LocalizationService().localeNotifier.value.languageCode,
      ).format(vehicle['date']);
    }

    String dateLabel = status == 'approved' || status == 'verified'
        ? tr('approved_at')
        : tr('submitted_at');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailKendaraanApprovalAdminPage(vehicle: vehicle),
          ),
        ).then((_) => _loadVehicles()); // refresh setelah approve/reject
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFEFE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Builder(
                  builder: (context) {
                    bool isCar =
                        (vehicle['type'] ?? '').toString().toLowerCase() ==
                        'mobil';
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
                      // Plate + see details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            vehicle['plate'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                tr('lihat_detail'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 14),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('nama_pemilik'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicle['owner'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('jenis_kendaraan'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(vehicle['type'].toString().toLowerCase()),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: status == 'approved' || status == 'verified'
                          ? Colors.green
                          : (status == 'rejected' ? Colors.red : Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$dateLabel $formattedDate",
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 'approved' || status == 'verified'
                            ? Colors.green
                            : (status == 'rejected' ? Colors.red : Colors.grey),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      tr('uploaded_by'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(
                        Icons.person,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vehicle['owner'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
