import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './watchlist_controller.dart';
import './models/watchlist_model.dart';
import './food_detail_view.dart';
import '../auth/auth_controller.dart';

class WatchlistView extends StatefulWidget {
  const WatchlistView({super.key});

  @override
  State<WatchlistView> createState() => _WatchlistViewState();
}

class _WatchlistViewState extends State<WatchlistView> {
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistController>();
    final items = watchlist.items;

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
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Info bar
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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    itemCount: pageItems.length,
                    itemBuilder: (context, index) => _buildWatchlistCard(context, pageItems[index]),
                  ),
                ),
                if (totalPages > 1) _buildPagination(safeCurrentPage, totalPages),
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
          }).take(7).toList(),
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
          color: enabled ? const Color(0xFFF3E5F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFD0C8FF) : Colors.transparent,
          ),
        ),
        child: Icon(icon, size: 18, color: enabled ? const Color(0xFF7C4DFF) : _textMuted.withValues(alpha: 0.3)),
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
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
                  ? Image.network(
                      food.imageUrl!,
                      width: 50, height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatar(food.name, accentColor),
                    )
                  : _buildAvatar(food.name, accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
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
                        '${food.category} • ${food.defaultServingSize.toInt()}g',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
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
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: Color(0xFF7C4DFF), size: 16),
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
