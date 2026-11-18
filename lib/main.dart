import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/splash_view.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:timezone/data/latest.dart' as tzdata;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.init(); // <- for preferences
  tzdata.initializeTimeZones(); // <- for timezone
  // Lock to landscape only (both directions)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sync Time',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      home: const SplashScreen(),
    );
  }
}
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Sync Time',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//         ),
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }