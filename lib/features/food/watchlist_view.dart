import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'watchlist_controller.dart';
import 'models/watchlist_model.dart';
import 'food_detail_view.dart';
import '../auth/auth_controller.dart';

class WatchlistView extends StatelessWidget {
  const WatchlistView({super.key});

  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistController>();
    final items = watchlist.items;

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
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildWatchlistCard(context, items[index]),
            ),
    );
  }

  Widget _buildWatchlistCard(BuildContext context, WatchlistModel item) {
    final food = item.food;
    final Color accentColor = _categoryColor(food.category);
    
    // Calculate nutrients for default serving size
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
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  food.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.category} • ${food.defaultServingSize.toInt()}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _nutriChip('P ${protein.toStringAsFixed(1)}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                      const SizedBox(width: 4),
                      _nutriChip('K ${carbs.toStringAsFixed(1)}g', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      _nutriChip('L ${fat.toStringAsFixed(1)}g', const Color(0xFFFFF3E0), const Color(0xFFFF8C00)),
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const Text(
                  'kkal',
                  style: TextStyle(fontSize: 10, color: _textMuted),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    final userId = context.read<AuthController>().currentUser?.id;
                    if (userId != null) {
                      context.read<WatchlistController>().toggleWatchlist(userId, food);
                    }
                  },
                  child: const Icon(Icons.bookmark_rounded, color: Color(0xFF7C4DFF), size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutriChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded, size: 40, color: Color(0xFF7C4DFF)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada makanan tersimpan',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Simpan makanan favoritmu untuk akses cepat',
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
