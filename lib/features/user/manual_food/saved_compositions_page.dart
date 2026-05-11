import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../general/food/food_controller.dart';
import '../../general/auth/auth_controller.dart';
import '../../general/food/models/food_model.dart';
import '../../general/food/models/log_model.dart';
import 'dart:io';

class SavedCompositionsPage extends StatelessWidget {
  final String title;
  final bool ingredientsOnly;
  const SavedCompositionsPage({super.key, this.title = 'Komposisi Tersimpan', this.ingredientsOnly = false});

  @override
  Widget build(BuildContext context) {
    final foodCtrl = context.watch<FoodController>();
    final authCtrl = context.watch<AuthController>();
    final userId = authCtrl.currentUser?.id ?? '';

    // Only show individual ingredients (tunggal)
    final List<FoodModel> savedItems = foodCtrl.manualFoods
        .where((f) => f.isManualIngredient)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Dedup by name
    final Map<String, FoodModel> uniqueItems = {};
    for (var item in savedItems) {
      uniqueItems[item.name.toLowerCase()] = item;
    }
    final displayList = uniqueItems.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: displayList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: displayList.length,
              itemBuilder: (ctx, idx) => _buildCard(context, displayList[idx]),
            ),
    );
  }

  Widget _buildCard(BuildContext context, FoodModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context, {
              'isManual': false,
              'food': item,
              'grams': item.defaultServingSize,
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: item.imageUrl != null
                      ? (item.imageUrl!.startsWith('http')
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(item.imageUrl!, fit: BoxFit.cover))
                          : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(item.imageUrl!), fit: BoxFit.cover)))
                      : const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF2E7D32), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1B2A1B))),
                      const SizedBox(height: 4),
                      Text('${item.defaultServingSize.round()}g • ${item.nutritionForAmount(item.defaultServingSize)['calories']?.round()} kcal', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _smallNutriChip('P ${item.nutritionForAmount(item.defaultServingSize)['protein']?.round()}g', Colors.red.shade50, Colors.red.shade700),
                          const SizedBox(width: 6),
                          _smallNutriChip('K ${item.nutritionForAmount(item.defaultServingSize)['carbs']?.round()}g', Colors.amber.shade50, Colors.amber.shade700),
                          const SizedBox(width: 6),
                          _smallNutriChip('L ${item.nutritionForAmount(item.defaultServingSize)['fat']?.round()}g', Colors.blue.shade50, Colors.blue.shade700),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_rounded, color: Color(0xFF2E7D32), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallNutriChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada komposisi tersimpan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
