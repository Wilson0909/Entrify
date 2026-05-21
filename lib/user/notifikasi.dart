import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:expo/services/localization_service.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final userId = storage.read("userId");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('Notification'),
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: userId == null
          ? Center(child: Text(tr('user_not_logged_in')))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      tr('no_notifications'),
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Convert and sort descending by createdAt (no index needed)
                List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

                docs.sort((a, b) {
                  Timestamp at = a['createdAt'];
                  Timestamp bt = b['createdAt'];
                  return bt.compareTo(at); // newest first
                });

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildNotificationItem(doc.id, data);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(String docId, Map<String, dynamic> data) {
    final String title = data['title'] ?? tr('no_title');
    final String description = data['message'] ?? '-';
    final bool isRead = data['isRead'] ?? false;
    final Timestamp? timestamp = data['createdAt'];
    final String time = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '-';

    // Determine icon and color based on title or type (simple logic for now)
    IconData icon = Icons.notifications;
    Color iconColor = const Color(0xFF7C68BE);
    Color iconBgColor = const Color(0xFFE8DEFC);

    if (isRead) {
      iconColor = Colors.grey;
      iconBgColor = Colors.grey.shade200;
    } else {
      if (title.toLowerCase().contains('disetujui')) {
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        iconBgColor = Colors.green.withOpacity(0.1);
      } else if (title.toLowerCase().contains('ditolak')) {
        icon = Icons.cancel_outlined;
        iconColor = Colors.red;
        iconBgColor = Colors.red.withOpacity(0.1);
      }
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(docId)
              .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isRead ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
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
