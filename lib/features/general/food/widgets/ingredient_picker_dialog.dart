import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../food_controller.dart';
import '../models/food_model.dart';

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
    _results = context.read<FoodController>().foods;
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = context.read<FoodController>().foods;
      });
      return;
    }
    final all = context.read<FoodController>().foods;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pilih Bahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _promptManualIngredient(context),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Input Manual'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
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

  void _promptManualIngredient(BuildContext context) {
    final nameCtrl = TextEditingController();
    final gramCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Bahan Manual'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Bahan', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: gramCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah (gram/ml)', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Kalori (kcal)', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: proCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Protein (g)', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Karbo (g)', isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Lemak (g)', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final gram = double.tryParse(gramCtrl.text) ?? 0;
              final cal = double.tryParse(calCtrl.text) ?? 0;
              final pro = double.tryParse(proCtrl.text) ?? 0;
              final carb = double.tryParse(carbCtrl.text) ?? 0;
              final fat = double.tryParse(fatCtrl.text) ?? 0;

              if (name.isNotEmpty && gram > 0) {
                Navigator.pop(ctx);
                Navigator.pop(context, {
                  'isManual': true,
                  'name': name,
                  'grams': gram,
                  'calories': cal,
                  'protein': pro,
                  'carbs': carb,
                  'fat': fat,
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
