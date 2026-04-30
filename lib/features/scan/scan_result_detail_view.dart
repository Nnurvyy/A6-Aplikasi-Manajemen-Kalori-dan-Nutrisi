import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../helpers/app_colors.dart';
import '../food/models/food_model.dart';
import '../auth/auth_controller.dart';
import '../food/food_controller.dart';
import '../shared/widgets/nt_button.dart';
import 'package:intl/intl.dart';
import '../food/watchlist_controller.dart';
import '../../helpers/date_controller.dart';

class ScanResultDetailView extends StatefulWidget {
  final FoodModel food;
  final File? imageFile;

  final int? initialQuantity;

  const ScanResultDetailView({
    super.key,
    required this.food,
    this.imageFile,
    this.initialQuantity,
  });

  @override
  State<ScanResultDetailView> createState() => _ScanResultDetailViewState();
}

class _ScanResultDetailViewState extends State<ScanResultDetailView> {
  late double _currentGrams;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _currentGrams = widget.food.defaultServingSize;
    _quantity = widget.food.id == 'unknown' ? 1 : (widget.initialQuantity ?? 1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Nutrition per gram * selected grams * quantity
    final baseNutrition = widget.food.nutritionForAmount(_currentGrams);
    final nutrition = {
      'calories': baseNutrition['calories']! * _quantity,
      'protein': baseNutrition['protein']! * _quantity,
      'carbs': baseNutrition['carbs']! * _quantity,
      'fat': baseNutrition['fat']! * _quantity,
    };
    
    final watchlist = context.watch<WatchlistController>();
    final userId = auth.currentUser?.id;
    final isSaved = userId != null && watchlist.isInWatchlist(userId, widget.food.id);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ─── Header Image with Actions ───
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (userId != null && widget.food.id != 'unknown')
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    watchlist.toggleWatchlist(userId, widget.food);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSaved ? 'Dihapus dari simpanan' : 'Disimpan ke watchlist'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.imageFile != null
                  ? Image.file(widget.imageFile!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.fastfood_rounded, size: 80, color: AppColors.primary),
                    ),
            ),
          ),

          // ─── Details ───
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Info
                  Text(
                    widget.food.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${DateFormat('EEEE, h:mm a').format(DateTime.now())} • ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Deteksi AI',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ─── Main Calorie Card ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: AppColors.warning, size: 32),
                        const SizedBox(width: 16),
                        Column(
                          children: [
                            Text(
                              nutrition['calories']!.toStringAsFixed(0),
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Calories',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Macro Cards ───
                  Row(
                    children: [
                      _buildMacroCard('Protein', nutrition['protein']!, AppColors.proteinColor, Icons.fitness_center_rounded, isDark),
                      const SizedBox(width: 12),
                      _buildMacroCard('Carbs', nutrition['carbs']!, AppColors.carbsColor, Icons.grain_rounded, isDark),
                      const SizedBox(width: 12),
                      _buildMacroCard('Fat', nutrition['fat']!, AppColors.fatColor, Icons.opacity_rounded, isDark),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ─── Portion Slider ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Porsi Makan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${_currentGrams.toInt()} gram',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withOpacity(0.1),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _currentGrams,
                      min: 10,
                      max: 1000,
                      divisions: 99,
                      onChanged: (val) {
                        setState(() => _currentGrams = val);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Quantity Stepper ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah (Pcs/Porsi)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              icon: const Icon(Icons.remove_rounded, color: AppColors.primary),
                            ),
                            Text(
                              '$_quantity',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Batal', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: NtButton(
                label: 'Simpan ke Log',
                onPressed: () async {
                  final userId = context.read<AuthController>().currentUser?.id;
                  if (userId == null) return;
                  
                  final foodCtrl = context.read<FoodController>();

                  bool success = await foodCtrl.addFoodToDailyLog(
                    userId: userId,
                    foodName: widget.food.name,
                    category: widget.food.category,
                    calories: nutrition['calories']!,
                    protein: nutrition['protein']!,
                    carbs: nutrition['carbs']!,
                    fat: nutrition['fat']!,
                    mealType: '',
                    dateConsumed: context.read<DateController>().selectedDate,
                    servingSize: _currentGrams * _quantity,
                  );

                  if (mounted) {
                    if (success) {
                      Navigator.pop(context); // Close detail
                      Navigator.pop(context); // Close scan view
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.food.name} berhasil ditambahkan ke log'),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal menambahkan ke log.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(String label, double value, Color color, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(1)}g',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
