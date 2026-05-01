import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../helpers/app_colors.dart';
import './models/food_model.dart';
import '../auth/auth_controller.dart';
import '../widgets/nt_button.dart';
import './food_controller.dart';
import './watchlist_controller.dart';
import '../../../helpers/date_controller.dart';

class FoodDetailView extends StatefulWidget {
  final FoodModel food;
  final bool isManual;

  const FoodDetailView({super.key, required this.food, this.isManual = false});

  @override
  State<FoodDetailView> createState() => _FoodDetailViewState();
}

class _FoodDetailViewState extends State<FoodDetailView> {
  late double _currentGrams;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _currentGrams = widget.food.defaultServingSize;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate nutrition: (per 100g * chosen gram / 100) * quantity
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
              if (userId != null)
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
              background: widget.food.imageUrl != null
                  ? Image.network(widget.food.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
                      child: Center(
                        child: Icon(Icons.fastfood_rounded, size: 80, color: Colors.white.withValues(alpha: 0.5)),
                      ),
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
                  // Title & Metadata
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
                        widget.food.category,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                      inactiveTrackColor: AppColors.primary.withValues(alpha: 0.1),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
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
                  
                  if (widget.food.description != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Keterangan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.food.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 120), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NtButton(
              label: 'Tambah ke Log',
              onPressed: () async {
                final userId = auth.currentUser?.id;
                if (userId == null) return;

                final foodCtrl = context.read<FoodController>();
                final selectedDate = context.read<DateController>().selectedDate;

                bool success = await foodCtrl.addFoodToDailyLog(
                  userId: userId,
                  foodName: widget.food.name,
                  category: widget.food.category,
                  calories: nutrition['calories']!,
                  protein: nutrition['protein']!,
                  carbs: nutrition['carbs']!,
                  fat: nutrition['fat']!,
                  mealType: '',
                  dateConsumed: selectedDate,
                  servingSize: _currentGrams * _quantity,
                  isManual: widget.isManual,
                );

                if (!context.mounted) return;
                if (success) {
                  Navigator.pop(context);
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
                      content: Text('Gagal menambahkan log.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
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
