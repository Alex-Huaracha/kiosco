import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:hgtrack/core/core.dart';
import 'package:hgtrack/features/authentication/presentation/pages/empleados_list_page.dart';

Future<void> main() async {
  // Asegurar que Flutter esté inicializado antes de cargar configuración
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno desde archivo .env
  await dotenv.load(fileName: ".env");
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
     return ChangeNotifierProvider(
      create: (context) => MyAppState(),
       child: MaterialApp(
        title: 'HG Control Tiempo OT',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.cardBackground,
            error: AppColors.error,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.bannerBackground,
            foregroundColor: AppColors.primary,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: AppColors.cardBackground,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(
              color: AppColors.textPrimary,
            ),
            bodyMedium: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ),
       home: const EmpleadosListPage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
}
