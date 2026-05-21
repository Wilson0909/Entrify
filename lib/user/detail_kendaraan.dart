import 'package:flutter/material.dart';
import 'package:expo/widgets/appbarback.dart';
import 'package:expo/services/localization_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class DetailKendaraanPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailKendaraanPage({super.key, required this.data});

  @override
  @override
  Widget build(BuildContext context) {
    final String statusText = data['status'] ?? '-';
    final bool isExit =
        statusText.toLowerCase() == 'keluar' ||
        statusText.toLowerCase() == 'keluar_status';
    print("Detail Data: $data"); // Debug print

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
                          style: const TextStyle(
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
                            color: isExit
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isExit ? Colors.red : Colors.green,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isExit ? Icons.logout : Icons.login,
                                size: 16,
                                color: isExit ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isExit
                                    ? tr('keluar_status')
                                    : tr(statusText.toLowerCase()),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isExit ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Detail Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _fetchVehicleDetails(data['plat'] ?? ''),
                      builder: (context, snapshot) {
                        String ownerName = tr('memuat');
                        String jenis = tr('memuat');
                        String date = tr('memuat');

                        if (snapshot.hasData) {
                          ownerName = snapshot.data!['ownerName'] ?? '-';
                          jenis = tr(
                            snapshot.data!['jenis']?.toString().toLowerCase() ??
                                '-',
                          );
                          date = snapshot.data!['date'] ?? '-';
                        } else if (snapshot.hasError) {
                          ownerName = "-";
                          jenis = "-";
                          date = "-";
                        } else if (snapshot.connectionState ==
                                ConnectionState.done &&
                            !snapshot.hasData) {
                          ownerName = "-";
                          jenis = "-";
                          date = "-";
                        }

                        return Column(
                          children: [
                            _buildDetailField(tr('nama_pemilik'), ownerName),
                            const SizedBox(height: 12),
                            _buildDetailField(
                              tr('plat_kendaraan'),
                              data['plat'] ?? '-',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailField(tr('jenis_kendaraan'), jenis),
                            const SizedBox(height: 12),
                            _buildDetailField(tr('tanggal_waktu'), date),
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
    );
  }

  Widget _buildDetailField(String label, String value) {
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
          Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchVehicleDetails(String plat) async {
    if (plat.isEmpty) return {};
    try {
      Map<String, dynamic>? vehicleData;

      // 1. Cari kendaraan di kendaraan_request berdasarkan plat
      var vehicleQuery = await FirebaseFirestore.instance
          .collection('kendaraan_request')
          .where('plat', isEqualTo: plat)
          .limit(1)
          .get();

      if (vehicleQuery.docs.isNotEmpty) {
        vehicleData = vehicleQuery.docs.first.data();
      } else {
        // 2. Jika tidak ada, cari di plat_terdaftar
        var platQuery = await FirebaseFirestore.instance
            .collection('plat_terdaftar')
            .where('plat', isEqualTo: plat)
            .limit(1)
            .get();

        if (platQuery.docs.isNotEmpty) {
          vehicleData = platQuery.docs.first.data();
        } else {
          // 3. Jika tidak ada, cari di plat_ditolak
          var rejectedQuery = await FirebaseFirestore.instance
              .collection('plat_ditolak')
              .where('plat', isEqualTo: plat)
              .limit(1)
              .get();

          if (rejectedQuery.docs.isNotEmpty) {
            vehicleData = rejectedQuery.docs.first.data();
          }
        }
      }

      if (vehicleData == null) return {};

      final ownerId = vehicleData['ownerId'];
      final jenis = vehicleData['jenis'] ?? '-';

      // Format Date
      String dateStr = '-';

      // Use passed date (Log Time) if available
      if (data['date'] != null) {
        dateStr = data['date'];
      }
      // Fallback to createdAt (Registration Time)
      else if (vehicleData['createdAt'] != null) {
        if (vehicleData['createdAt'] is Timestamp) {
          DateTime dt = (vehicleData['createdAt'] as Timestamp).toDate();
          dateStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
        } else {
          dateStr = vehicleData['createdAt'].toString();
        }
      }

      // 3. Cari nama user di users berdasarkan ownerId
      String ownerName = '-';
      if (ownerId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          ownerName = userData['nama'] ?? userData['username'] ?? '-';
        }
      }

      return {'ownerName': ownerName, 'jenis': jenis, 'date': dateStr};
    } catch (e) {
      print("Error fetching vehicle details: $e");
      return {};
    }
  }
}
