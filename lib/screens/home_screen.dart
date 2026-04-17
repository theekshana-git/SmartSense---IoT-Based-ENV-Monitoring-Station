// ============================================================
//  lib/screens/home_screen.dart
//  Bottom navigation shell. Uses IndexedStack so the
//  Monitor polling timer stays alive when switching tabs.
// ============================================================

import 'package:flutter/material.dart';
import 'monitor_screen.dart';
import 'forecast_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _screens = [
    MonitorScreen(),
    ForecastScreen(),
    AlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF185FA5)),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud_rounded, color: Color(0xFF185FA5)),
            label: 'Forecast',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded, color: Color(0xFF185FA5)),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
