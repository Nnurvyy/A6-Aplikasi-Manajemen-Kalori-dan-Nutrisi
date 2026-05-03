import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import './features/general/auth/models/user_model.dart';
import './features/general/food/models/food_model.dart';
import './features/general/food/models/log_model.dart';
import './features/general/food/models/watchlist_model.dart';
import './features/general/food/watchlist_controller.dart';
import './features/user/progress/models/weight_log_model.dart';
import './features/general/submission/submission_hive_model.dart';
import './features/general/submission/submission_controller.dart';
import './helpers/date_controller.dart';

import './services/hive_service.dart';
import './helpers/seed_helper.dart';

import './features/general/auth/auth_controller.dart';
import './features/general/food/food_controller.dart';
import './features/general/auth/splash_view.dart';

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

  // Register semua adapter
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(FoodModelAdapter());
  Hive.registerAdapter(LogModelAdapter());
  Hive.registerAdapter(WatchlistModelAdapter());
  Hive.registerAdapter(WeightLogModelAdapter());
  Hive.registerAdapter(SubmissionHiveModelAdapter()); // ← baru

  await HiveService.initBoxes();
  await SeedHelper.seedIfEmpty();

  // Inisialisasi SubmissionController sebelum runApp
  final submissionCtrl = SubmissionController();
  await submissionCtrl.init();

  runApp(NutriTrackApp(submissionCtrl: submissionCtrl));
}

class NutriTrackApp extends StatelessWidget {
  final SubmissionController submissionCtrl;
  const NutriTrackApp({super.key, required this.submissionCtrl});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => FoodController()),
        ChangeNotifierProvider(create: (_) => WatchlistController()),
        ChangeNotifierProvider(create: (_) => DateController()),
        // SubmissionController global — shared antara Admin & Nutritionist
        ChangeNotifierProvider.value(value: submissionCtrl),
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
