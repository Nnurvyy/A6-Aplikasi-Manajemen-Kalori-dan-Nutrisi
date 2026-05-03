import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/hive_service.dart';
import '../../../helpers/calorie_helper.dart';
import '../../general/auth/auth_controller.dart';
import '../../general/auth/models/user_model.dart';

class AdminUserManagementView extends StatefulWidget {
  const AdminUserManagementView({super.key});

  @override
  State<AdminUserManagementView> createState() =>
      _AdminUserManagementViewState();
}

class _AdminUserManagementViewState extends State<AdminUserManagementView> {
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _primaryDark = Color(0xFF2E7D32);
  static const Color _textMuted = Color(0xFF5A7A5A);

  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allUsers = [];
  List<UserModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final currentAdminId =
        context.read<AuthController>().currentUser?.id ?? '';
    setState(() {
      _allUsers = HiveService.users.values
          .where((u) => u.role == 'user' && u.id != currentAdminId)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_allUsers)
          : _allUsers.where((u) {
              return u.name.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _toggleBlock(UserModel user) async {
    final willBlock = !user.isBlocked;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: willBlock ? 'Blokir Pengguna?' : 'Buka Blokir?',
        message: willBlock
            ? '${user.name} tidak akan bisa login setelah diblokir.'
            : '${user.name} akan bisa login kembali.',
        confirmLabel: willBlock ? 'Blokir' : 'Buka Blokir',
        confirmColor: willBlock
            ? const Color(0xFFE53935)
            : const Color(0xFF4CAF50),
      ),
    );
    if (confirm != true || !mounted) return;

    final updated = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      password: user.password,
      role: user.role,
      weight: user.weight,
      height: user.height,
      age: user.age,
      gender: user.gender,
      activityLevel: user.activityLevel,
      dailyCalorieNeed: user.dailyCalorieNeed,
      birthDate: user.birthDate,
      isBlocked: willBlock,
      targetWeightGainPerMonth: user.targetWeightGainPerMonth,
      initialWeight: user.initialWeight,
      targetHistory: user.targetHistory,
    );
    await HiveService.users.put(user.id, updated);
    _loadUsers();
    if (!mounted) return;
    _showSnack(
      willBlock
          ? '${user.name} berhasil diblokir'
          : '${user.name} berhasil dibuka blokirnya',
      willBlock ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
    );
  }

  void _editUser(UserModel user) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _EditUserView(user: user)),
    );
    if (result == true) _loadUsers();
  }

  void _showDetail(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: user,
        onBlock: () {
          Navigator.pop(context);
          _toggleBlock(user);
        },
        onEdit: () {
          Navigator.pop(context);
          _editUser(user);
        },
        onDelete: () {}, // TODO: commit 6
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_alt_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manajemen Pengguna',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${_allUsers.length} pengguna terdaftar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                color: _primaryDark,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _applyFilter();
                              },
                              child: Icon(Icons.close_rounded,
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                  size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search_rounded,
                        size: 64,
                        color: _textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Belum ada pengguna'
                          : 'Tidak ditemukan',
                      style: const TextStyle(
                          color: _textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Text(
                        'untuk "${_searchController.text}"',
                        style: const TextStyle(
                            color: _textMuted, fontSize: 13),
                      ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) => _UserCard(
                  user: _filtered[i],
                  onDetail: () => _showDetail(_filtered[i]),
                  onBlock: () => _toggleBlock(_filtered[i]),
                  onEdit: () => _editUser(_filtered[i]),
                  onDelete: () {}, // TODO: commit 6
                ),
              ),
      ),
    );
  }
}

