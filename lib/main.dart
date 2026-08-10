import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blogorum/providers/auth.dart';
import 'package:blogorum/providers/profiles.dart';
import 'router.dart';
import 'theme/app_text_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qoczguvmnchlpevoxqon.supabase.co',
    publishableKey: 'sb_publishable_I5X8m8BbXfVP0Bz2yHb_LA_vQZ7KGpf',
  );
  final auth = AuthService();
  if (auth.isLoggedIn) {
    await ProfileService.instance.loadCurrentProfile();
  }
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme =
        ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 61, 184, 255),
            brightness: Brightness.light,
          ),
          textTheme: AppTextTheme.lightTextTheme,
          scaffoldBackgroundColor: const Color(0xFFF4F0E7),
        ).copyWith(
          extensions: <ThemeExtension<dynamic>>[
            const AppThemeExtension(boxShadows: AppTextTheme.lightBoxShadows),
          ],
        );
    final darkTheme =
        ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 61, 184, 255),
            brightness: Brightness.dark,
          ),
          textTheme: AppTextTheme.darkTextTheme,
          scaffoldBackgroundColor: const Color(0xFF121212),
        ).copyWith(
          extensions: <ThemeExtension<dynamic>>[
            const AppThemeExtension(boxShadows: AppTextTheme.darkBoxShadows),
          ],
        );
    return ThemeController(
      themeMode: _themeMode,
      toggleTheme: toggleTheme,
      child: MaterialApp.router(
        title: 'Blogorum',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: _themeMode,
        routerConfig: router,
      ),
    );
  }
}

class ThemeController extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;
  const ThemeController({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
    required super.child,
  });
  static ThemeController of(BuildContext context) {
    final controller = context
        .dependOnInheritedWidgetOfExactType<ThemeController>();
    assert(
      controller != null,
      'ThemeController could not be found in the widget tree.',
    );
    return controller!;
  }

  @override
  bool updateShouldNotify(ThemeController oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}
