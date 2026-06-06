import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:nutritrack_app/helpers/app_colors.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:nutritrack_app/features/general/views/widgets/nt_button.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:nutritrack_app/features/general/food/controllers/watchlist_controller.dart';
import 'package:nutritrack_app/helpers/date_controller.dart';
import 'package:nutritrack_app/services/offline_storage_service.dart';
import './scan_ingredient_edit_view.dart';

class ScanResultDetailView extends StatefulWidget {
  final FoodModel food;
  final File? imageFile;
  final Uint8List? processedImageBytes;

  final int? initialQuantity;

  const ScanResultDetailView({
    super.key,
    required this.food,
    this.imageFile,
    this.processedImageBytes,
    this.initialQuantity,
  });

  @override
  State<ScanResultDetailView> createState() => _ScanResultDetailViewState();
}

class _ScanResultDetailViewState extends State<ScanResultDetailView> {
  late double _currentGrams;
  int _quantity = 1;

  bool _hasIngredients = false;
  List<IngredientState> _ingredientStates = [];

  @override
  void initState() {
    super.initState();
    _currentGrams = widget.food.defaultServingSize;
    _quantity = widget.food.id == 'unknown' ? 1 : (widget.initialQuantity ?? 1);

    if (widget.food.ingredientsJson != null) {
      try {
        final parsed = jsonDecode(widget.food.ingredientsJson!);
        if (parsed is List && parsed.isNotEmpty) {
          _hasIngredients = true;
          for (var item in parsed) {
            _ingredientStates.add(IngredientState(item as Map<String, dynamic>));
          }
        }
      } catch (e) {
        debugPrint('Error parsing ingredients: $e');
      }
    }
  }

