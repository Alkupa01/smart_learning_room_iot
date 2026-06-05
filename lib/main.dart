// lib/main.dart
// Entry point Smart Learning Room System
// Tim: Alkupa, Danniel, Nicholas — Universitas Ciputra Surabaya

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/dashboard_screen.dart';
import 'screens/control_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/profile_screen.dart';

// TODO: Uncomment saat Firebase sudah dikonfigurasi
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock ke portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // TODO: Init Firebase saat siap
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const ProviderScope(child: SmartLearningRoomApp()),
  );
}

class SmartLearningRoomApp extends StatelessWidget {
  const SmartLearningRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Learning Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1D9E75),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D9E75),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color.fromRGBO(29, 158, 117, 0.12),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      home: const _MainNavigation(),
    );
  }
}

// ── Navigasi Utama ────────────────────────────────────────────────────────────
class _MainNavigation extends StatefulWidget {
  const _MainNavigation();

  @override
  State<_MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<_MainNavigation> {
  int _idx = 0;

  final _screens = const [
  DashboardScreen(),
  ControlScreen(),           // ← ganti dari PlaceholderScreen
 AnalyticsScreen(),          // ← ganti dari PlaceholderScreen
  PomodoroScreen(), 
  ProfileScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_idx), child: _screens[_idx]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 16, offset: const Offset(0, -2))],
        ),
        child: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          elevation: 0,
          backgroundColor: Colors.white,
          destinations: const [
            NavigationDestination(
              icon:         Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label:        'Home',
            ),
            NavigationDestination(
              icon:         Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label:        'Kontrol',
            ),
            NavigationDestination(
              icon:         Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label:        'Analitik',
            ),
            NavigationDestination(
              icon:         Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label:        'Sesi',
            ),
            NavigationDestination(
              icon:         Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology),
              label:        'Profil AI',
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens removed — replaced by real screens in navigation.
