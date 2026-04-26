import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/auth/models/user_model.dart';
import 'features/food/models/food_model.dart';
import 'features/food/models/log_model.dart';

import 'services/hive_service.dart';
import 'helpers/seed_helper.dart';

import 'features/auth/auth_controller.dart';
import 'features/food/food_controller.dart';
import 'features/auth/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('id', null);

  await Hive.initFlutter();

  // Register semua adapter di sini (HiveService TIDAK register lagi)
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(FoodModelAdapter());
  Hive.registerAdapter(LogModelAdapter());

  await HiveService.initBoxes();
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          useMaterial3: true,
        ),
        home: const SplashView(),
      ),
    );
  }
}
