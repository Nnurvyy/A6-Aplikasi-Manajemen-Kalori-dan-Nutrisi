import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './features/admin/UserManagement/admin_user_controller.dart';
import './features/general/auth/models/user_model.dart';
import './features/general/food/models/food_model.dart';
import './features/general/food/models/log_model.dart';
import './features/general/food/models/watchlist_model.dart';
import './features/general/food/watchlist_controller.dart';
import './features/user/progress/models/weight_log_model.dart';
import './features/general/submission/submission_controller.dart';
import './features/general/submission/model/pending_submission_model.dart';
import './features/user/notification/models/notification_setting_model.dart'; 
import './helpers/date_controller.dart';
import './services/hive_service.dart';
import './helpers/seed_helper.dart';
import './features/general/auth/auth_controller.dart';
import './features/general/food/food_controller.dart';
import './features/general/auth/splash_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import './services/notification_service.dart'; 

import 'services/food_log_sync_service.dart';   
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

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

  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(FoodModelAdapter());
  Hive.registerAdapter(LogModelAdapter());
  Hive.registerAdapter(WatchlistModelAdapter());
  Hive.registerAdapter(WeightLogModelAdapter());
  Hive.registerAdapter(PendingSubmissionModelAdapter()); 
  Hive.registerAdapter(NotificationSettingModelAdapter()); 

  await HiveService.initBoxes();
  await NotificationService.init();         
  await NotificationService.requestPermission();
  await SeedHelper.seedIfEmpty();
  
  // Initial sync
  FoodLogSyncService.syncPendingLogs();

  // Connectivity listener for auto-sync when back online
  Connectivity().onConnectivityChanged.listen((results) {
    if (results.any((r) => r != ConnectivityResult.none)) {
      debugPrint('[Main] Connection restored, triggering sync...');
      FoodLogSyncService.syncPendingLogs();
    }
  });

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
        ChangeNotifierProvider(create: (_) => WatchlistController()),
        ChangeNotifierProvider(create: (_) => DateController()),
        ChangeNotifierProvider(create: (_) => AdminUserController()),
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

final submissionCtrl = SubmissionController();
