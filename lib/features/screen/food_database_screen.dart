import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'food_item_model.dart';
import 'PilihMakananManual.dart';
import '../food/models/food_model.dart';
import '../../services/hive_service.dart';

// FoodItem lokal dihapus — sekarang pakai FoodModel (Hive) supaya persisten.

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Baca langsung dari Hive — hanya tampilkan food milik user (isApproved=false = custom)
  List<FoodModel> get _myIngredients =>
      HiveService.foods.values.where((f) => !f.isApproved).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  static const Color _primary = Color(0xFF2ECC71);
  static const Color _bg = Color(0xFFF4FAF6);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1A2E22);
  static const Color _textMuted = Color(0xFF7A9485);
  static const Color _calColor = Color(0xFFFF6B35);
  static const Color _proteinColor = Color(0xFF2ECC71);
  static const Color _carbsColor = Color(0xFFFFB800);
  static const Color _fatColor = Color(0xFF3498DB);

  @override
  void initState() {
    super.initState();
    _dbFoods = HiveService.foods.values.toList();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _dbFoods = HiveService.foods.values.toList();
      } else {
        _dbFoods = HiveService.foods.values
            .where((f) => f.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _navigateToDetail(FoodModel food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailView(food: food),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteIngredient(FoodModel item) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Hapus Bahan?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('Yakin ingin menghapus "${item.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: _textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  await HiveService.foods.delete(item.id);
                  if (mounted) {
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _openAddIngredient() async {
    final result = await Navigator.push<FoodItem>(
      context,
      MaterialPageRoute(builder: (_) => const PilihMakananManual()),
    );
    if (result != null && mounted) {
      // Konversi FoodItem (dari PilihMakananManual) → FoodModel lalu simpan ke Hive
      final food = FoodModel(
        id: const Uuid().v4(),
        name: result.name,
        category: 'Lainnya',
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        defaultServingSize: result.servingSize,
        isApproved:
            false, // false = bahan custom milik user (bukan dari database resmi)
        createdAt: DateTime.now(),
        description:
            result.unit, // simpan satuan (gram/butir/dll) di description
      );
      await HiveService.foods.put(food.id, food);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Text(
          'Database Makanan',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _dbFoods.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _dbFoods.length,
                    itemBuilder: (context, index) => _buildFoodCard(_dbFoods[index]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cari makanan di database',
                    style: TextStyle(color: _textMuted, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyIngredientsTab() {
    final items = _myIngredients;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildAddCustomButton(),
          const SizedBox(height: 16),
          Expanded(
            child:
                items.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildIngredientCard(items[i]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _surface,
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari makanan...',
            prefixIcon: Icon(Icons.search, color: _textMuted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientCard(FoodModel item) {
    // unit tersimpan di description saat save dari PilihMakananManual
    final unit =
        (item.description != null && item.description!.isNotEmpty)
            ? item.description!
            : 'gram';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(food),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.defaultServingSize.toStringAsFixed(0)} $unit',
                  style: TextStyle(color: _textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food.category,
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniNutriBadge('${food.calories.toStringAsFixed(0)} kkal', _calColor),
                        const SizedBox(width: 8),
                        _miniNutriBadge('${food.protein.toStringAsFixed(1)}g P', _proteinColor),
                        const SizedBox(width: 8),
                        _miniNutriBadge('${food.carbs.toStringAsFixed(1)}g K', _carbsColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: _primary,
                  size: 22,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} ditambahkan ke log!'),
                      backgroundColor: _primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                onPressed: () => _deleteIngredient(item),
              ),
              const Icon(Icons.chevron_right_rounded, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniNutriBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: _textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Makanan tidak ditemukan',
            style: TextStyle(color: _textMuted, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
