import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/vintage_theme.dart';
import 'views/login_view.dart';

void main() {
  runApp(
    // ProviderScope is mandatory for all Riverpod state bindings
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ILKF - Slow messaging',
      debugShowCheckedModeBanner: false,
      theme: VintageTheme.getThemeData(),
      home: const LoginView(),
    );
  }
}
