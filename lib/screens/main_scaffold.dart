import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _tab = 0;

  static const _screens = [
    HomeScreen(),
    AnalyticsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<AppProvider>();
    final isAlert = prov.state == AppState.alerting;

    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: NavigationBar(
          selectedIndex:     _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorColor:  AppColors.cyan.withOpacity(0.12),
          height: 62,
          labelBehavior:   NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: _tab == 0
                      ? AppColors.cyan
                      : Colors.white.withOpacity(0.3)),
              selectedIcon: Stack(
                children: [
                  const Icon(Icons.home, color: AppColors.cyan),
                  if (isAlert)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined,
                  color: _tab == 1
                      ? AppColors.cyan
                      : Colors.white.withOpacity(0.3)),
              selectedIcon:
                  const Icon(Icons.bar_chart, color: AppColors.cyan),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined,
                  color: _tab == 2
                      ? AppColors.cyan
                      : Colors.white.withOpacity(0.3)),
              selectedIcon:
                  const Icon(Icons.list_alt, color: AppColors.cyan),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
