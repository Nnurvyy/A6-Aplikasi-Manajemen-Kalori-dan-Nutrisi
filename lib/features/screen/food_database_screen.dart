import 'package:flutter/material.dart';
import 'PilihMakananManual.dart';
import '../../services/hive_service.dart';
import '../food/models/food_model.dart';

class FoodItem {
  final String name;
  final double servingSize;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    required this.name,
    required this.servingSize,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<FoodModel> _dbFoods = [];
  
  final List<FoodItem> _myIngredients = [
    FoodItem(
      name: 'Nasi Putih',
      servingSize: 100,
      unit: 'gram',
      calories: 130,
      protein: 2.7,
      carbs: 28.2,
      fat: 0.3,
    ),
    FoodItem(
      name: 'Telur Ayam',
      servingSize: 1,
      unit: 'butir',
      calories: 77,
      protein: 6.3,
      carbs: 0.6,
      fat: 5.3,
    ),
  ];

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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _deleteIngredient(int index) {
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
            content: Text(
              'Yakin ingin menghapus "${_myIngredients[index].name}"?',
            ),
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
                onPressed: () {
                  setState(() => _myIngredients.removeAt(index));
                  Navigator.pop(context);
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
    if (result != null) {
      setState(() => _myIngredients.add(result));
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
          const SizedBox(height: 16),
          Expanded(
            child: _dbFoods.isEmpty
                ? Center(
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
                          _searchController.text.isNotEmpty 
                            ? 'Makanan tidak ditemukan'
                            : 'Database kosong',
                          style: TextStyle(color: _textMuted, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _dbFoods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildDbFoodCard(_dbFoods[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyIngredientsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAddCustomButton(),
          const SizedBox(height: 16),
          Expanded(
            child:
                _myIngredients.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                      itemCount: _myIngredients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder:
                          (_, i) => _buildIngredientCard(_myIngredients[i], i),
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
          hintText: 'Cari makanan di database...',
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

  Widget _buildDbFoodCard(FoodModel item) {
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
              Icons.food_bank_outlined,
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
                  '${item.defaultServingSize.toStringAsFixed(0)} gram',
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
          IconButton(
            icon: const Icon(
              Icons.add_shopping_cart_rounded,
              color: _primary,
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} ditambahkan! (Demo)'),
                  backgroundColor: _primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(FoodItem item, int index) {
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
                  '${item.servingSize.toStringAsFixed(0)} ${item.unit}',
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
                      content: Text('${item.name} ditambahkan! (Demo)'),
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
                onPressed: () => _deleteIngredient(index),
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
