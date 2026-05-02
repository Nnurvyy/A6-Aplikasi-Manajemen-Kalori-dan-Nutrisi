import '../features/general/auth/models/user_model.dart';
import '../features/general/food/models/food_model.dart';
import '../services/hive_service.dart';

class SeedHelper {
  /// Populate initial data jika box kosong
  static Future<void> seedIfEmpty() async {
    await _seedUsers();
    await _seedFoods();

    // Debug Print: Pastikan isi database tampil di terminal
    print('--- DEBUG: ISI DATABASE MAKANAN ---');
    print('Total Makanan: ${HiveService.foods.length}');
    for (var f in HiveService.foods.values) {
      print('- ${f.name} (${f.defaultServingSize}g)');
    }
    print('----------------------------------');
  }

  static Future<void> _seedUsers() async {
    if (HiveService.users.isNotEmpty) return;

    final users = [
      UserModel(
        id: 'admin_001',
        name: 'Admin NutriTrack',
        email: 'admin@nutritrack.com',
        password: 'admin123',
        role: 'admin',
      ),
      UserModel(
        id: 'nutri_001',
        name: 'Dr. Hilmi Mahdani',
        email: 'nutri@nutritrack.com',
        password: 'nutri123',
        role: 'nutritionist',
      ),
      UserModel(
        id: 'user_001',
        name: 'Budi Santoso',
        email: 'budi@email.com',
        password: 'budi123',
        role: 'user',
        weight: 70,
        height: 170,
        age: 25,
        gender: 'Laki-laki',
        activityLevel: 'Jarang olahraga',
        dailyCalorieNeed: 2400,
      ),
    ];

    for (final u in users) {
      await HiveService.users.put(u.id, u);
    }
  }

