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
  static const Color _primary = Color(0xFF4CAF50);
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  static const int _itemsPerPage = 10;
  int _currentPage = 0;
  String _selectedCategory = 'Semua';

  static const List<String> _filterCategories = [
    'Semua', 'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodController>().loadAllFoods();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() => _currentPage = 0);
    context.read<FoodController>().search(_searchController.text);
  }

  void _navigateToDetail(FoodModel food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodDetailView(food: food)),
    );
  }

  void _navigateToAddEdit({FoodModel? food}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminFoodFormView(initialFood: food)),
    );
    if (result == true && mounted) {
      context.read<FoodController>().loadAllFoods();
    }
  }

  void _confirmDelete(FoodModel food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Makanan?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Anda yakin ingin menghapus "${food.name}" dari database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context.read<FoodController>().deleteFood(food.id);
              Navigator.pop(ctx);
              setState(() => _currentPage = 0);
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

  List<FoodModel> get _filteredFoods {
    final all = context.read<FoodController>().foods;
    if (_selectedCategory == 'Semua') return all;
    return all.where((f) => f.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final foodCtrl = context.watch<FoodController>();
    List<FoodModel> foods = foodCtrl.foods;
    if (_selectedCategory != 'Semua') {
      foods = foods.where((f) => f.category == _selectedCategory).toList();
    }

    final totalPages = (foods.length / _itemsPerPage).ceil();
    final safeCurrentPage = foods.isEmpty ? 0 : _currentPage.clamp(0, totalPages - 1);
    final startIndex = safeCurrentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, foods.length);
    final pageItems = foods.isEmpty ? <FoodModel>[] : foods.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Database Makanan',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          // Results info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Text(
                  '${foods.length} makanan',
                  style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600),
                ),
                if (foods.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'Hal. ${safeCurrentPage + 1}/${ totalPages < 1 ? 1 : totalPages}',
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
                ]
              ],
            ),
          ),
          Expanded(
            child: foods.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          itemCount: pageItems.length,
                          itemBuilder: (context, index) => _buildFoodCard(pageItems[index]),
                        ),
                      ),
                      if (totalPages > 1) _buildPagination(safeCurrentPage, totalPages),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Makanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: _surface,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: _textDark),
                decoration: InputDecoration(
                  hintText: 'Cari makanan...',
                  hintStyle: const TextStyle(color: Color(0xFF9EAD9E), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: _primary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: _textMuted),
                          onPressed: () {
                            _searchController.clear();
                            context.read<FoodController>().search('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // Category dropdown filter
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: _primary, size: 18),
                const SizedBox(width: 8),
                const Text('Kategori:', style: TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                        style: const TextStyle(fontSize: 13, color: _textDark, fontWeight: FontWeight.w600),
                        items: _filterCategories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              if (cat != 'Semua') ...[
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: _catColor(cat),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(cat),
                            ],
                          ),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() {
                            _selectedCategory = val;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int current, int total) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(Icons.first_page_rounded, current > 0, () => setState(() => _currentPage = 0)),
          const SizedBox(width: 4),
          _pageBtn(Icons.chevron_left_rounded, current > 0, () => setState(() => _currentPage--)),
          const SizedBox(width: 8),
          ...List.generate(total, (i) {
            final isActive = i == current;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isActive ? _primary : const Color(0xFFD0E8D0)),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : _textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).take(7).toList(), // show max 7 page buttons
          const SizedBox(width: 8),
          _pageBtn(Icons.chevron_right_rounded, current < total - 1, () => setState(() => _currentPage++)),
          const SizedBox(width: 4),
          _pageBtn(Icons.last_page_rounded, current < total - 1, () => setState(() => _currentPage = total - 1)),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: enabled ? _bg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? const Color(0xFFD0E8D0) : Colors.transparent),
        ),
        child: Icon(icon, size: 18, color: enabled ? _primary : _textMuted.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildFoodCard(FoodModel food) {
    final Color accentColor = _catColor(food.category);
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
            // Food image or avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: food.imageUrl != null
                  ? Image.network(
                      food.imageUrl!,
                      width: 50, height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatar(food.name, accentColor),
                    )
                  : _buildAvatar(food.name, accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${food.category} • ${food.defaultServingSize.toInt()}g',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _primary),
                ),
                const Text('kkal', style: TextStyle(fontSize: 10, color: _textMuted)),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _navigateToAddEdit(food: food),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.blue, size: 16),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _confirmDelete(food),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                      ),
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

  Widget _buildAvatar(String name, Color color) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }

  Widget _nutriChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Color _catColor(String category) {
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
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Makanan tidak ditemukan',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba kata kunci atau kategori lain',
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
