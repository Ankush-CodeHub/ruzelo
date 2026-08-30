import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/shaders/shader_program_loader.dart';
import 'core/theme/app_colors.dart';
import 'features/shell/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Asynchronously initialize GLSL fragment shaders with automatic fallback
  await ShaderProgramLoader.initializeShaders();

  runApp(
    const ProviderScope(
      child: RuzeloApp(),
    ),
  );
}

class RuzeloApp extends StatelessWidget {
  const RuzeloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruzelo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryNeon,
          secondary: AppColors.secondaryNeon,
          surface: AppColors.surfaceDark,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}
