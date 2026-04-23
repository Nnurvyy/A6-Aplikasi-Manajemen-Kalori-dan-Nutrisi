import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/auth/models/user_model.dart';
import 'features/food/models/food_model.dart';

import 'services/hive_service.dart';
import 'helpers/seed_helper.dart';

import 'features/auth/auth_controller.dart';
import 'features/food/food_controller.dart';
import 'features/auth/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Locale for intl (Bahasa Indonesia)
  await initializeDateFormatting('id', null);

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(FoodModelAdapter());

  // Open configured boxes
  await HiveService.initBoxes();

  // Seed default data if empty
  await SeedHelper.seedIfEmpty();

  runApp(const NutriTrackApp());
}

class NutriTrackApp extends StatelessWidget {
  const NutriTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => FoodController()),
      ],
      child: MaterialApp(
        title: 'NutriTrack',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system, // simplified
        home: const SplashView(),
      ),
    );
  }
}
