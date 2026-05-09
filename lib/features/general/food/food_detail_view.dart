import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../helpers/app_colors.dart';
import './models/food_model.dart';
import './models/log_model.dart';
import '../auth/auth_controller.dart';
import '../widgets/nt_button.dart';
import './food_controller.dart';
import './watchlist_controller.dart';
import '../../../helpers/date_controller.dart';
import 'dart:io';

class FoodDetailView extends StatefulWidget {
  final FoodModel food;
  final LogModel? initialLog;
  final bool isManual;

  const FoodDetailView({super.key, required this.food, this.initialLog, this.isManual = false});

  @override
  State<FoodDetailView> createState() => _FoodDetailViewState();
}

class _FoodDetailViewState extends State<FoodDetailView> {
  List<Map<String, dynamic>> _ingredientWeights = [];
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialLog?.quantity ?? 1;
    
    // Initialize weights
    final String? jsonStr = widget.initialLog?.ingredientsJson ?? widget.food.ingredientsJson;
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _ingredientWeights = decoded.map((e) {
          final map = Map<String, dynamic>.from(e);
          // If editing a log, 'grams' is already what's saved.
          // If from FoodModel database, we need to ensure we have the per-100g reference values.
          // However, FoodModel's ingredients usually already have 'calories', 'protein', etc.
          // Let's make sure we have the reference values (per 100g).
          
          // If the ingredient itself has multiple components, it would be complex.
          // But usually ingredients are base foods.
          return map;
        }).toList();
      } catch (e) {
        _setupSingleIngredient();
      }
    } else {
      _setupSingleIngredient();
    }
  }

  void _setupSingleIngredient() {
    _ingredientWeights = [{
      'id': widget.food.id,
      'name': widget.food.name,
      'grams': widget.initialLog?.servingSize ?? widget.food.defaultServingSize,
      'calories_base': widget.food.calories, // per 100g
      'protein_base': widget.food.protein,
      'carbs_base': widget.food.carbs,
      'fat_base': widget.food.fat,
      // For single ingredient, we also need to handle the display of current nutrition
      'calories': 0.0, // placeholder, will be calculated
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
    }];
    _updateIngredientNutrition(0, _ingredientWeights[0]['grams']);
  }

  void _updateIngredientNutrition(int index, double grams) {
    final ing = _ingredientWeights[index];
    
    // If it's a base ingredient from database, it has calories_base (per 100g).
    // If it's an ingredient picked from database during manual meal creation, 
    // we need to find its base values if they aren't there.
    
    double calBase = ing['calories_base'] ?? (ing['calories'] / (ing['grams'] > 0 ? ing['grams'] : 100)) * 100;
    double proBase = ing['protein_base'] ?? (ing['protein'] / (ing['grams'] > 0 ? ing['grams'] : 100)) * 100;
    double carbBase = ing['carbs_base'] ?? (ing['carbs'] / (ing['grams'] > 0 ? ing['grams'] : 100)) * 100;
    double fatBase = ing['fat_base'] ?? (ing['fat'] / (ing['grams'] > 0 ? ing['grams'] : 100)) * 100;

    setState(() {
      _ingredientWeights[index]['grams'] = grams;
      _ingredientWeights[index]['calories_base'] = calBase;
      _ingredientWeights[index]['protein_base'] = proBase;
      _ingredientWeights[index]['carbs_base'] = carbBase;
      _ingredientWeights[index]['fat_base'] = fatBase;
      
      final ratio = grams / 100;
      _ingredientWeights[index]['calories'] = calBase * ratio;
      _ingredientWeights[index]['protein'] = proBase * ratio;
      _ingredientWeights[index]['carbs'] = carbBase * ratio;
      _ingredientWeights[index]['fat'] = fatBase * ratio;
    });
  }

  Map<String, double> _calculateTotalNutrition() {
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (var ing in _ingredientWeights) {
      cal += (ing['calories'] ?? 0);
      pro += (ing['protein'] ?? 0);
      carb += (ing['carbs'] ?? 0);
      fat += (ing['fat'] ?? 0);
    }
    return {
      'calories': cal * _quantity,
      'protein': pro * _quantity,
      'carbs': carb * _quantity,
      'fat': fat * _quantity,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final nutrition = _calculateTotalNutrition();
    final totalGrams = _ingredientWeights.fold<double>(0, (sum, ing) => sum + (ing['grams'] ?? 0));
    
    final watchlist = context.watch<WatchlistController>();
    final userId = auth.currentUser?.id;
    final isSaved = userId != null && watchlist.isInWatchlist(userId, widget.food.id);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.initialLog != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => _deleteLog(context),
                ),
              if (userId != null)
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => watchlist.toggleWatchlist(userId, widget.food),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(),
            ),
          ),

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
                  _buildTitleAndMetadata(isDark),
                  const SizedBox(height: 32),
                  _buildMainCalorieCard(nutrition['calories']!, isDark),
                  const SizedBox(height: 24),
                  _buildMacroCards(nutrition, isDark),
                  const SizedBox(height: 40),

                  // ─── Ingredient Sliders ───
                  Text(
                    'Porsi Masing-masing Bahan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_ingredientWeights.length, (idx) {
                    final ing = _ingredientWeights[idx];
                    return _buildIngredientSlider(idx, ing, isDark);
                  }),

                  const SizedBox(height: 24),
                  _buildQuantityStepper(isDark),
                  
                  if (widget.food.description != null) _buildDescription(isDark),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(auth, nutrition, totalGrams, isDark),
    );
  }

  Widget _buildIngredientSlider(int index, Map<String, dynamic> ing, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ing['name'] ?? 'Bahan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                '${(ing['grams'] as double).round()} gram',
                style: GoogleFonts.poppins(
                  fontSize: 14,
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
              trackHeight: 4,
            ),
            child: Slider(
              value: (ing['grams'] as double).clamp(0, 2000),
              min: 0,
              max: 1000,
              divisions: 200,
              onChanged: (val) => _updateIngredientNutrition(index, val),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallNutriLabel('${(ing['calories'] as double).round()} kkal', Colors.orange),
              _smallNutriLabel('P ${(ing['protein'] as double).round()}g', Colors.red),
              _smallNutriLabel('K ${(ing['carbs'] as double).round()}g', Colors.amber),
              _smallNutriLabel('L ${(ing['fat'] as double).round()}g', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallNutriLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return widget.food.imageUrl != null
        ? (widget.food.imageUrl!.startsWith('http')
            ? Image.network(widget.food.imageUrl!, fit: BoxFit.cover)
            : Image.file(File(widget.food.imageUrl!), fit: BoxFit.cover))
        : Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Center(
              child: Icon(Icons.fastfood_rounded, size: 80, color: Colors.white.withOpacity(0.5)),
            ),
          );
  }

  Widget _buildTitleAndMetadata(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.initialLog != null) ...[
              const SizedBox(width: 8),
              Container(width: 4, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                'Dikonsumsi pkl ${widget.initialLog!.formattedTime}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMainCalorieCard(double calories, bool isDark) {
    return Container(
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
                calories.round().toString(),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                'kkal total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCards(Map<String, double> nutrition, bool isDark) {
    return Row(
      children: [
        _buildMacroCard('Protein', nutrition['protein']!, AppColors.proteinColor, Icons.fitness_center_rounded, isDark),
        const SizedBox(width: 12),
        _buildMacroCard('Carbs', nutrition['carbs']!, AppColors.carbsColor, Icons.grain_rounded, isDark),
        const SizedBox(width: 12),
        _buildMacroCard('Fat', nutrition['fat']!, AppColors.fatColor, Icons.opacity_rounded, isDark),
      ],
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
              '${value.round()}g',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(bool isDark) {
    return Row(
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
    );
  }

  Widget _buildDescription(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'Keterangan',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildBottomBar(AuthController auth, Map<String, double> nutrition, double totalGrams, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NtButton(
            label: widget.initialLog != null ? 'Update Riwayat' : 'Tambah ke Log',
            onPressed: () => _onSavePressed(auth, nutrition, totalGrams),
          ),
        ],
      ),
    );
  }

  void _onSavePressed(AuthController auth, Map<String, double> nutrition, double totalGrams) async {
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final foodCtrl = context.read<FoodController>();
    final String updatedIngredientsJson = jsonEncode(_ingredientWeights);
    
    if (widget.initialLog != null) {
      final updatedLog = widget.initialLog!.copyWith(
        servingSize: totalGrams,
        quantity: _quantity,
        calories: nutrition['calories']!,
        protein: nutrition['protein']!,
        carbs: nutrition['carbs']!,
        fat: nutrition['fat']!,
        ingredientsJson: updatedIngredientsJson,
      );
      await foodCtrl.updateLog(updatedLog);
    } else {
      final selectedDate = context.read<DateController>().selectedDate;
      await foodCtrl.addFoodToDailyLog(
        userId: userId,
        foodName: widget.food.name,
        category: widget.food.category,
        calories: nutrition['calories']!,
        protein: nutrition['protein']!,
        carbs: nutrition['carbs']!,
        fat: nutrition['fat']!,
        mealType: '',
        dateConsumed: selectedDate,
        servingSize: totalGrams,
        quantity: _quantity,
        isManual: widget.isManual,
        imageUrl: widget.food.imageUrl,
        ingredientsJson: updatedIngredientsJson,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.food.name} berhasil disimpan'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _deleteLog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Yakin ingin menghapus item ini dari riwayat harian?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<FoodController>().deleteLog(widget.initialLog!.id);
      Navigator.pop(context);
    }
  }
}