  static Future<void> _seedFoods() async {
    // Paksa reset seed jika terdeteksi data lama atau ingin reset database
    final bool forceReset = HiveService.settings.get('seed_v2_done') != true;

    if (HiveService.foods.length >= 30 && !forceReset) {
      return;
    }

    if (forceReset) {
      await HiveService.foods.clear();
      await HiveService.settings.put('seed_v2_done', true);
    }

    final now = DateTime.now();
    final List<FoodModel> labelsData = [
      FoodModel(
        id: 'f1',
        name: 'Apel',
        category: 'Buah',
        calories: 52,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        defaultServingSize: 150,
        createdAt: now,
      ),
      FoodModel(
        id: 'f2',
        name: 'Ayam Krispi',
        category: 'Lauk',
        calories: 260,
        protein: 25,
        carbs: 10,
        fat: 15,
        defaultServingSize: 120,
        createdAt: now,
      ),
      FoodModel(
        id: 'f3',
        name: 'Bakwan Jagung',
        category: 'Lauk',
        calories: 150,
        protein: 3,
        carbs: 20,
        fat: 7,
        defaultServingSize: 50,
        createdAt: now,
      ),
      FoodModel(
        id: 'f4',
        name: 'Bihun goreng',
        category: 'Makanan Pokok',
        calories: 180,
        protein: 4,
        carbs: 30,
        fat: 5,
        defaultServingSize: 200,
        createdAt: now,
      ),
      FoodModel(
        id: 'f5',
        name: 'Bubur',
        category: 'Makanan Pokok',
        calories: 50,
        protein: 1,
        carbs: 10,
        fat: 0.5,
        defaultServingSize: 250,
        createdAt: now,
      ),
      FoodModel(
        id: 'f6',
        name: 'Cah Kangkung',
        category: 'Sayuran',
        calories: 40,
        protein: 2,
        carbs: 3,
        fat: 3,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f7',
        name: 'Durian',
        category: 'Buah',
        calories: 147,
        protein: 1.5,
        carbs: 27,
        fat: 5,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f8',
        name: 'Gado-gado',
        category: 'Sayuran',
        calories: 130,
        protein: 5,
        carbs: 15,
        fat: 6,
        defaultServingSize: 250,
        createdAt: now,
      ),
      FoodModel(
        id: 'f9',
        name: 'Jeruk',
        category: 'Buah',
        calories: 47,
        protein: 0.9,
        carbs: 12,
        fat: 0.1,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f10',
        name: 'Kentang Goreng',
        category: 'Snack',
        calories: 312,
        protein: 3,
        carbs: 41,
        fat: 15,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f11',
        name: 'Kue Brownies',
        category: 'Snack',
        calories: 460,
        protein: 5,
        carbs: 50,
        fat: 25,
        defaultServingSize: 60,
        createdAt: now,
      ),
      FoodModel(
        id: 'f12',
        name: 'Mie Ayam',
        category: 'Makanan Pokok',
        calories: 220,
        protein: 7,
        carbs: 35,
        fat: 4,
        defaultServingSize: 300,
        createdAt: now,
      ),
      FoodModel(
        id: 'f13',
        name: 'Mie Bakso',
        category: 'Makanan Pokok',
        calories: 250,
        protein: 8,
        carbs: 40,
        fat: 5,
        defaultServingSize: 300,
        createdAt: now,
      ),
      FoodModel(
        id: 'f14',
        name: 'Nasi Goreng',
        category: 'Makanan Pokok',
        calories: 170,
        protein: 4,
        carbs: 25,
        fat: 6,
        defaultServingSize: 250,
        createdAt: now,
      ),
      FoodModel(
        id: 'f15',
        name: 'Nasi Putih',
        category: 'Makanan Pokok',
        calories: 130,
        protein: 2.7,
        carbs: 28,
        fat: 0.3,
        defaultServingSize: 150,
        createdAt: now,
      ),
      FoodModel(
        id: 'f16',
        name: 'Nugget Ayam',
        category: 'Lauk',
        calories: 250,
        protein: 15,
        carbs: 15,
        fat: 15,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f17',
        name: 'Pepes Ikan',
        category: 'Lauk',
        calories: 120,
        protein: 18,
        carbs: 2,
        fat: 5,
        defaultServingSize: 120,
        createdAt: now,
      ),
      FoodModel(
        id: 'f18',
        name: 'Pisang',
        category: 'Buah',
        calories: 89,
        protein: 1.1,
        carbs: 23,
        fat: 0.3,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f19',
        name: 'Pisang Pasir',
        category: 'Snack',
        calories: 200,
        protein: 2,
        carbs: 35,
        fat: 7,
        defaultServingSize: 80,
        createdAt: now,
      ),
      FoodModel(
        id: 'f20',
        name: 'Rendang',
        category: 'Lauk',
        calories: 193,
        protein: 17,
        carbs: 4,
        fat: 12,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f21',
        name: 'Roti Putih',
        category: 'Makanan Pokok',
        calories: 265,
        protein: 9,
        carbs: 49,
        fat: 3.2,
        defaultServingSize: 50,
        createdAt: now,
      ),
      FoodModel(
        id: 'f22',
        name: 'Sate ayam',
        category: 'Lauk',
        calories: 180,
        protein: 25,
        carbs: 2,
        fat: 8,
        defaultServingSize: 100,
        createdAt: now,
      ),
      FoodModel(
        id: 'f23',
        name: 'Semangka',
        category: 'Buah',
        calories: 30,
        protein: 0.6,
        carbs: 8,
        fat: 0.2,
        defaultServingSize: 200,
        createdAt: now,
      ),
      FoodModel(
        id: 'f24',
        name: 'Soto Ayam',
        category: 'Lauk',
        calories: 90,
        protein: 8,
        carbs: 5,
        fat: 4,
        defaultServingSize: 300,
        createdAt: now,
      ),
      FoodModel(
        id: 'f25',
        name: 'Tahu Goreng',
        category: 'Lauk',
        calories: 175,
        protein: 11,
        carbs: 3,
        fat: 13,
        defaultServingSize: 50,
        createdAt: now,
      ),
      FoodModel(
        id: 'f26',
        name: 'Telur Balado',
        category: 'Lauk',
        calories: 150,
        protein: 10,
        carbs: 2,
        fat: 11,
        defaultServingSize: 60,
        createdAt: now,
      ),
      FoodModel(
        id: 'f27',
        name: 'Telur Ceplok',
        category: 'Lauk',
        calories: 190,
        protein: 13,
        carbs: 1,
        fat: 15,
        defaultServingSize: 60,
        createdAt: now,
      ),
      FoodModel(
        id: 'f28',
        name: 'Telur Dadar',
        category: 'Lauk',
        calories: 150,
        protein: 10,
        carbs: 1,
        fat: 12,
        defaultServingSize: 60,
        createdAt: now,
      ),
      FoodModel(
        id: 'f29',
        name: 'Telur Rebus',
        category: 'Lauk',
        calories: 155,
        protein: 13,
        carbs: 1,
        fat: 11,
        defaultServingSize: 50,
        createdAt: now,
      ),
      FoodModel(
        id: 'f30',
        name: 'Tempe Goreng',
        category: 'Lauk',
        calories: 220,
        protein: 14,
        carbs: 9,
        fat: 14,
        defaultServingSize: 50,
        createdAt: now,
      ),
    ];

    for (final f in labelsData) {
      await HiveService.foods.put(f.id, f);
    }
  }
}
