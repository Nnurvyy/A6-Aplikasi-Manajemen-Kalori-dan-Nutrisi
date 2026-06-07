class StringHelper {
  /// Capitalize each word in a string (Title Case)
  /// e.g. "makanan pokok" -> "Makanan Pokok"
  static String formatCategory(String? category) {
    if (category == null || category.trim().isEmpty) return '-';
    return category.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Get the unit for a given category: 'pcs' or 'porsi'
  static String getUnitForCategory(String? category) {
    if (category == null) return 'porsi';
    final cleanCategory = category.trim().toLowerCase();
    if (cleanCategory == 'snack' || cleanCategory == 'lauk' || cleanCategory == 'buah') {
      return 'pcs';
    }
    return 'porsi';
  }

  /// Format the food display name with its quantity and unit if quantity > 1
  /// e.g. quantity: 3, category: 'minuman', name: 'Air Putih' -> '3 porsi Air Putih'
  static String getFoodHistoryDisplayName(String foodName, int quantity, String? category) {
    if (quantity <= 1) return foodName;
    final unit = getUnitForCategory(category);
    return '$quantity $unit $foodName';
  }
}
