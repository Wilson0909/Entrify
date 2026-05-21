import 'package:flutter/material.dart';
import 'package:expo/services/localization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_kendaraan.dart';
import 'package:get_storage/get_storage.dart';

class RiwayatKendaraanPage extends StatefulWidget {
  const RiwayatKendaraanPage({super.key});

  @override
  State<RiwayatKendaraanPage> createState() => _RiwayatKendaraanPageState();
}

class _RiwayatKendaraanPageState extends State<RiwayatKendaraanPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '';
  String _jenisFilter = '';
  DateTime? _selectedDate;

  List<Map<String, dynamic>> _historyData = [];
  List<String> userPlates = [];
  bool _isLoading = true;

  // Storage (boleh tetap final)
  final storage = GetStorage();

  // ⛔ Tidak boleh read dalam deklarasi
  // final String currentUserID = storage.read("userId"); // ERROR

  // ✅ Ganti dengan late (diisi pada initState)
  late String currentUserID;

  @override
  void initState() {
    super.initState();

    // 🔥 Sekarang aman: object State sudah siap
    currentUserID = storage.read("userId") ?? "";
    print("USER ID = $currentUserID"); // <── CEK INI

    _loadUserPlates();
  }

  Future<void> _loadUserPlates() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plat_terdaftar')
          .where('ownerId', isEqualTo: currentUserID)
          .get();

      userPlates = snapshot.docs.map((doc) => doc['plat'].toString()).toList();

      await _fetchLogs();
    } catch (e) {
      print("Error load plat: $e");
    }

    setState(() => _isLoading = false);
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime(2000); // fallback

    // Jika Timestamp Firestore → convert
    if (raw is Timestamp) return raw.toDate();

    // Jika String → coba parse
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (e) {
        print("Gagal parse String date: $raw");
        return DateTime(2000);
      }
    }

    print("Unknown date format: $raw");
    return DateTime(2000);
  }

  Future<void> _fetchLogs() async {
    final List<Map<String, dynamic>> temp = [];

    try {
      if (userPlates.isEmpty) return;

      // 🔥 FETCH VEHICLE TYPES (Plat -> Jenis)
      final typesSnapshot = await FirebaseFirestore.instance
          .collection('kendaraan_request')
          .where('plat', whereIn: userPlates)
          .get();

      final Map<String, String> vehicleTypes = {};
      for (var doc in typesSnapshot.docs) {
        final data = doc.data();
        if (data['plat'] != null && data['jenis'] != null) {
          vehicleTypes[data['plat']] = data['jenis'];
        }
      }

      // LOG MASUK
      final masukSnap = await FirebaseFirestore.instance
          .collection('logs_masuk')
          .where('plat', whereIn: userPlates)
          .get();

      print("LOG MASUK: ${masukSnap.docs.length}");

      for (var doc in masukSnap.docs) {
        final data = doc.data();
        final rawDate = data['waktu_masuk'];
        final plate = data['plat'] ?? '';

        temp.add({
          "plat": plate,
          "type": vehicleTypes[plate] ?? data['jenis'] ?? '-',
          "status": "Masuk",
          "date": _formatDate(rawDate),
          "date_raw": _parseDate(rawDate),
        });
      }

      // LOG KELUAR
      final keluarSnap = await FirebaseFirestore.instance
          .collection('logs_keluar')
          .where('plat', whereIn: userPlates)
          .get();

      print("LOG KELUAR: ${keluarSnap.docs.length}");

      for (var doc in keluarSnap.docs) {
        final data = doc.data();
        final rawDate = data['waktu_keluar'];
        final plate = data['plat'] ?? '';

        temp.add({
          "plat": plate,
          "type": vehicleTypes[plate] ?? data['jenis'] ?? '-',
          "status": "Keluar",
          "date": _formatDate(rawDate),
          "date_raw": _parseDate(rawDate),
        });
      }

      // SORT (aman untuk null, string, timestamp)
      temp.sort((a, b) {
        DateTime ad = a['date_raw'];
        DateTime bd = b['date_raw'];
        return bd.compareTo(ad); // newest first
      });
    } catch (e) {
      print("Error load logs: $e");
    }

    setState(() => _historyData = temp);
  }

  // ─────────────────────────────────────────────

  String _formatDate(dynamic raw) {
    DateTime dt = _parseDate(raw);

    return "${dt.day} ${_monthName(dt.month)} ${dt.year}, "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";
  }

  String _monthName(int m) {
    return tr('month_$m');
  }

  // ─────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredHistory {
    return _historyData.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item['plat'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['type'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _statusFilter.isEmpty || item['status'] == _statusFilter;

      final matchesJenis = _jenisFilter.isEmpty || item['type'] == _jenisFilter;

      bool matchesDate = true;
      if (_selectedDate != null) {
        final DateTime itemDate = item['date_raw'];
        matchesDate =
            itemDate.year == _selectedDate!.year &&
            itemDate.month == _selectedDate!.month &&
            itemDate.day == _selectedDate!.day;
      }

      return matchesSearch && matchesStatus && matchesJenis && matchesDate;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────

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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryItem(_filteredHistory[index]);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────── UI COMPONENTS ─────────────

  Widget _buildEmptyState() {
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
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                40,
              ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
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
                                    _searchController.clear();
                                    _searchQuery = '';
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
                      items: ['Masuk', 'Keluar'],
                      width: itemWidth,
                      onChanged: (value) {
                        setState(() => _statusFilter = value);
                      },
                    ),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: itemWidth,
                    child: _buildFilterChip(
                      label: tr('jenis'),
                      value: _jenisFilter,
                      items: ['Motor', 'Mobil'],
                      width: itemWidth,
                      onChanged: (value) {
                        setState(() => _jenisFilter = value);
                      },
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

  Widget _buildDateFilter() {
    String label = tr('tanggal');
    bool isSelected = _selectedDate != null;
    if (isSelected) {
      final date = _selectedDate!;
      label = "${date.day} ${_monthName(date.month)} ${date.year}";
    }

    return GestureDetector(
      onTap: () async {
        // Custom Dialog with CalendarDatePicker to support "Clear" button
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
                          Navigator.pop(
                            context,
                            DateTime(0),
                          ); // Sentinel for Clear
                        },
                        child: Text(
                          tr('hapus_filter'),
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Cancel (null)
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
            setState(() {
              _selectedDate = null;
            });
          } else {
            setState(() {
              _selectedDate = picked;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7A5AF8) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7A5AF8) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              )
            else
              const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required List<String> items,
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
              value.isEmpty ? label : tr(value.toLowerCase()),
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
        ...items.map(
          (item) => PopupMenuItem(
            value: item,
            child: Text(
              tr(item.toLowerCase()),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final bool isEntry = item['status'] == "Masuk";
    final Color statusColor = isEntry ? Colors.green : Colors.red;
    final String statusText = item['status'];

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
                    item['plat'],
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
                  Icon(Icons.check_circle, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText.toLowerCase() == 'keluar'
                        ? tr('keluar_status')
                        : tr(statusText.toLowerCase()),
                    style: TextStyle(
                      color: statusColor,
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
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailKendaraanPage(data: item),
                    ),
                  );
                },
                child: Text(
                  tr('lihat_detail'),
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