  @override
  void dispose() {
    for (var state in _ingredientStates) {
      state.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Map<String, double> nutrition;
    if (_hasIngredients) {
      double tCal = 0, tPro = 0, tCarb = 0, tFat = 0;
      for (var state in _ingredientStates) {
        tCal += double.tryParse(state.calCtrl.text) ?? 0;
        tPro += double.tryParse(state.proCtrl.text) ?? 0;
        tCarb += double.tryParse(state.carbCtrl.text) ?? 0;
        tFat += double.tryParse(state.fatCtrl.text) ?? 0;
      }
      nutrition = {
        'calories': tCal * _quantity,
        'protein': tPro * _quantity,
        'carbs': tCarb * _quantity,
        'fat': tFat * _quantity,
      };
      
      // Update _currentGrams as well so that if saved, it has the total grams
      double totalGrams = 0;
      for (var state in _ingredientStates) {
        totalGrams += double.tryParse(state.weightCtrl.text) ?? 0;
      }
      _currentGrams = totalGrams > 0 ? totalGrams : _currentGrams;

    } else {
      final baseNutrition = widget.food.nutritionForAmount(_currentGrams);
      nutrition = {
        'calories': baseNutrition['calories']! * _quantity,
        'protein': baseNutrition['protein']! * _quantity,
        'carbs': baseNutrition['carbs']! * _quantity,
        'fat': baseNutrition['fat']! * _quantity,
      };
    }
    
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
                      color: AppColors.primary.withValues(alpha: 0.1),
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
                          color: AppColors.error.withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nutrition['calories']!.toStringAsFixed(0),
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Total Kalori (kkal)',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
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

                  // ─── Portion Slider (Only if no ingredients) ───
                  if (!_hasIngredients) ...[
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
                  ],

                  if (_hasIngredients) ...[
                    Text(
                      'Komponen & Nutrisi (Bisa Diedit)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildEditableIngredientsList(isDark),
                    const SizedBox(height: 24),
                  ],

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
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))
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
                label: 'Simpan',
                onPressed: () async {
                  final userId = context.read<AuthController>().currentUser?.id;
                  if (userId == null) return;
                  
                  final foodCtrl = context.read<FoodController>();

                  // Simpan image ke offline storage
                  String? localFileName;
                  if (widget.imageFile != null) {
                    localFileName = await OfflineStorageService.saveLocalImage(await widget.imageFile!.readAsBytes());
                  } else if (widget.processedImageBytes != null) {
                    localFileName = await OfflineStorageService.saveLocalImage(widget.processedImageBytes!);
                  }

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
                    imageUrl: localFileName,
                  );

                  if (mounted) {
                    if (success) {
                      // Upload ke Cloudinary di background
                      if (localFileName != null) {
                        final logs = foodCtrl.getUserLogs(userId);
                        if (logs.isNotEmpty) {
                          OfflineStorageService.uploadAndSyncToFirebase(localFileName, userId, logs.last);
                        }
                      }

                      Navigator.pop(context); // Close detail & return to dashboard
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              '${value.toStringAsFixed(1)}g',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onWeightChanged(IngredientState state, String newText) {
    double? newWeight = double.tryParse(newText);
    if (newWeight != null && state.baseWeight > 0) {
      double ratio = newWeight / state.baseWeight;
      state.calCtrl.text = state._format(state.baseCal * ratio, 0);
      state.proCtrl.text = state._format(state.basePro * ratio);
      state.carbCtrl.text = state._format(state.baseCarb * ratio);
      state.fatCtrl.text = state._format(state.baseFat * ratio);
    }
    setState(() {}); // trigger macro recalculation
  }

  void _onMacroChanged(String _) {
    setState(() {}); // trigger macro recalculation without proportional scaling
  }

  List<Widget> _buildEditableIngredientsList(bool isDark) {
    return _ingredientStates.map((state) {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanIngredientEditView(
                name: state.originalData['name'] ?? '',
                initialGrams: double.tryParse(state.weightCtrl.text) ?? state.baseWeight,
                initialCalories: double.tryParse(state.calCtrl.text) ?? state.baseCal,
                initialProtein: double.tryParse(state.proCtrl.text) ?? state.basePro,
                initialCarbs: double.tryParse(state.carbCtrl.text) ?? state.baseCarb,
                initialFat: double.tryParse(state.fatCtrl.text) ?? state.baseFat,
              ),
            ),
          );
          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              state.originalData['name'] = result['name'];
              state.weightCtrl.text = _format(result['grams']);
              state.calCtrl.text = _format(result['calories'], 0);
              state.proCtrl.text = _format(result['protein']);
              state.carbCtrl.text = _format(result['carbs']);
              state.fatCtrl.text = _format(result['fat']);
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.originalData['name'] ?? '',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.weightCtrl.text} gram',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _nutriChip('${state.calCtrl.text} kkal', Colors.orange),
                        _nutriChip('P ${state.proCtrl.text}g', Colors.red),
                        _nutriChip('K ${state.carbCtrl.text}g', Colors.amber),
                        _nutriChip('L ${state.fatCtrl.text}g', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _nutriChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _format(double val, [int fractionDigits = 1]) {
    if (val == val.toInt()) return val.toInt().toString();
    return val.toStringAsFixed(fractionDigits);
  }
}

class IngredientState {
  final Map<String, dynamic> originalData;
  late TextEditingController weightCtrl;
  late TextEditingController calCtrl;
  late TextEditingController proCtrl;
  late TextEditingController carbCtrl;
  late TextEditingController fatCtrl;

  final double baseWeight;
  final double baseCal;
  final double basePro;
  final double baseCarb;
  final double baseFat;
  
  IngredientState(this.originalData) 
      : baseWeight = (originalData['weight_grams'] as num?)?.toDouble() ?? 1,
        baseCal = (originalData['calories'] as num?)?.toDouble() ?? 0,
        basePro = (originalData['protein'] as num?)?.toDouble() ?? 0,
        baseCarb = (originalData['carbs'] as num?)?.toDouble() ?? 0,
        baseFat = (originalData['fat'] as num?)?.toDouble() ?? 0 {
    weightCtrl = TextEditingController(text: _format(baseWeight));
    calCtrl = TextEditingController(text: _format(baseCal, 0));
    proCtrl = TextEditingController(text: _format(basePro));
    carbCtrl = TextEditingController(text: _format(baseCarb));
    fatCtrl = TextEditingController(text: _format(baseFat));
  }
  
  String _format(double val, [int fractionDigits = 1]) {
    if (val == val.toInt()) return val.toInt().toString();
    return val.toStringAsFixed(fractionDigits);
  }

  void dispose() {
    weightCtrl.dispose();
    calCtrl.dispose();
    proCtrl.dispose();
    carbCtrl.dispose();
    fatCtrl.dispose();
  }
}

