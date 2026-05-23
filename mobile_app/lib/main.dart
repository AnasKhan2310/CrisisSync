import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisisync/config/theme.dart';
import 'package:crisisync/services/crisis_provider.dart';
import 'package:crisisync/screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CrisisProvider()),
      ],
      child: const CrisisSyncApp(),
    ),
  );
}

class CrisisSyncApp extends StatelessWidget {
  const CrisisSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrisisSync',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
