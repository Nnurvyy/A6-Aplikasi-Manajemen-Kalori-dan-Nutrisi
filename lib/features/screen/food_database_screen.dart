import 'package:flutter/material.dart';
import '../../services/hive_service.dart';
import '../food/models/food_model.dart';
import '../food/food_detail_view.dart';

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodModel> _dbFoods = [];
  Map<String, List<FoodModel>> _groupedFoods = {};
  
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  @override
  void initState() {
    super.initState();
    _loadAndFilter();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadAndFilter() {
    final query = _searchController.text.toLowerCase();
    List<FoodModel> allFoods = HiveService.foods.values.toList();
    
    if (query.isEmpty) {
      _dbFoods = allFoods;
    } else {
      _dbFoods = allFoods
          .where((f) => f.name.toLowerCase().contains(query))
          .toList();
    }
    
    // Grouping logic
    _groupedFoods = {};
    for (var food in _dbFoods) {
      final cat = food.category.isEmpty ? 'Lainnya' : food.category;
      if (!_groupedFoods.containsKey(cat)) {
        _groupedFoods[cat] = [];
      }
      _groupedFoods[cat]!.add(food);
    }
    
    // Sort categories (optional)
    final sortedKeys = _groupedFoods.keys.toList()..sort();
    final newGrouped = <String, List<FoodModel>>{};
    for (var key in sortedKeys) {
      newGrouped[key] = _groupedFoods[key]!..sort((a, b) => a.name.compareTo(b.name));
    }
    _groupedFoods = newGrouped;
  }

  void _onSearchChanged() {
    setState(() {
      _loadAndFilter();
    });
  }

  void _navigateToDetail(FoodModel food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodDetailView(food: food)),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Database Makanan',
          style: TextStyle(
            color: _textDark, 
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _dbFoods.isEmpty
                ? _buildEmptyState()
                : _buildCategorizedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      color: _surface,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: const InputDecoration(
            hintText: 'Cari makanan...',
            hintStyle: TextStyle(color: Color(0xFF9EAD9E), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4CAF50), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorizedList() {
    final categories = _groupedFoods.keys.toList();
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: categories.length,
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final foods = _groupedFoods[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _categoryColor(category),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _categoryColor(category),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: _categoryColor(category).withOpacity(0.2), thickness: 1)),
                ],
              ),
            ),
            ...foods.map((food) => _buildFoodCard(food)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFoodCard(FoodModel food) {
    final Color accentColor = _categoryColor(food.category);
    // Hitung berdasarkan default serving size
    final nutrients = food.nutritionForAmount(food.defaultServingSize);
    final calories = nutrients['calories'] ?? 0;
    final protein = nutrients['protein'] ?? 0;
    final carbs = nutrients['carbs'] ?? 0;
    final fat = nutrients['fat'] ?? 0;

    return GestureDetector(
      onTap: () => _navigateToDetail(food),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  food.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.category} • ${food.defaultServingSize.toInt()}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _nutriChip('P ${protein.toStringAsFixed(1)}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                      const SizedBox(width: 4),
                      _nutriChip('K ${carbs.toStringAsFixed(1)}g', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      _nutriChip('L ${fat.toStringAsFixed(1)}g', const Color(0xFFFFF3E0), const Color(0xFFFF8C00)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${calories.toInt()}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const Text(
                  'kkal',
                  style: TextStyle(fontSize: 10, color: _textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutriChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'lauk':
        return const Color(0xFF4CAF50);
      case 'makanan pokok':
        return const Color(0xFFF59E0B);
      case 'sayuran':
        return const Color(0xFF43A047);
      case 'buah':
        return const Color(0xFFE91E63);
      case 'minuman':
        return const Color(0xFF1E88E5);
      case 'snack':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF78909C);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Makanan tidak ditemukan',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba cari dengan kata kunci lain',
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

