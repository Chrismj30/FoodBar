import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:read_the_label/utils/custom_colors.dart';

import 'my_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  if (kIsWeb) {
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=AIzaSyA91Qu8C8xDq_cpr0zYIhT00UMlUWXD0Lc');
  } else {
    await dotenv.load(fileName: ".env");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2DCCA7),
          brightness: Brightness.light,
          surface: const Color(0xFF121212),
          primary: const Color(0xFF2DCCA7),
          secondary: const Color(0xFFFF6B6B),
          tertiary: const Color(0xFFFFC857),
          error: const Color(0xFFFF5C5C),
          onSurface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.black),
          labelMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}
