import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../general/auth/auth_controller.dart';
import '../../general/food/food_controller.dart';
import '../../general/food/models/log_model.dart';

class ChildLogView extends StatelessWidget {
  const ChildLogView({super.key});

  static const Color _primary = Color(0xFF1565C0);
  static const Color _bg = Color(0xFFE8F4FF);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final foodCtrl = context.watch<FoodController>();
    final childId = auth.currentUser?.id ?? '';
    
    final logs = foodCtrl.getUserLogs(childId)
      ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Manual Anak', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Hanya bisa dilihat', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${logs.length} log',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: logs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: logs.length,
              itemBuilder: (ctx, i) => _buildLogCard(logs[i]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.create_outlined, size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Anak Anda belum ada log makanan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2E1A)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogModel log) {
    final dateStr = DateFormat('d MMM y • HH:mm', 'id').format(log.consumedAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: log.imageUrl != null
                ? Image.file(File(log.imageUrl!), width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatar(log))
                : _buildAvatar(log),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.quantity > 1 ? '${log.quantity}x ${log.foodName}' : log.foodName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A2E1A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chip('${log.calories.round()} kcal', const Color(0xFFFFF8E1), const Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    _chip('P ${log.protein.round()}g', const Color(0xFFFFEBEE), const Color(0xFFE53935)),
                    const SizedBox(width: 4),
                    _chip('K ${log.carbs.round()}g', const Color(0xFFF3F8FF), _primary),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.visibility_outlined, color: _primary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(LogModel log) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          log.foodName.isNotEmpty ? log.foodName[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _primary),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

