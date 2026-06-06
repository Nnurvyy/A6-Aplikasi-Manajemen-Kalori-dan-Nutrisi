import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/features/general/food/controllers/watchlist_controller.dart';
import 'package:nutritrack_app/features/general/food/models/watchlist_model.dart';
import './food_detail_view.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'dart:io';
import 'package:nutritrack_app/services/offline_storage_service.dart';
import 'package:nutritrack_app/features/general/food/models/food_combination_model.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:nutritrack_app/helpers/date_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutritrack_app/helpers/string_helper.dart';

class WatchlistView extends StatefulWidget {
  const WatchlistView({super.key});

  @override
  State<WatchlistView> createState() => _WatchlistViewState();
}

class _WatchlistViewState extends State<WatchlistView> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final user = auth.currentUser;
      if (user != null) {
        context.read<WatchlistController>().loadCombinations(user.id);
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
    final watchlist = context.watch<WatchlistController>();
    final items = watchlist.items;
    final combinations = watchlist.combinations; 
    final userId = context.watch<AuthController>().currentUser?.id ?? '';

    final totalPages = items.isEmpty ? 1 : (items.length / _itemsPerPage).ceil();
    final safeCurrentPage = _currentPage.clamp(0, totalPages - 1);
    final startIndex = safeCurrentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, items.length);
    final pageItems = items.isEmpty ? <WatchlistModel>[] : items.sublist(startIndex, endIndex);



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
          'Makanan Tersimpan',
          style: TextStyle(color: _textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
            ),
        ],

        bottom: TabBar(
          controller: _tabController,
          labelColor: _textDark, 
          indicatorColor: const Color(0xFF4CAF50), 
          tabs: const [
            Tab(text: 'Satuan'),
            Tab(text: 'Kombinasi Menu'),
          ],
      ),

      ),
      body: TabBarView(
      controller: _tabController,
      children: [
        items.isEmpty
            ? RefreshIndicator(
                onRefresh: () async {
                  final auth = context.read<AuthController>();
                  final user = auth.currentUser;
                  if (user != null) {
                    context.read<WatchlistController>().loadWatchlist(user.id);
                  }
                  await Future.delayed(const Duration(seconds: 1)); 
                },
                color: const Color(0xFF2E7D32),
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 100,
                    child: _buildEmptyState(),
                  ),
                ),
              )
            : Column(
                children: [
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                    child: Row(
                      children: [
                        Text(
                          '${items.length} makanan tersimpan',
                          style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (totalPages > 1)
                          Text(
                            'Hal. ${safeCurrentPage + 1}/$totalPages',
                            style: const TextStyle(fontSize: 12, color: _textMuted),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final auth = context.read<AuthController>();
                        final user = auth.currentUser;
                        if (user != null) {
                          context.read<WatchlistController>().loadWatchlist(user.id);
                        }
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      color: const Color(0xFF2E7D32),
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) => _buildWatchlistCard(context, pageItems[index]),
                    ),
                  ),
                ),
                if (totalPages > 1) _buildPagination(safeCurrentPage, totalPages),
              ],
            ),

            _buildCombinationTab(context, combinations, userId),

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
                  color: isActive ? const Color(0xFF7C4DFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? const Color(0xFF7C4DFF) : const Color(0xFFD0C8FF),
                  ),
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
          }).take(7),
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
          border: Border.all(
            color: enabled ? const Color(0xFFC8E6C9) : Colors.transparent,
          ),
        ),
        child: Icon(icon, size: 18, color: enabled ? const Color(0xFF2E7D32) : _textMuted.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildWatchlistCard(BuildContext context, WatchlistModel item) {
    final food = item.food;
    final Color accentColor = _categoryColor(food.category);
    
    final nutrients = food.nutritionForAmount(food.defaultServingSize);
    final calories = nutrients['calories'] ?? 0;
    final protein = nutrients['protein'] ?? 0;
    final carbs = nutrients['carbs'] ?? 0;
    final fat = nutrients['fat'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FoodDetailView(food: food)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor, width: 1),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: food.imageUrl != null
                  ? FutureBuilder<File?>(
                      future: OfflineStorageService.getImageFile(food.imageUrl!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            color: accentColor.withValues(alpha: 0.1),
                            child: const Center(
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            snapshot.data!,
                            width: 50, height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatar(food.name, accentColor),
                          );
                        }
                        return _buildAvatar(food.name, accentColor);
                      },
                    )
                  : _buildAvatar(food.name, accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        item.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                        size: 14,
                        color: item.isSynced ? Colors.blue.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
                      ),
                    ],
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
                        '${StringHelper.formatCategory(food.category)} • ${food.defaultServingSize.toInt()}g',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _nutriChip('P ${protein.round()}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                      const SizedBox(width: 4),
                      _nutriChip('K ${carbs.round()}g', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      _nutriChip('L ${fat.round()}g', const Color(0xFFFFF3E0), const Color(0xFFFF8C00)),
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF4CAF50)),
                ),
                const Text('kkal', style: TextStyle(fontSize: 10, color: _textMuted)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    final userId = context.read<AuthController>().currentUser?.id;
                    if (userId != null) {
                      context.read<WatchlistController>().toggleWatchlist(userId, food);
                      if (_currentPage > 0) setState(() => _currentPage--);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: Color(0xFF2E7D32), size: 16),
                  ),
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
          name[0].toUpperCase(),
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
    final isMonitor = context.watch<AuthController>().isMonitoring;
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
            child: const Icon(Icons.bookmark_border_rounded, size: 40, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 16),
          Text(
            isMonitor ? 'Belum ada makanan tersimpan oleh Anak' : 'Belum ada makanan tersimpan',
            style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (!isMonitor) ...[
            const SizedBox(height: 4),
            const Text(
              'Simpan makanan favoritmu untuk akses cepat',
              style: TextStyle(color: _textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  void _showLogComboBottomSheet(BuildContext context, FoodCombinationModel combo) {
    final menuNameCtrl = TextEditingController(text: combo.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1B2A1B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.lunch_dining_rounded, color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Log Kombinasi Menu',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1B2A1B)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan ${combo.foods.length} makanan ke riwayat makan harian Anda.',
                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              
              // Input Text Nama Menu / Waktu Makan
              TextField(
                controller: menuNameCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nama Waktu Makan (Misal: Makan Siang, Bekal)',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.restaurant_menu_rounded),
                ),
              ),
              const SizedBox(height: 24),
              
              // Tombol Konfirmasi Log
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                  label: Text('Tambah ke Riwayat', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (menuNameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Isi nama waktu makannya dulu ya!'))
                      );
                      return;
                    }
                    
                    final auth = context.read<AuthController>();
                    final dateCtrl = context.read<DateController>();
                    final foodCtrl = context.read<FoodController>();
                    
                    final userId = auth.currentUser?.id ?? '';
                    if (userId.isEmpty) return;

                    final selectedDate = dateCtrl.selectedDate;
                    final mealName = menuNameCtrl.text;

                    for (var food in combo.foods) {
                      await foodCtrl.addFoodToDailyLog(
                        userId: userId,
                        foodName: food.name,
                        category: food.category,
                        calories: food.calories,
                        protein: food.protein,
                        carbs: food.carbs,
                        fat: food.fat,
                        mealType: mealName,
                        dateConsumed: selectedDate,
                        servingSize: food.defaultServingSize,
                        quantity: 1,
                        isManual: false,
                        imageUrl: food.imageUrl,
                        ingredientsJson: food.ingredientsJson,
                        context: context,
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menu "$mealName" berhasil ditambahkan ke Riwayat!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCombinationTab(BuildContext context, List<FoodCombinationModel> combos, String userId) {
    if (combos.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => context.read<WatchlistController>().loadCombinations(userId),
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: _buildEmptyState(),
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> schemes = [
      {
        'bg': const Color(0xFFFFF0F5), // Lavender blush
        'border': const Color(0xFFFFC0CB), // Pink
        'accent': const Color(0xFFFF69B4),
        'icon': Icons.bakery_dining_rounded,
        'tagText': 'Menu Sarapan',
      },
      {
        'bg': const Color(0xFFE8F5E9), // Soft Mint
        'border': const Color(0xFFA7E8BD), 
        'accent': const Color(0xFF2E7D32),
        'icon': Icons.lunch_dining_rounded,
        'tagText': 'Menu Sehat',
      },
      {
        'bg': const Color(0xFFE8F0FE), // Soft Blue
        'border': const Color(0xFFD2E3FC),
        'accent': const Color(0xFF1A73E8),
        'icon': Icons.restaurant_menu_rounded,
        'tagText': 'Menu Lezat',
      },
      {
        'bg': const Color(0xFFFFF3E0), // Soft Orange
        'border': const Color(0xFFFFE0B2),
        'accent': const Color(0xFFE65100),
        'icon': Icons.emoji_food_beverage_rounded,
        'tagText': 'Menu Segar',
      },
      {
        'bg': const Color(0xFFF3E8FD), // Soft Purple
        'border': const Color(0xFFE9D2FD),
        'accent': const Color(0xFF681DA8),
        'icon': Icons.soup_kitchen_rounded,
        'tagText': 'Menu Spesial',
      },
    ];

    return RefreshIndicator(
      onRefresh: () async => context.read<WatchlistController>().loadCombinations(userId),
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: combos.length,
        itemBuilder: (context, index) {
          final combo = combos[index];
          final scheme = schemes[index % schemes.length];
          final accentColor = scheme['accent'] as Color;
          final borderVal = scheme['border'] as Color;
          final bgVal = scheme['bg'] as Color;
          final iconVal = scheme['icon'] as IconData;
          final tagText = scheme['tagText'] as String;

          double totalCal = combo.foods.fold(0, (sum, f) => sum + f.calories);
          double totalProtein = combo.foods.fold(0, (sum, f) => sum + f.protein);
          double totalCarbs = combo.foods.fold(0, (sum, f) => sum + f.carbs);
          double totalFat = combo.foods.fold(0, (sum, f) => sum + f.fat);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: bgVal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderVal, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconVal, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    combo.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold, 
                                      color: _textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  combo.isSynced == true ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                                  size: 14,
                                  color: combo.isSynced == true 
                                      ? Colors.blue.withValues(alpha: 0.8) 
                                      : Colors.orange.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                            Text(
                              tagText,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                        tooltip: 'Hapus Semua Kombinasi',
                        onPressed: () => context.read<WatchlistController>().deleteCombination(combo.id),
                      ),
                    ],
                  ),

                  const Divider(height: 20, thickness: 1),

                  ...combo.foods.map((food) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderVal.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FoodDetailView(food: food),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _categoryColor(food.category),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13, 
                                          fontWeight: FontWeight.bold,
                                          color: _textDark
                                        ),
                                      ),
                                      Text(
                                        '${StringHelper.formatCategory(food.category)} • ${food.defaultServingSize.round()}g',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${food.calories.toStringAsFixed(0)} kkal',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w600,
                                    color: _textMuted
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Colors.orange),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => context.read<WatchlistController>().removeFoodFromCombination(combo.id, food.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),

                  const Divider(height: 24, thickness: 1),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderVal.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights_rounded, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              'Total Nutrisi Kombinasi:',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNutrientInfo('🔥 Kalori', '${totalCal.toStringAsFixed(0)} kkal', accentColor),
                            _buildNutrientInfo('💪 Protein', '${totalProtein.toStringAsFixed(1)}g', accentColor),
                            _buildNutrientInfo('🍞 Karbo', '${totalCarbs.toStringAsFixed(1)}g', accentColor),
                            _buildNutrientInfo('🥑 Lemak', '${totalFat.toStringAsFixed(1)}g', accentColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'Makan Menu Ini',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showLogComboBottomSheet(context, combo),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.poppins(fontSize: 10, color: _textMuted, fontWeight: FontWeight.w500)
        ),
        const SizedBox(height: 2),
        Text(
          value, 
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)
        ),
      ],
    );
  }
}
