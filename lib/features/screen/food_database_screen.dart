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

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Baca langsung dari Hive — hanya tampilkan food milik user (isApproved=false = custom)
  List<FoodModel> get _myIngredients =>
      HiveService.foods.values.where((f) => !f.isApproved).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  static const Color _primary = Color(0xFF2ECC71);
  static const Color _primaryDark = Color(0xFF27AE60);
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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Food Database',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primary,
          unselectedLabelColor: _textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          indicatorColor: _primary,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'Database'), Tab(text: 'My Ingredients')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDatabaseTab(), _buildMyIngredientsTab()],
      ),
    );
  }

  Widget _buildDatabaseTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: _textMuted.withOpacity(0.5),
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
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari makanan...',
          hintStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAddCustomButton() {
    return GestureDetector(
      onTap: _openAddIngredient,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Tambah Bahan Custom',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
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
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.defaultServingSize.toStringAsFixed(0)} $unit',
                  style: TextStyle(color: _textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _nutriBadge(
                      '${item.calories.toStringAsFixed(0)}',
                      'kal',
                      _calColor,
                    ),
                    const SizedBox(width: 8),
                    _nutriBadge(
                      '${item.protein.toStringAsFixed(1)}g',
                      'protein',
                      _proteinColor,
                    ),
                    const SizedBox(width: 8),
                    _nutriBadge(
                      '${item.carbs.toStringAsFixed(1)}g',
                      'karbo',
                      _carbsColor,
                    ),
                    const SizedBox(width: 8),
                    _nutriBadge(
                      '${item.fat.toStringAsFixed(1)}g',
                      'lemak',
                      _fatColor,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutriBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(label, style: TextStyle(color: _textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.no_food_rounded, size: 50, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada bahan custom',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan bahan makananmu sendiri\ndengan klik tombol di atas',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
