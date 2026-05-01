import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../helpers/app_colors.dart';
import './food_controller.dart';
import './models/food_model.dart';
import './food_detail_view.dart';

class FoodListView extends StatefulWidget {
  final String? initialSearch;

  const FoodListView({super.key, this.initialSearch});

  @override
  State<FoodListView> createState() => _FoodListViewState();
}

class _FoodListViewState extends State<FoodListView> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'Semua';
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  static const List<String> _filterCategories = [
    'Semua', 'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<FoodController>();
      ctrl.loadFoods();
      if (widget.initialSearch != null) {
        _searchCtrl.text = widget.initialSearch!;
        ctrl.search(widget.initialSearch!);
      }
    });
    _searchCtrl.addListener(() => setState(() => _currentPage = 0));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FoodController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Apply category filter client-side (on top of FoodController search)
    List<FoodModel> foods = ctrl.foods;
    if (_selectedCategory != 'Semua') {
      foods = foods.where((f) => f.category == _selectedCategory).toList();
    }

    final totalPages = foods.isEmpty ? 1 : (foods.length / _itemsPerPage).ceil();
    final safeCurrentPage = _currentPage.clamp(0, totalPages - 1);
    final startIndex = safeCurrentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, foods.length);
    final pageItems = foods.isEmpty ? <FoodModel>[] : foods.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Database Makanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ─── Search bar ───
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                ctrl.search(v);
                setState(() => _currentPage = 0);
              },
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari makanan...',
                hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          ctrl.search('');
                          setState(() => _currentPage = 0);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ─── Category dropdown ───
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Kategori:',
                  style: GoogleFonts.poppins(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : const Color(0xFFF4F6F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFC8E6C9),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
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
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Results count ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${foods.length} makanan ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                if (foods.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'Hal. ${safeCurrentPage + 1}/$totalPages',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── Food list ───
          Expanded(
            child: foods.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_food_rounded,
                            size: 56,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        const SizedBox(height: 12),
                        Text('Makanan tidak ditemukan',
                            style: GoogleFonts.poppins(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          itemCount: pageItems.length,
                          itemBuilder: (_, i) => _foodCard(context, pageItems[i], isDark),
                        ),
                      ),
                      if (totalPages > 1) _buildPagination(safeCurrentPage, totalPages, isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int current, int total, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(Icons.chevron_left_rounded, current > 0, () => setState(() => _currentPage--), isDark),
          const SizedBox(width: 8),
          ...List.generate(total, (i) {
            final isActive = i == current;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.primary : (isDark ? AppColors.darkBorder : const Color(0xFFD0E8D0)),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            );
          }).take(7).toList(),
          const SizedBox(width: 8),
          _pageBtn(Icons.chevron_right_rounded, current < total - 1, () => setState(() => _currentPage++), isDark),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: enabled ? (isDark ? AppColors.darkBackground : const Color(0xFFF4F6F0)) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? (isDark ? AppColors.darkBorder : const Color(0xFFD0E8D0)) : Colors.transparent,
          ),
        ),
        child: Icon(icon, size: 16, color: enabled ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
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

  Widget _foodCard(BuildContext context, FoodModel food, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FoodDetailView(food: food)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightDivider),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: food.imageUrl != null
                  ? Image.network(
                      food.imageUrl!,
                      width: 50, height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatar(food.name),
                    )
                  : _avatar(food.name),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      )),
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: _catColor(food.category), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(food.category,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _nutriBadge('P ${food.protein.toStringAsFixed(0)}g', AppColors.proteinColor, isDark),
                      const SizedBox(width: 4),
                      _nutriBadge('K ${food.carbs.toStringAsFixed(0)}g', AppColors.carbsColor, isDark),
                      const SizedBox(width: 4),
                      _nutriBadge('L ${food.fat.toStringAsFixed(0)}g', AppColors.fatColor, isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 24),
                Text(
                  food.calories.toStringAsFixed(0),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
                Text('kkal',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    )),
                const SizedBox(height: 4),
                Text('per 100g',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
        ),
      ),
    );
  }

  Widget _nutriBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
