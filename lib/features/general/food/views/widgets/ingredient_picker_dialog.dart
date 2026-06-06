import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/features/general/food/controllers/food_controller.dart';
import 'package:nutritrack_app/features/general/food/models/food_model.dart';

class IngredientPickerDialog extends StatefulWidget {
  const IngredientPickerDialog({super.key});

  @override
  State<IngredientPickerDialog> createState() => _IngredientPickerDialogState();
}

class _IngredientPickerDialogState extends State<IngredientPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<FoodModel> _results = [];

  @override
  void initState() {
    super.initState();
    _results = context.read<FoodController>().allApproved;
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = context.read<FoodController>().allApproved;
      });
      return;
    }
    final all = context.read<FoodController>().allApproved;
    setState(() {
      _results = all.where((f) => f.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            const Text('Pilih Bahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari bahan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final food = _results[index];
                  return ListTile(
                    title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${food.category} • ${food.calories.toInt()} kcal / 100g'),
                    trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onTap: () {
                      _promptAmount(context, food);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _promptAmount(BuildContext context, FoodModel food) {
    final TextEditingController amountCtrl = TextEditingController(text: food.defaultServingSize.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Jumlah ${food.name}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: 'gram',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(amountCtrl.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx); // Close amount dialog
                Navigator.pop(context, {'food': food, 'grams': val}); // Return result
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

}

