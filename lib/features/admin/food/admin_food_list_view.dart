import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/food/food_controller.dart';
import '../../general/food/models/food_model.dart';
import '../../general/food/food_detail_view.dart';
import 'admin_food_form_view.dart';

class AdminFoodListView extends StatefulWidget {
  const AdminFoodListView({super.key});

  @override
  State<AdminFoodListView> createState() => _AdminFoodListViewState();
}

class _AdminFoodListViewState extends State<AdminFoodListView> {
  final TextEditingController _searchController = TextEditingController();
  
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodController>().loadAllFoods();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<FoodController>().search(_searchController.text);
  }

  void _navigateToDetail(FoodModel food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodDetailView(food: food)),
    );
  }

  void _navigateToAddEdit({FoodModel? food}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminFoodFormView(initialFood: food)),
    );
  }

  void _confirmDelete(FoodModel food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Makanan?'),
        content: Text('Anda yakin ingin menghapus "${food.name}" dari database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<FoodController>().deleteFood(food.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
    final foodCtrl = context.watch<FoodController>();
    final foods = foodCtrl.foods;

    // Grouping
    final groupedFoods = <String, List<FoodModel>>{};
    for (var food in foods) {
      final cat = food.category.isEmpty ? 'Lainnya' : food.category;
      if (!groupedFoods.containsKey(cat)) groupedFoods[cat] = [];
      groupedFoods[cat]!.add(food);
    }

    final sortedKeys = groupedFoods.keys.toList()..sort();

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
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: foods.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final category = sortedKeys[index];
                      final catFoods = groupedFoods[category]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryHeader(category),
                          ...catFoods.map((f) => _buildFoodCard(f)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Makanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      color: _surface,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
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

  Widget _buildCategoryHeader(String category) {
    return Padding(
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
          Expanded(child: Divider(color: _categoryColor(category).withValues(alpha: 0.2), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildFoodCard(FoodModel food) {
    final Color accentColor = _categoryColor(food.category);
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
              color: Colors.black.withValues(alpha: 0.03),
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
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  food.name.isNotEmpty ? food.name[0].toUpperCase() : '?',
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
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _navigateToAddEdit(food: food),
                      child: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _confirmDelete(food),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    ),
                  ],
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
      case 'lauk': return const Color(0xFF4CAF50);
      case 'makanan pokok': return const Color(0xFFF59E0B);
      case 'sayuran': return const Color(0xFF43A047);
      case 'buah': return const Color(0xFFE91E63);
      case 'minuman': return const Color(0xFF1E88E5);
      case 'snack': return const Color(0xFF9C27B0);
      default: return const Color(0xFF78909C);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Makanan tidak ditemukan',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
