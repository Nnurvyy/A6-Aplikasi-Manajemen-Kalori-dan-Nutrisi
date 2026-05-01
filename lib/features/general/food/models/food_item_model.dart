// Model sederhana untuk transfer data dari PilihMakananManual
// ke FoodDatabaseScreen sebelum dikonversi ke FoodModel (Hive).
class FoodItem {
  final String name;
  final double servingSize;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodItem({
    required this.name,
    required this.servingSize,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
