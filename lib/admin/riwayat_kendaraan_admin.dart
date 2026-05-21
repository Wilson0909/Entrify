import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expo/admin/detail_kendaraan_admin.dart';
import 'package:rxdart/rxdart.dart';
import 'package:expo/services/localization_service.dart';

class RiwayatKendaraanAdminPage extends StatefulWidget {
  const RiwayatKendaraanAdminPage({super.key});

  @override
  State<RiwayatKendaraanAdminPage> createState() =>
      _RiwayatKendaraanAdminPageState();
}

class _RiwayatKendaraanAdminPageState extends State<RiwayatKendaraanAdminPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '';
  String _jenisFilter = '';
  DateTime? _selectedDate;

  String _monthName(int m) {
    return tr('month_$m');
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime(2000);
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return DateTime(2000);
  }

  String _formatDate(dynamic raw) {
    DateTime dt = _parseDate(raw);
    return "${dt.day} ${_monthName(dt.month)} ${dt.year}, "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // STREAM MASUK
  Stream<List<Map<String, dynamic>>> getRiwayatStream() {
    return FirebaseFirestore.instance
        .collection('logs_masuk')
        .orderBy('waktu_masuk', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final d = doc.data();
            return {
              "id": doc.id,
              "plate": d['plat'] ?? '',
              "type": d['jenis'] ?? '-',
              "status": d['status'] ?? '',
              "isEntry": true,
              "date": _formatDate(d['waktu_masuk']),
              "date_raw": _parseDate(d['waktu_masuk']),
            };
          }).toList();
        });
  }

  // STREAM KELUAR
  Stream<List<Map<String, dynamic>>> getRiwayatStreamKeluar() {
    return FirebaseFirestore.instance
        .collection('logs_keluar')
        .orderBy('waktu_keluar', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final d = doc.data();
            return {
              "id": doc.id,
              "plate": d['plat'] ?? '',
              "type": d['jenis'] ?? '-',
              "status": d['status'] ?? '',
              "isEntry": false,
              "date": _formatDate(d['waktu_keluar']),
              "date_raw": _parseDate(d['waktu_keluar']),
            };
          }).toList();
        });
  }

  // STREAM jenis kendaraan terbaru
  Stream<Map<String, String>> getVehicleTypesStream() {
    return FirebaseFirestore.instance
        .collection('kendaraan_request')
        .snapshots()
        .map((snapshot) {
          final Map<String, String> types = {};
          for (var doc in snapshot.docs) {
            final d = doc.data();
            if (d['plat'] != null && d['jenis'] != null) {
              types[d['plat']] = d['jenis'];
            }
          }
          return types;
        });
  }

  // GABUNG 3 STREAM
  Stream<List<Map<String, dynamic>>> getAllRiwayatStream() {
    return CombineLatestStream.combine3(
      getRiwayatStream(),
      getRiwayatStreamKeluar(),
      getVehicleTypesStream(),
      (masuk, keluar, types) {
        final all = [...masuk, ...keluar];

        for (var x in all) {
          if (types.containsKey(x['plate'])) {
            x['type'] = types[x['plate']];
          }
        }

        all.sort((a, b) => b["date_raw"].compareTo(a["date_raw"]));
        return all;
      },
    );
  }

  // FILTERING
  List<Map<String, dynamic>> filterData(List<Map<String, dynamic>> data) {
    return data.where((item) {
      final s = _searchQuery.toLowerCase();

      final matchesSearch =
          s.isEmpty ||
          item['plate'].toLowerCase().contains(s) ||
          item['type'].toLowerCase().contains(s);

      final matchesStatus =
          _statusFilter.isEmpty || item['status'] == _statusFilter;
      final matchesJenis = _jenisFilter.isEmpty || item['type'] == _jenisFilter;

      bool matchesDate = true;
      if (_selectedDate != null) {
        final d = item['date_raw'];
        matchesDate =
            d.year == _selectedDate!.year &&
            d.month == _selectedDate!.month &&
            d.day == _selectedDate!.day;
      }

      return matchesSearch && matchesStatus && matchesJenis && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildFilters(),

          const SizedBox(height: 10),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: getAllRiwayatStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filtered = filterData(snapshot.data!);

                    if (filtered.isEmpty) return _emptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (c, i) => _buildHistoryItem(filtered[i]),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EMPTY STATE
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            tr('tidak_ada_data'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double maxWidth = 600;
        double padding = (screenWidth - maxWidth) / 2;
        if (padding < 16) padding = 16;

        return Container(
          width: double.infinity,
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
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            tr('riwayat_kendaraan').replaceAll('\n', ' '),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('data_keluar_masuk'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/icon-clock.png',
                        width: 70,
                        height: 70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // SEARCH BAR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: tr('search_placeholder'),
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : const Icon(Icons.search, color: Colors.black54),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
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

  // ⭐ FILTERS – versi JUSTIFY 3 KOLOM
  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        if (width > 600) width = 600;

        double spacing = 8;
        // Subtract padding (16 * 2 = 32) and spacing (8 * 2 = 16)
        double itemWidth = (width - 32 - (spacing * 2)) / 3;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(width: itemWidth, child: _buildDateFilter()),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: itemWidth,
                    child: _buildFilterChip(
                      label: tr('status'),
                      value: _statusFilter,
                      items: {
                        'masuk': tr('masuk'),
                        'keluar': tr('keluar_status'),
                      },
                      width: itemWidth,
                      onChanged: (v) => setState(() => _statusFilter = v),
                    ),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: itemWidth,
                    child: _buildFilterChip(
                      label: tr('jenis'),
                      value: _jenisFilter,
                      items: {'Motor': tr('motor'), 'Mobil': tr('mobil')},
                      width: itemWidth,
                      onChanged: (v) => setState(() => _jenisFilter = v),
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

  // DATE FILTER (UI tidak diubah)
  Widget _buildDateFilter() {
    bool selected = _selectedDate != null;

    String label = tr('tanggal');
    if (selected) {
      final s = _selectedDate!;
      label = "${s.day} ${_monthName(s.month)} ${s.year}";
    }

    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDialog<DateTime>(
          context: context,
          builder: (context) {
            DateTime tempSelectedDate = _selectedDate ?? DateTime.now();
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF7A5AF8),
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7A5AF8),
                  ),
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    content: SizedBox(
                      width: 320,
                      height: 400,
                      child: CalendarDatePicker(
                        initialDate: tempSelectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        onDateChanged: (date) {
                          setStateDialog(() {
                            tempSelectedDate = date;
                          });
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, DateTime(0));
                        },
                        child: Text(
                          tr('hapus_filter'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(tr('batal')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, tempSelectedDate);
                        },
                        child: Text(tr('pilih')),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );

        if (picked != null) {
          if (picked.year == 0) {
            setState(() => _selectedDate = null);
          } else {
            setState(() => _selectedDate = picked);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7A5AF8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF7A5AF8) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!selected)
              const Icon(Icons.calendar_today, size: 14, color: Colors.black54)
            else
              GestureDetector(
                onTap: () => setState(() => _selectedDate = null),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FILTER CHIP (UI sama)
  Widget _buildFilterChip({
    required String label,
    required String value,
    required Map<String, String> items,
    required double width,
    required Function(String) onChanged,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      constraints: BoxConstraints.tightFor(width: width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value.isNotEmpty ? const Color(0xFF7A5AF8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value.isNotEmpty
                ? const Color(0xFF7A5AF8)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (value.isNotEmpty)
              const Icon(Icons.filter_alt, size: 14, color: Colors.white),
            if (value.isNotEmpty) const SizedBox(width: 4),
            Text(
              value.isEmpty ? label : (items[value] ?? value),
              style: TextStyle(
                fontSize: 12,
                color: value.isNotEmpty ? Colors.white : Colors.black87,
                fontWeight: value.isNotEmpty
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: value.isNotEmpty ? Colors.white : Colors.black54,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: '',
          child: Text(
            '${tr('semua')} $label',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        ...items.entries.map(
          (entry) => PopupMenuItem(
            value: entry.key,
            child: Text(
              entry.value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  // CARD ITEM
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final isEntry = item['isEntry'];
    final color = isEntry ? Colors.green : Colors.red;
    final statusText = isEntry ? tr('masuk') : tr('keluar_status');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KIRI: Jenis & Plat
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(item['type'].toString().toLowerCase()),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['plate'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              // KANAN: Badge Status (Icon + Text)
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12),
          const SizedBox(height: 8),

          // BAWAH: Tanggal & See Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['date'],
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailKendaraanAdminPage(vehicle: item),
                    ),
                  );
                },
                child: Text(
                  tr('lihat_detail'),
                  style: const TextStyle(
                    fontSize: 13,
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
