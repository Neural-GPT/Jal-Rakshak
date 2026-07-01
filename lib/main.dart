import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_scaffold.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child:  const JalRakshakApp(),
    ),
  );
}

class JalRakshakApp extends StatelessWidget {
  const JalRakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    return MaterialApp(
      title:        'Jal Rakshak',
      debugShowCheckedModeBanner: false,
      theme:        prov.settings.isDark ? AppTheme.dark() : AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/':         (_) => const MainScaffold(),
        '/settings': (_) => const SettingsScreen(),
        '/history':  (_) => HistoryScreen(),
      },
    );
  }
}