import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/food/food_controller.dart';

import '../../general/food/models/food_model.dart';
import '../../general/food/food_detail_view.dart';
import '../../general/auth/auth_controller.dart';
import './manual_food_form_view.dart';
import './manual_ingredient_input_page.dart';
import 'dart:io';
import 'dart:convert';

class PilihMakananManual extends StatefulWidget {
  const PilihMakananManual({super.key});

  @override
  State<PilihMakananManual> createState() => _PilihMakananManualState();
}

class _PilihMakananManualState extends State<PilihMakananManual> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF2E7D32);
  static const Color _textMuted = Color(0xFF5A7A5A);

  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Load foods immediately if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().currentUser?.id;
      context.read<FoodController>().loadFoods(userId: userId);
    });
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentPage = 0);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodCtrl = context.watch<FoodController>();
    final authCtrl = context.watch<AuthController>();
    final userId = authCtrl.currentUser?.id ?? '';
    
    final manualItems = foodCtrl.manualFoods
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Split items by type: Makanan (Meal) vs Komposisi (Individual Ingredient)
    final meals = manualItems.where((f) => !f.isManualIngredient).toList();
    final ingredients = manualItems.where((f) => f.isManualIngredient).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Log Manual',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _textDark,
          unselectedLabelColor: _textMuted,
          indicatorColor: _textDark,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Makanan'),
            Tab(text: 'Komposisi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(meals),
          _buildTabContent(ingredients),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_tabController.index == 0) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormTambahMakananManual()),
            );
            if (result == true) {
              // Refresh handled by Provider
            }
          } else {
            // New ingredient input from "Komposisi" tab
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManualIngredientInputPage()),
            );
            if (result != null && result is Map) {
              // Save as manual ingredient
              final foodCtrl = context.read<FoodController>();
              final foodId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
              final newIngredient = FoodModel(
                id: foodId,
                name: result['name'],
                category: 'Lainnya',
                calories: (result['calories'] / result['grams']) * 100,
                protein: (result['protein'] / result['grams']) * 100,
                carbs: (result['carbs'] / result['grams']) * 100,
                fat: (result['fat'] / result['grams']) * 100,
                defaultServingSize: result['grams'],
                isApproved: true,
                createdAt: DateTime.now(),
                isManualIngredient: true,
                userId: context.read<AuthController>().currentUser?.id, // ← TAMBAHKAN INI
              );
              await foodCtrl.addFood(newIngredient);
            }
          }
        },
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(_tabController.index == 0 ? 'Tambah Baru' : 'Tambah Bahan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTabContent(List<FoodModel> items) {
    if (items.isEmpty) return _buildEmptyState();

    final totalPages = (items.length / _itemsPerPage).ceil();
    final safeCurrentPage = _currentPage.clamp(0, totalPages - 1);
    final startIndex = safeCurrentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, items.length);
    final pageItems = items.sublist(startIndex, endIndex);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text('${items.length} item tersimpan', style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (totalPages > 1)
                Text('Hal. ${safeCurrentPage + 1}/$totalPages', style: const TextStyle(fontSize: 12, color: _textMuted)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            itemCount: pageItems.length,
            itemBuilder: (context, index) => _buildManualFoodCard(pageItems[index]),
          ),
        ),
        if (totalPages > 1) _buildPagination(safeCurrentPage, totalPages),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPagination(int current, int total) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(Icons.chevron_left_rounded, current > 0, () => setState(() => _currentPage--)),
          const SizedBox(width: 8),
          ...List.generate(total, (i) {
            final isActive = i == current;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFD0E8D0)),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : _textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).take(7).toList(),
          const SizedBox(width: 8),
          _pageBtn(Icons.chevron_right_rounded, current < total - 1, () => setState(() => _currentPage++)),
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
          color: enabled ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? const Color(0xFFD0E8D0) : Colors.transparent),
        ),
        child: Icon(icon, size: 18, color: enabled ? const Color(0xFF2E7D32) : _textMuted.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildManualFoodCard(FoodModel food) {
    final Color accentColor = _getCategoryColor(food.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showFoodDetail(food),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: food.imageUrl != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: food.imageUrl!.startsWith('http')
                                    ? Image.network(food.imageUrl!, fit: BoxFit.cover)
                                    : Image.file(
                                        File(food.imageUrl!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            food.name.isNotEmpty ? food.name[0].toUpperCase() : '?',
                                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accentColor),
                                          ),
                                        ),
                                      ),
                              )
                            : Center(
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
                            Builder(builder: (context) {
                              double displayGrams = food.defaultServingSize;
                              if (food.ingredientsJson != null) {
                                try {
                                  final List decoded = jsonDecode(food.ingredientsJson!);
                                  displayGrams = decoded.fold<double>(0, (sum, item) => sum + (item['grams'] ?? 0));
                                } catch (_) {}
                              }
                              return Text(
                                '${displayGrams.round()}g',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textMuted,
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _nutriChip('P ${food.nutritionForAmount(food.defaultServingSize)['protein']?.round()}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                                const SizedBox(width: 4),
                                _nutriChip('K ${food.nutritionForAmount(food.defaultServingSize)['carbs']?.round()}g', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                _nutriChip('L ${food.nutritionForAmount(food.defaultServingSize)['fat']?.round()}g', const Color(0xFFFFF3E0), const Color(0xFFFF8C00)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${food.nutritionForAmount(food.defaultServingSize)['calories']?.toInt()}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E7D32),
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
                              _actionButton(
                                icon: Icons.edit_rounded,
                                color: Colors.blue,
                                onTap: () => _editManualFood(context, food),
                              ),
                              const SizedBox(width: 8),
                              _actionButton(
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red,
                                onTap: () => _confirmDeleteManualFood(context, food),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _editManualFood(BuildContext context, FoodModel food) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => food.isManualIngredient
            ? ManualIngredientInputPage(initialFood: food)
            : FormTambahMakananManual(initialFood: food),
      ),
    );
    if (result == true || (result != null && result is Map)) {
      if (result is Map && food.isManualIngredient) {
        final foodCtrl = context.read<FoodController>();
        await foodCtrl.updateFood(food.copyWith(
          name: result['name'],
          calories: (result['calories'] / result['grams']) * 100,
          protein: (result['protein'] / result['grams']) * 100,
          carbs: (result['carbs'] / result['grams']) * 100,
          fat: (result['fat'] / result['grams']) * 100,
          defaultServingSize: result['grams'].toDouble(),
        ));
      }
      // Refresh handled by Provider or by calling updateFood
    }
  }

  void _confirmDeleteManualFood(BuildContext context, FoodModel food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Makanan?'),
        content: Text('Hapus "${food.name}" dari database manual Anda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final foodCtrl = context.read<FoodController>();
              await foodCtrl.deleteFood(food.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFoodDetail(FoodModel food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodDetailView(food: food, isManual: true)),
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
            child: const Icon(Icons.note_add_rounded, size: 40, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada log manual',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Klik + untuk membuat catatan baru',
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// Global Helper
Color _getCategoryColor(String category) {
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
