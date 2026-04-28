import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _Tab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil', path: '/home'),
    _Tab(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Famille', path: '/family'),
    _Tab(icon: Icons.medication_outlined, activeIcon: Icons.medication, label: 'Traitements', path: '/treatments'),
    _Tab(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Historique', path: '/medical-history'),
    _Tab(icon: Icons.monitor_heart_outlined, activeIcon: Icons.monitor_heart, label: 'Constantes', path: '/vitals'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs
            .map((tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  activeIcon: Icon(tab.activeIcon),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _Tab({required this.icon, required this.activeIcon, required this.label, required this.path});
}
