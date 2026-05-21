import 'package:expo/user/pengumuman.dart';
import 'package:flutter/material.dart';
import 'auth/signin_merged.dart';
import 'user/homepage.dart';
import 'user/riwayat_kendaraan.dart';
import 'user/profil.dart';
import 'user/daftar_kendaraan.dart';

// Admin imports
import 'admin/admin_homepage.dart';

import 'admin/tambah_pengumuman.dart';
import 'admin/daftar_pengumuman.dart';

import 'admin/riwayat_kendaraan_admin.dart';
import 'admin/daftar_kendaraan_admin.dart';
import 'admin/daftar_penghuni_admin.dart';
import 'admin/tambah_penghuni_admin.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:get_storage/get_storage.dart';

import 'package:expo/services/localization_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting();

  final localizationService = LocalizationService();
  localizationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService().localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: child!,
            );
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const SignInMergedPage(),
            //'/signin2': (context) => const SignIn2Page(),

            // User routes
            '/user/homepage': (context) => const HomePageUser(),
            '/user/pengumuman': (context) => const Pengumuman(),
            '/log': (context) => const RiwayatKendaraanPage(),
            '/profil': (context) => const ProfilPage(),
            '/daftar_kendaraan': (context) => const DaftarKendaraanPage(),

            // Admin routes
            '/admin/homepage': (context) => const AdminHomePage(),
            '/admin/pengumuman': (context) =>
                const AdminHomePage(initialIndex: 1),
            '/admin/tambah_pengumuman': (context) =>
                const TambahPengumumanPage(),
            '/admin/daftar_pengumuman': (context) =>
                const DaftarPengumumanPage(),

            '/admin/riwayat_kendaraan': (context) =>
                const RiwayatKendaraanAdminPage(),
            '/admin/daftar_kendaraan': (context) =>
                const DaftarKendaraanAdminPage(),
            '/admin/daftar_penghuni': (context) =>
                const DaftarPenghuniAdminPage(),
            '/admin/tambah_penghuni': (context) =>
                const TambahPenghuniAdminPage(),
          },
        );
      },
    );
  }
}
