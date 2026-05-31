import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../helpers/app_colors.dart';
import './food_controller.dart';
import './models/food_model.dart';
import './food_detail_view.dart';
import '../auth/auth_controller.dart';
import 'dart:io';
import './watchlist_controller.dart';
import './models/log_model.dart';
import '../../../helpers/date_controller.dart';
import '../../../services/hive_service.dart';

class FoodListView extends StatefulWidget {
  final String? initialSearch;

  const FoodListView({super.key, this.initialSearch});

  @override
  State<FoodListView> createState() => _FoodListViewState();
}

class _FoodListViewState extends State<FoodListView> {
  final _searchCtrl = TextEditingController();
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  bool _isMultiSelectMode = false;
  final Set<FoodModel> _selectedFoods = {};

  static const List<String> _filterCategories = [
    'Semua', 'Makanan Pokok', 'Lauk', 'Sayuran', 'Buah', 'Minuman', 'Snack', 'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<FoodController>();
      if (widget.initialSearch != null) {
        _searchCtrl.text = widget.initialSearch!;
        ctrl.search(widget.initialSearch!);
      } else {
        ctrl.resetFilters();
      }
      ctrl.loadFoods(userId: context.read<AuthController>().currentUser?.id);
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

    // Use controller's filtered foods and filter out manual ones for this view
    List<FoodModel> foods = ctrl.foods.where((f) => !f.id.startsWith('manual_')).toList();

    final totalPages = foods.isEmpty ? 1 : (foods.length / _itemsPerPage).ceil();
    final safeCurrentPage = _currentPage.clamp(0, totalPages - 1);
    final startIndex = safeCurrentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, foods.length);
    final pageItems = foods.isEmpty ? <FoodModel>[] : foods.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      
      appBar: AppBar(
        title: Text(_isMultiSelectMode ? '${_selectedFoods.length} Dipilih' : 'Database Makanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_isMultiSelectMode) {
              setState(() {
                _isMultiSelectMode = false;
                _selectedFoods.clear(); 
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
                if (!_isMultiSelectMode) _selectedFoods.clear();
              });
            },
            child: Text(
              _isMultiSelectMode ? 'Batal' : 'Pilih',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          )
        ],
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
                        value: ctrl.selectedCategory,
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
                            ctrl.setCategory(val);
                            setState(() => _currentPage = 0);
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
            child: RefreshIndicator(
              onRefresh: () async {
                final auth = context.read<AuthController>();
                await ctrl.syncWithFirebase(userId: auth.currentUser?.id);
              },
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: foods.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
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
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            itemCount: pageItems.length,
                            itemBuilder: (_, i) => _foodCard(context, pageItems[i], isDark),
                          ),
                        ),
                        if (totalPages > 1) _buildPagination(safeCurrentPage, totalPages, isDark),
                      ],
                    ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: _isMultiSelectMode && _selectedFoods.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showCheckoutBottomSheet(),
                  child: Text(
                    'Lanjut (${_selectedFoods.length} Makanan)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            )
          : null,

    );
  }

  Widget _buildPagination(int current, int total, bool isDark) {
    const int maxVisible = 5;

    int startPage = current - (maxVisible ~/ 2);
    if (startPage < 0) startPage = 0;

    int endPage = startPage + maxVisible - 1;
    if (endPage >= total) {
      endPage = total - 1;
      startPage = endPage - maxVisible + 1;
      if (startPage < 0) startPage = 0;
    }

    List<int> visiblePages = [];
    for (int i = startPage; i <= endPage; i++) {
      visiblePages.add(i);
    }

    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(Icons.chevron_left_rounded, current > 0, () => setState(() => _currentPage--), isDark),
          const SizedBox(width: 8),
          
          ...visiblePages.map((i) {
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
          }),
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
        final isSelected = _selectedFoods.contains(food); 

        return GestureDetector(
          onLongPress: () {
            if (!_isMultiSelectMode) {
              setState(() {
                _isMultiSelectMode = true;
                _selectedFoods.add(food);
              });
            }
          },
          onTap: () {
            if (_isMultiSelectMode) {
              
              setState(() {
                if (isSelected) {
                  _selectedFoods.remove(food);
                } else {
                  _selectedFoods.add(food);
                }
              });
            } else {
              
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FoodDetailView(food: food)),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.1) 
                  : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isSelected 
                      ? AppColors.primary 
                      : (isDark ? AppColors.darkBorder : AppColors.lightDivider),
                  width: isSelected ? 1.5 : 1.0, 
              ),
              
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
                  ? (food.imageUrl!.startsWith('http') 
                      ? Image.network(
                          food.imageUrl!,
                          width: 50, height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatar(food.name),
                        )
                      : Image.file(
                          File(food.imageUrl!),
                          width: 50, height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatar(food.name),
                        ))
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

            if (_isMultiSelectMode) ...[
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: 26,
              ),
            ],

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

  void _showCheckoutBottomSheet() {
    final menuNameCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, // Biar nggak ketutup keyboard
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              Text('Simpan Paket Makanan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${_selectedFoods.length} makanan terpilih', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 16),
              
              // Input Text Nama Menu
              TextField(
                controller: menuNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Menu (Misal: Makan Pagi, Bekal)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.restaurant_menu_rounded),
                ),
              ),
              const SizedBox(height: 24),
              
              // Tombol Pilihan Simpan
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_border_rounded),
                      label: const Text('Watchlist'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _saveToWatchlist(menuNameCtrl.text);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Riwayat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (menuNameCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nama menunya dulu ya!')));
                          return;
                        }
                        _saveToHistory(menuNameCtrl.text);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveToWatchlist(String menuName) async {
    final auth = context.read<AuthController>();
    final watchlistCtrl = context.read<WatchlistController>();
    final userId = auth.currentUser?.id ?? '';
    
    if (userId.isEmpty) return;

    for (var food in _selectedFoods) {
      if (!watchlistCtrl.isInWatchlist(userId, food.id)) {
        await watchlistCtrl.toggleWatchlist(userId, food); 
      }
    }

    if (!mounted) return;

    setState(() {
      _isMultiSelectMode = false;
      _selectedFoods.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil ditambahkan ke Watchlist!'), backgroundColor: Colors.green),
    );
  }

  void _saveToHistory(String menuName) async {
    final auth = context.read<AuthController>();
    final dateCtrl = context.read<DateController>(); 
    
    final userId = auth.currentUser?.id ?? auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    final selectedDate = dateCtrl.selectedDate;

    for (var food in _selectedFoods) {
      
      final uniqueId = 'log_${DateTime.now().millisecondsSinceEpoch}_${food.id}';
      
      final log = LogModel(
        id: uniqueId,
        userId: userId,
        foodName: food.name,
        category: food.category,
        calories: food.calories,
        protein: food.protein,
        carbs: food.carbs,
        fat: food.fat,
        servingSize: food.defaultServingSize,
        imageUrl: food.imageUrl,
        quantity: 1, 
        ingredientsJson: food.ingredientsJson,
        consumedAt: selectedDate,
        mealType: menuName, 
        syncStatus: 'pending',
      );

      await HiveService.logs.put(log.id, log);
      
      await Future.delayed(const Duration(milliseconds: 2)); 
    }

    if (!mounted) return;
    
    setState(() {
      _isMultiSelectMode = false;
      _selectedFoods.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menu "$menuName" berhasil ditambahkan ke Riwayat!'), 
        backgroundColor: Colors.green,
      ),
    );
  }
}

