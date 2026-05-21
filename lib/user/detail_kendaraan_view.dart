import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expo/services/localization_service.dart';
import 'package:intl/intl.dart';
import 'package:expo/widgets/appbarback.dart';

class DetailKendaraanViewPage extends StatefulWidget {
  final String vehicleId;

  const DetailKendaraanViewPage({super.key, required this.vehicleId});

  @override
  State<DetailKendaraanViewPage> createState() =>
      _DetailKendaraanViewPageState();
}

class _DetailKendaraanViewPageState extends State<DetailKendaraanViewPage> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final vehicleDoc = await FirebaseFirestore.instance
        .collection('kendaraan_request')
        .doc(widget.vehicleId)
        .get();

    if (!vehicleDoc.exists) {
      // Try fetching from 'plat_terdaftar' if not found in requests
      final verifiedDoc = await FirebaseFirestore.instance
          .collection('plat_terdaftar')
          .doc(widget.vehicleId)
          .get();

      if (!verifiedDoc.exists) {
        throw Exception(tr('vehicle_not_found'));
      }

      // Use verified doc data
      final vehicleData = verifiedDoc.data() as Map<String, dynamic>;
      // Ensure status is set to Verified for display
      vehicleData['status'] = 'Verified';

      return _fetchUserData(vehicleData);
    }

    if (vehicleDoc.exists) {
      final data = vehicleDoc.data() as Map<String, dynamic>;
      // Check for auto-deletion if Tamu
      if (data['kategori'] == 'Tamu' && data['createdAt'] != null) {
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(createdAt);

        if (difference.inHours >= 24) {
          // Auto delete
          await FirebaseFirestore.instance
              .collection('kendaraan_request')
              .doc(widget.vehicleId)
              .delete();

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(tr('guest_data_expired'))));
          }
          throw Exception(tr('vehicle_expired'));
        }
      }
      return _fetchUserData(data);
    }

    return _fetchUserData(vehicleDoc.data() as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _fetchUserData(
    Map<String, dynamic> vehicleData,
  ) async {
    final ownerId = vehicleData['ownerId'];

    Map<String, dynamic>? userData;
    if (ownerId != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      if (userDoc.exists) {
        userData = userDoc.data();
      }
    }

    return {'vehicle': vehicleData, 'user': userData};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBarBack(
        title: tr('detail_kendaraan'),
        gradient: const LinearGradient(
          colors: [Color(0xFF795FFC), Color(0xFF7155FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text(tr('tidak_ada_data')));
          }

          final vehicleData = snapshot.data!['vehicle'];
          final userData = snapshot.data!['user'];

          // Get owner name: try 'nama' then 'username' from user data, fallback to 'merk' or '-'
          String namaPemilik = '-';

          if (userData != null) {
            namaPemilik = userData['nama'] ?? userData['username'] ?? '-';
          } else {
            // Fallback if user not found but we have vehicle data (though unlikely if ownerId exists)
            namaPemilik = vehicleData['merk'] ?? '-';
          }

          final jenisKendaraan = vehicleData['jenis'] ?? '-';
          final status = vehicleData['status'] ?? 'Pending';
          final platKendaraan = vehicleData['plat'] ?? '-';
          final fotoUrl =
              vehicleData['foto_kendaraan'] ?? vehicleData['stnkUrl'];
          final kedatangan = vehicleData['createdAt'] != null
              ? DateFormat(
                  'dd MMM yyyy, HH:mm',
                ).format((vehicleData['createdAt'] as Timestamp).toDate())
              : null;

          return Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
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
                          _buildDetailItem(tr('nama_pemilik'), namaPemilik),
                          const SizedBox(height: 12),
                          _buildDetailItem(
                            tr('jenis_kendaraan'),
                            jenisKendaraan,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailItem(
                            tr('status'),
                            tr(status.toLowerCase()),
                          ),
                          const SizedBox(height: 12),
                          if (vehicleData['kategori'] == 'Tamu') ...[
                            _buildDetailItem(tr('kategori'), tr('tamu')),
                            const SizedBox(height: 12),
                            if (kedatangan != null) ...[
                              _buildDetailItem(tr('kedatangan'), kedatangan),
                              const SizedBox(height: 12),
                            ],
                          ],
                          _buildDetailItem(tr('plat_kendaraan'), platKendaraan),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
                      Text(
                        tr('foto_kendaraan'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          fotoUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
