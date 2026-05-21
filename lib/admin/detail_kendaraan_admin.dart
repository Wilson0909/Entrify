import 'package:flutter/material.dart';
import 'package:expo/widgets/appbarback.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:expo/services/localization_service.dart';

class DetailKendaraanAdminPage extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const DetailKendaraanAdminPage({super.key, required this.vehicle});

  @override
  State<DetailKendaraanAdminPage> createState() =>
      _DetailKendaraanAdminPageState();
}

class _DetailKendaraanAdminPageState extends State<DetailKendaraanAdminPage> {
  late String _ownerName;
  late String _vehicleType;
  late String _plate;

  String _merk = '-';
  String _keterangan = '-';
  String _foto = '';
  String _registeredDate = '-';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("🔥 Detail Kendaraan Page OPENED!");
    print("Vehicle data received: ${widget.vehicle}");

    _plate = widget.vehicle['plat'] ?? widget.vehicle['plate'] ?? '';
    _ownerName = widget.vehicle['owner'] ?? '-';
    _vehicleType = widget.vehicle['jenis'] ?? widget.vehicle['type'] ?? '-';

    print("Plat extracted: $_plate");

    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final vehicleId = widget.vehicle['id'];

      if (vehicleId == null && _plate.isEmpty) {
        print("⚠️ ID dan Plat kendaraan kosong! Stop fetch.");
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic>? data;
      String? ownerId;

      // 1. Try fetching by ID from kendaraan_request (most reliable for pending/rejected)
      if (vehicleId != null) {
        print("🔍 Mencari di kendaraan_request dengan ID: $vehicleId");
        final reqDoc = await FirebaseFirestore.instance
            .collection('kendaraan_request')
            .doc(vehicleId)
            .get();

        if (reqDoc.exists) {
          print("📌 Data ditemukan di kendaraan_request (by ID)!");
          data = reqDoc.data();
          ownerId = data?['ownerId'];
        }
      }

      // 2. If not found or no ID, try plat_terdaftar by Plate (for verified)
      if (data == null && _plate.isNotEmpty) {
        print("🔍 Mencari di collection plat_terdaftar by Plate: $_plate");
        final platSnap = await FirebaseFirestore.instance
            .collection('plat_terdaftar')
            .where('plat', isEqualTo: _plate)
            .limit(1)
            .get();

        if (platSnap.docs.isNotEmpty) {
          print("📌 Data ditemukan di plat_terdaftar!");
          data = platSnap.docs.first.data();
          ownerId = data?['ownerId'];
        }
      }

      // 3. If still not found, try kendaraan_request by Plate (fallback)
      if (data == null && _plate.isNotEmpty) {
        print("🔍 Mencari di kendaraan_request by Plate: $_plate");
        final reqSnap = await FirebaseFirestore.instance
            .collection('kendaraan_request')
            .where('plat', isEqualTo: _plate)
            .limit(1)
            .get();

        if (reqSnap.docs.isNotEmpty) {
          print("📌 Data ditemukan di kendaraan_request (by Plate)!");
          data = reqSnap.docs.first.data();
          ownerId = data?['ownerId'];
        }
      }

      if (data != null) {
        print("📦 Data kendaraan ditemukan: $data");
        final d = data;

        setState(() {
          _vehicleType = d['jenis'] ?? _vehicleType;
          _merk = d['merk'] ?? '-';
          _keterangan = d['keterangan'] ?? '-';
          _foto =
              d['foto'] ?? d['stnkUrl'] ?? ''; // Handle stnkUrl from request

          if (d['createdAt'] != null) {
            if (d['createdAt'] is Timestamp) {
              _registeredDate = DateFormat(
                'd MMM yyyy, HH:mm',
                LocalizationService().localeNotifier.value.languageCode,
              ).format((d['createdAt'] as Timestamp).toDate());
            } else {
              _registeredDate = d['createdAt'].toString();
            }
          }
        });

        if (ownerId != null) {
          print("🔍 Cari owner dengan ID: $ownerId");

          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .get();

          if (userSnap.exists) {
            final userData = userSnap.data();
            print("👤 Data owner ditemukan: $userData");

            setState(() {
              // Prefer 'nama', fallback to 'username'
              _ownerName =
                  userData?['nama'] ?? userData?['username'] ?? _ownerName;
            });
          } else {
            print("⚠️ Owner dengan ID $ownerId tidak ditemukan");
          }
        } else {
          print("⚠️ OwnerId tidak ada di data kendaraan");
        }
      } else {
        print("❌ Data kendaraan tidak ditemukan dimanapun");
      }
    } catch (e) {
      print("❌ ERROR saat fetch details: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print("✔ Fetch selesai");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.vehicle['status']?.toString().toLowerCase() ?? '';
    final isKeluar = status == 'keluar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBarBack(
        title: tr('detail_kendaraan'),
        gradient: const LinearGradient(
          colors: [Color(0xFF795FFC), Color(0xFF7155FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('status'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isKeluar
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isKeluar ? Colors.red : Colors.green,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isKeluar ? Icons.logout : Icons.login,
                                size: 16,
                                color: isKeluar ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.vehicle['status'] ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isKeluar ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_foto.isNotEmpty && _foto != 'assets/car.png')
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(_foto),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),

                              _buildDetailBox(tr('nama_pemilik'), _ownerName),
                              const SizedBox(height: 12),
                              _buildDetailBox(tr('plat_kendaraan'), _plate),
                              const SizedBox(height: 12),
                              _buildDetailBox(
                                tr('jenis_kendaraan'),
                                tr(_vehicleType.toLowerCase()),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailBox(
                                tr('tanggal_waktu'),
                                widget.vehicle['date'] ?? '-',
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
