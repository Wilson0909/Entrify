import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:expo/widgets/button.dart';
import 'package:expo/services/localization_service.dart';

class TambahPengumumanPage extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String? docId;

  const TambahPengumumanPage({super.key, this.data, this.docId});

  @override
  State<TambahPengumumanPage> createState() => _TambahPengumumanPageState();
}

class _TambahPengumumanPageState extends State<TambahPengumumanPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  List<String> _assetImages = [];
  String? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadAssetImages();

    if (widget.data != null) {
      _titleController.text = widget.data!['judul'] ?? '';
      _descriptionController.text = widget.data!['deskripsi'] ?? '';
      _selectedImage = widget.data!['gambar'];

      if (widget.data!['tanggal_kegiatan'] != null) {
        Timestamp timestamp = widget.data!['tanggal_kegiatan'];
        _selectedDate = timestamp.toDate();
      }

      if (widget.data!['jam_kegiatan'] != null) {
        String timeStr = widget.data!['jam_kegiatan'];
        List<String> parts = timeStr.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    }
  }

  Future<void> _loadAssetImages() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final imagePaths = manifestMap.keys
          .where((String key) => key.contains('assets/img/pengumuman/'))
          .toList();

      setState(() {
        _assetImages = imagePaths;
      });
    } catch (e) {
      print("Error loading assets: $e");
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    // Allow only H+1 (tomorrow) onwards
    final tomorrow = now.add(const Duration(days: 1));
    final firstDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    // Ensure initialDate is valid (must be >= firstDate)
    DateTime initialDate = _selectedDate ?? firstDate;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                        Text(
                          widget.data != null
                              ? tr('edit_pengumuman')
                              : tr('pengumuman'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Container(
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              tr('judul_kegiatan'),
                              tr('hint_judul'),
                              _titleController,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              tr('deskripsi'),
                              tr('hint_deskripsi'),
                              _descriptionController,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildDateField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTimeField()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildImageSelector(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: CustomButton(
          text: _isLoading
              ? tr('memuat')
              : (widget.data != null ? tr('simpan') : tr('submit')),
          onPressed: _isLoading
              ? () {}
              : () async {
                  if (_formKey.currentState!.validate()) {
                    if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('pilih_tanggal_valid')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (_selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('pilih_jam_valid')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final DateTime dateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );

                    if (dateTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('waktu_kegiatan_berlalu')),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final Map<String, dynamic> announcementData = {
                        'judul': _titleController.text,
                        'deskripsi': _descriptionController.text,
                        'tanggal_kegiatan': Timestamp.fromDate(dateTime),
                        'jam_kegiatan':
                            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                        'gambar': _selectedImage ?? '',
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (widget.docId != null) {
                        // Update existing document
                        await FirebaseFirestore.instance
                            .collection('pengumuman')
                            .doc(widget.docId)
                            .update(announcementData);
                      } else {
                        // Add new document
                        announcementData['createdAt'] =
                            FieldValue.serverTimestamp();
                        await FirebaseFirestore.instance
                            .collection('pengumuman')
                            .add(announcementData);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.docId != null
                                  ? tr('pengumuman_diperbarui')
                                  : tr('pengumuman_ditambahkan'),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${tr('terjadi_kesalahan')}: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  }
                },
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: const Color.fromARGB(255, 240, 240, 240),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C68BE), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('tanggal_kegiatan'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 240, 240, 240),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : tr('pilih_tanggal'),
                  style: TextStyle(
                    color: _selectedDate != null
                        ? Colors.black87
                        : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('jam_kegiatan'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 240, 240, 240),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime != null
                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : tr('pilih_jam'),
                  style: TextStyle(
                    color: _selectedTime != null
                        ? Colors.black87
                        : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('pilih_gambar'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (_assetImages.isEmpty)
          Text(
            tr('no_images_found'),
            style: TextStyle(color: Colors.grey.shade500),
          )
        else
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                children: _assetImages.map((imagePath) {
                  final isSelected = _selectedImage == imagePath;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = isSelected ? null : imagePath;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF7A5AF8)
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          image: DecorationImage(
                            image: AssetImage(imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: isSelected
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7A5AF8,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
