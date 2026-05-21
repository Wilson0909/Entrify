import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expo/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detail_pengumuman.dart';
import 'daftar_pengumuman.dart';

class Pengumuman extends StatefulWidget {
  const Pengumuman({super.key});

  @override
  State<Pengumuman> createState() => _PengumumanState();
}

class _PengumumanState extends State<Pengumuman> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

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
        child: Stack(
          children: [
            // 1. Content Body (White/Grey part with top curves)
            Column(
              children: [
                const SizedBox(height: 140), // Space for header
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F3F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCalendarSection(),
                          const SizedBox(height: 20),
                          Expanded(child: _buildAnnouncementsSection()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Header Content (Text & Icon)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('daftar_pengumuman'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('informasi_terbaru'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Image.asset('assets/logo.png', width: 60, height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('kalender'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildCalendarHeader(),
              const SizedBox(height: 16),
              _buildCalendarGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat(
            'MMMM yyyy',
            LocalizationService().localeNotifier.value.languageCode,
          ).format(_focusedDay),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                  );
                  _selectedDay = _focusedDay;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                  );
                  _selectedDay = _focusedDay;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    const weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final days = _getDaysInMonth(_focusedDay);

    // Calculate start and end of the month for the query
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
      23,
      59,
      59,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map(
                (day) => SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      tr(day),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pengumuman')
              .where('tanggal_kegiatan', isGreaterThanOrEqualTo: startOfMonth)
              .where('tanggal_kegiatan', isLessThanOrEqualTo: endOfMonth)
              .snapshots(),
          builder: (context, snapshot) {
            Set<int> activityDays = {};
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                if (data['tanggal_kegiatan'] != null) {
                  Timestamp timestamp = data['tanggal_kegiatan'] as Timestamp;
                  activityDays.add(timestamp.toDate().day);
                }
              }
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return _buildDayCell(days[index], activityDays);
              },
            );
          },
        ),
      ],
    );
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    final days = <DateTime>[];

    int firstWeekday = firstDayOfMonth.weekday;
    int padding = firstWeekday == 7 ? 0 : firstWeekday;

    for (int i = 0; i < padding; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: padding - i)));
    }

    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(firstDayOfMonth.add(Duration(days: i)));
    }

    int remaining = 42 - days.length;
    if (remaining < 7) {
      int fill = 7 - (days.length % 7);
      if (fill < 7) {
        for (int i = 1; i <= fill; i++) {
          days.add(lastDayOfMonth.add(Duration(days: i)));
        }
      }
    }

    return days;
  }

  Widget _buildDayCell(DateTime day, Set<int> activityDays) {
    final bool isCurrentMonth = day.month == _focusedDay.month;
    final bool isSelected =
        day.year == _selectedDay.year &&
        day.month == _selectedDay.month &&
        day.day == _selectedDay.day;
    final bool isToday =
        day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;
    final bool hasActivity = isCurrentMonth && activityDays.contains(day.day);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C68BE)
              : isToday
              ? const Color(0xFF7C68BE).withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : !isCurrentMonth
                      ? Colors.grey.shade400
                      : Colors.black87,
                ),
              ),
            ),
            if (hasActivity)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    Query query = FirebaseFirestore.instance.collection('pengumuman');

    DateTime start = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    DateTime end = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      23,
      59,
      59,
    );
    query = query
        .where('tanggal_kegiatan', isGreaterThanOrEqualTo: start)
        .where('tanggal_kegiatan', isLessThanOrEqualTo: end)
        .orderBy('tanggal_kegiatan');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${tr('kegiatan_pada')} ${DateFormat('d MMM yyyy', LocalizationService().localeNotifier.value.languageCode).format(_selectedDay)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DaftarPengumumanPage(),
                  ),
                );
              },
              child: Text(
                tr('see_more'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF795FFC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "${tr('error_loading_announcements')}: ${snapshot.error}",
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(tr('tidak_ada_pengumuman')),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnnouncementCard(data),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> data) {
    String title = data['judul'] ?? tr('no_title');
    Timestamp? timestamp = data['tanggal_kegiatan'] as Timestamp?;
    String time = timestamp != null
        ? "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
        : "-";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailPengumuman(data: data)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                (data['gambar'] != null && data['gambar'].toString().isNotEmpty)
                    ? data['gambar']
                    : 'assets/gotongroyong.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/gotongroyong.png',
                    width: 50,
                    height: 50,
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
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
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
      ),
    );
  }
}
