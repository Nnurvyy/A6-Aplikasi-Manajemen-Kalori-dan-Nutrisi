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

    // Filter items based on type
    final List<FoodModel> savedItems = foodCtrl.allApproved
        .where((f) {
          if (ingredientsOnly) {
            return f.isManualIngredient;
          } else {
            // Complex compositions are manual foods with ingredients
            return f.id.startsWith('manual_') && !f.isManualIngredient && f.ingredientsJson != null;
          }
        })
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: item.imageUrl != null
              ? (item.imageUrl!.startsWith('http')
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(item.imageUrl!, fit: BoxFit.cover))
                  : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(item.imageUrl!), fit: BoxFit.cover)))
              : const Icon(Icons.restaurant_menu, color: Color(0xFF2E7D32)),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.defaultServingSize.round()}g • ${item.calories.round()} kcal'),
        trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF2E7D32)),
        onTap: () {
          Navigator.pop(context, {
            'isManual': false,
            'food': item,
            'grams': item.defaultServingSize,
          });
        },
      ),
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