// ─── Card User ────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDetail;
  final VoidCallback onBlock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onDetail,
    required this.onBlock,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _primary = Color(0xFF4CAF50);
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);
  static const Color _danger = Color(0xFFE53935);
  static const Color _border = Color(0xFFC8E6C9);

  @override
  Widget build(BuildContext context) {
    final initials = user.name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isBlocked ? const Color(0xFFFFCDD2) : _border,
          width: user.isBlocked ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: user.isBlocked
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: user.isBlocked ? _danger : _primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            decoration: user.isBlocked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: _danger,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isBlocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFFFCDD2),
                                width: 0.8),
                          ),
                          child: const Text(
                            'Diblokir',
                            style: TextStyle(
                                color: _danger,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style:
                        const TextStyle(color: _textMuted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onDetail,
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                backgroundColor: const Color(0xFFF1F8F1),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Detail',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'block') onBlock();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_rounded, size: 16, color: _primary),
                    const SizedBox(width: 8),
                    const Text('Edit Data',
                        style: TextStyle(fontSize: 14)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(children: [
                    Icon(
                      user.isBlocked
                          ? Icons.lock_open_rounded
                          : Icons.block_rounded,
                      size: 16,
                      color: user.isBlocked
                          ? _primary
                          : const Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.isBlocked ? 'Buka Blokir' : 'Blokir',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_rounded,
                        size: 16, color: _danger),
                    const SizedBox(width: 8),
                    const Text('Hapus Akun',
                        style: TextStyle(fontSize: 14, color: _danger)),
                  ]),
                ),
              ],
              icon: const Icon(Icons.more_vert_rounded,
                  color: Color(0xFFB0BEC5), size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Sheet: Detail User ────────────────────────────────────────────────
class _UserDetailSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onBlock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserDetailSheet({
    required this.user,
    required this.onBlock,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _primary = Color(0xFF4CAF50);
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);
  static const Color _danger = Color(0xFFE53935);
  static const Color _border = Color(0xFFC8E6C9);

  // Ambil 2 kata pertama dari string aktivitas (apapun formatnya dari DB)
  static String _shortActivity(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final words = raw.trim().split(RegExp(r'\s+'));
    return words.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final initials = user.name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bmi = (user.weight != null && user.height != null)
        ? user.weight! / ((user.height! / 100) * (user.height! / 100))
        : null;
    final dateFormat = DateFormat('d MMM yyyy', 'id');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: user.isBlocked
                          ? [
                              const Color(0xFFFFCDD2),
                              const Color(0xFFEF9A9A)
                            ]
                          : [
                              const Color(0xFFA5D6A7),
                              const Color(0xFF66BB6A)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: user.isBlocked ? _danger : _primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              color: _textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text(user.email,
                          style: const TextStyle(
                              color: _textMuted, fontSize: 13)),
                      if (user.isBlocked)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Akun Diblokir',
                            style: TextStyle(
                                color: _danger,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: _border, thickness: 0.8, height: 0),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Data Fisik'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statChip(
                          '${user.weight?.toStringAsFixed(1) ?? '-'} kg',
                          'Berat',
                          const Color(0xFFE8F5E9)),
                      const SizedBox(width: 8),
                      _statChip(
                          '${user.height?.toStringAsFixed(0) ?? '-'} cm',
                          'Tinggi',
                          const Color(0xFFE3F2FD)),
                      const SizedBox(width: 8),
                      _statChip('${user.age ?? '-'} thn', 'Usia',
                          const Color(0xFFFFF8E1)),
                      const SizedBox(width: 8),
                      if (bmi != null)
                        _statChip(bmi.toStringAsFixed(1), 'BMI',
                            const Color(0xFFF3E5F5)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle('Informasi Akun'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.wc_rounded, 'Jenis kelamin',
                      user.gender ?? '-'),
                  _infoRow(
                    Icons.cake_rounded,
                    'Tanggal lahir',
                    user.birthDate != null
                        ? dateFormat.format(user.birthDate!)
                        : '-',
                  ),
                  _infoRow(Icons.fitness_center_rounded, 'Aktivitas',
                      _shortActivity(user.activityLevel)),
                  const SizedBox(height: 14),
                  _sectionTitle('Target Nutrisi Harian'),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.local_fire_department_rounded,
                    'Kebutuhan kalori',
                    '${user.dailyCalorieNeed?.toStringAsFixed(0) ?? '-'} kkal',
                  ),
                  _infoRow(
                    Icons.trending_up_rounded,
                    'Target BB/bulan',
                    user.targetWeightGainPerMonth != null
                        ? '${user.targetWeightGainPerMonth! >= 0 ? '+' : ''}${user.targetWeightGainPerMonth!.toStringAsFixed(1)} kg'
                        : '-',
                  ),
                  _infoRow(
                    Icons.monitor_weight_rounded,
                    'BB awal',
                    '${user.initialWeight?.toStringAsFixed(1) ?? '-'} kg',
                  ),
                  if (user.macroTargets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          _macroChip(
                            'Protein',
                            '${user.macroTargets['protein']?.toStringAsFixed(0)}g',
                            const Color(0xFFEF5350),
                          ),
                          const Spacer(),
                          _macroChip(
                            'Karbo',
                            '${user.macroTargets['carbs']?.toStringAsFixed(0)}g',
                            const Color(0xFF42A5F5),
                          ),
                          const Spacer(),
                          _macroChip(
                            'Lemak',
                            '${user.macroTargets['fat']?.toStringAsFixed(0)}g',
                            const Color(0xFFFFA726),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Edit Data',
                          icon: Icons.edit_rounded,
                          color: _primary,
                          onTap: onEdit,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label:
                              user.isBlocked ? 'Buka Blokir' : 'Blokir',
                          icon: user.isBlocked
                              ? Icons.lock_open_rounded
                              : Icons.block_rounded,
                          color: user.isBlocked
                              ? _primary
                              : const Color(0xFFFF9800),
                          onTap: onBlock,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: 'Hapus',
                          icon: Icons.delete_rounded,
                          color: _danger,
                          onTap: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: _textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8));

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: _textMuted, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: _textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _statChip(String value, String label, Color bg) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: _textMuted, fontSize: 10)),
            ],
          ),
        ),
      );

  Widget _macroChip(String label, String value, Color color) => Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style:
                  const TextStyle(color: _textMuted, fontSize: 11)),
        ],
      );
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 17)),
      content: Text(message,
          style:
              const TextStyle(color: Color(0xFF5A7A5A), fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal',
              style: TextStyle(color: Color(0xFF5A7A5A))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel,
              style: TextStyle(
                  color: confirmColor, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ─── Edit User View ───────────────────────────────────────────────────────────
class _EditUserView extends StatefulWidget {
  final UserModel user;
  const _EditUserView({required this.user});

  @override
  State<_EditUserView> createState() => _EditUserViewState();
}

class _EditUserViewState extends State<_EditUserView> {
  static const Color _primary = Color(0xFF4CAF50);
  static const Color _primaryDark = Color(0xFF2E7D32);
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _targetCtrl;
  String _gender = 'Laki-laki';
  String _activityLevel = 'Jarang olahraga';
  bool _isSaving = false;

  final _genders = ['Laki-laki', 'Perempuan'];
  static const List<String> _activities = [
    'Jarang olahraga',
    'Sedikit aktif',
    'Cukup aktif',
    'Sangat aktif',
    'Ekstra aktif',
  ];

  // Normalisasi nilai panjang dari DB → salah satu dari 5 opsi di atas
  static String _normalizeActivity(String? raw) {
    if (raw == null || raw.isEmpty) return 'Jarang olahraga';
    final words = raw.trim().split(RegExp(r'\s+')).take(2).join(' ').toLowerCase();
    if (words.contains('ekstra')) return 'Ekstra aktif';
    if (words.contains('sangat') || words.contains('berat')) return 'Sangat aktif';
    if (words.contains('cukup') || words.contains('sedang')) return 'Cukup aktif';
    if (words.contains('sedikit') || words.contains('ringan')) return 'Sedikit aktif';
    return 'Jarang olahraga';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _weightCtrl = TextEditingController(
        text: widget.user.weight?.toStringAsFixed(1) ?? '');
    _heightCtrl = TextEditingController(
        text: widget.user.height?.toStringAsFixed(0) ?? '');
    _ageCtrl =
        TextEditingController(text: widget.user.age?.toString() ?? '');
    _targetCtrl = TextEditingController(
        text: widget.user.targetWeightGainPerMonth?.toStringAsFixed(1) ??
            '0');
    _gender = widget.user.gender ?? 'Laki-laki';
    _activityLevel = _normalizeActivity(widget.user.activityLevel);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama dan email wajib diisi')));
      return;
    }

    final emailExists = HiveService.users.values.any((u) =>
        u.email.toLowerCase() == email.toLowerCase() &&
        u.id != widget.user.id);
    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email sudah digunakan pengguna lain')));
      return;
    }

    setState(() => _isSaving = true);

    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);
    final target = double.tryParse(_targetCtrl.text) ?? 0;

    double? newCalorie = widget.user.dailyCalorieNeed;
    if (weight != null && height != null && age != null) {
      newCalorie = CalorieHelper.calculateDailyCalorieNeed(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: _gender,
        activityLevel: _activityLevel,
        targetWeightGainPerMonth: target,
      );
    }

    final updated = UserModel(
      id: widget.user.id,
      name: name,
      email: email,
      password: widget.user.password,
      role: widget.user.role,
      weight: weight,
      height: height,
      age: age,
      gender: _gender,
      activityLevel: _activityLevel,
      dailyCalorieNeed: newCalorie,
      birthDate: widget.user.birthDate,
      isBlocked: widget.user.isBlocked,
      targetWeightGainPerMonth: target,
      initialWeight: widget.user.initialWeight,
      targetHistory: widget.user.targetHistory,
    );

    await HiveService.users.put(updated.id, updated);
    setState(() => _isSaving = false);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Edit Data Pengguna',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Simpan',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Informasi Dasar', [
            _buildField('Nama Lengkap', _nameCtrl,
                icon: Icons.person_rounded),
            _buildField('Email', _emailCtrl,
                icon: Icons.email_rounded,
                type: TextInputType.emailAddress),
          ]),
          const SizedBox(height: 12),
          _buildSection('Data Fisik', [
            Row(children: [
              Expanded(
                  child: _buildField('Berat (kg)', _weightCtrl,
                      icon: Icons.monitor_weight_rounded,
                      type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildField('Tinggi (cm)', _heightCtrl,
                      icon: Icons.height_rounded,
                      type: TextInputType.number)),
            ]),
            _buildField('Usia', _ageCtrl,
                icon: Icons.cake_rounded,
                type: TextInputType.number),
            _buildDropdown('Jenis Kelamin', _gender, _genders,
                (v) => setState(() => _gender = v!),
                icon: Icons.wc_rounded),
          ]),
          const SizedBox(height: 12),
          _buildSection('Target & Aktivitas', [
            _buildDropdown(
                'Level Aktivitas', _activityLevel, _activities,
                (v) => setState(() => _activityLevel = v!),
                icon: Icons.fitness_center_rounded),
            _buildField(
                'Target BB/bulan (kg, + naik / - turun)', _targetCtrl,
                icon: Icons.trending_up_rounded,
                type: const TextInputType.numberWithOptions(
                    signed: true, decimal: true)),
          ]),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: _primary, size: 18),
          filled: true,
          fillColor: const Color(0xFFF9FFF9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFC8E6C9), width: 0.8)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFC8E6C9), width: 0.8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        style: const TextStyle(color: _textDark, fontSize: 14),
        dropdownColor: Colors.white,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: _primary, size: 18),
          filled: true,
          fillColor: const Color(0xFFF9FFF9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFC8E6C9), width: 0.8)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFC8E6C9), width: 0.8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
      ),
    );
  }
}