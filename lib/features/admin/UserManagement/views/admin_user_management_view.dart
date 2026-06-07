import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/features/admin/UserManagement/controllers/admin_user_controller.dart';
import 'dart:io';

class AdminUserManagementView extends StatefulWidget {
  const AdminUserManagementView({super.key});

  @override
  State<AdminUserManagementView> createState() =>
      _AdminUserManagementViewState();
}

class _AdminUserManagementViewState extends State<AdminUserManagementView> {
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFF4CAF50);
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);
  static const Color _danger = Color(0xFFE53935);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentAdminId =
          context.read<AuthController>().currentUser?.id ?? '';
      context.read<AdminUserController>().loadUsers(currentAdminId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<AdminUserController>().search(_searchController.text);
  }

  Future<void> _toggleBlock(UserModel user) async {
    final willBlock = !user.isBlocked;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => _ConfirmDialog(
            title: willBlock ? 'Blokir Pengguna?' : 'Buka Blokir?',
            message:
                willBlock
                    ? '${user.name} tidak akan bisa login setelah diblokir.'
                    : '${user.name} akan bisa login kembali.',
            confirmLabel: willBlock ? 'Blokir' : 'Buka Blokir',
            confirmColor: willBlock ? _danger : _primary,
          ),
    );
    if (confirm != true || !mounted) return;

    await context.read<AdminUserController>().toggleBlock(user, willBlock);
    if (!mounted) return;
    _showSnack(
      willBlock
          ? '${user.name} berhasil diblokir'
          : '${user.name} berhasil dibuka blokirnya',
      willBlock ? _danger : _primary,
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => _ConfirmDialog(
            title: 'Hapus Pengguna?',
            message:
                'Akun ${user.name} beserta seluruh data log makanannya akan dihapus permanen.',
            confirmLabel: 'Hapus',
            confirmColor: _danger,
          ),
    );
    if (confirm != true || !mounted) return;

    await context.read<AdminUserController>().deleteUser(user);
    if (!mounted) return;
    _showSnack('${user.name} berhasil dihapus', _danger);
  }

  void _editUser(UserModel user) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _EditUserView(user: user)),
    );
  }

  void _showDetail(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _UserDetailSheet(
            user: user,
            onBlock: () {
              Navigator.pop(context);
              _toggleBlock(user);
            },
            onEdit: () {
              Navigator.pop(context);
              _editUser(user);
            },
            onDelete: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            onEditPlan: () {
              Navigator.pop(context);
              _showEditPlanDialog(user);
            },
          ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Dialog untuk mengubah plan, subscriptionStart, subscriptionEnd
  Future<void> _showEditPlanDialog(UserModel user) async {
    String selectedPlan = user.plan;
    DateTime? startDate = user.subscriptionStart;
    DateTime? endDate = user.subscriptionEnd;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickDate({required bool isEnd}) async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: isEnd
                    ? (endDate ?? DateTime.now().add(const Duration(days: 30)))
                    : (startDate ?? DateTime.now()),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setDialogState(() {
                  if (isEnd) {
                    endDate = picked;
                  } else {
                    startDate = picked;
                  }
                });
              }
            }

            final df = DateFormat('d MMM yyyy', 'id');
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Edit Plan Pengguna',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan',
                    style: TextStyle(
                        color: Color(0xFF5A7A5A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'free',
                          label: Text('Free'),
                          icon: Icon(Icons.person_outline_rounded)),
                      ButtonSegment(
                          value: 'premium',
                          label: Text('Premium'),
                          icon: Icon(Icons.workspace_premium_rounded)),
                    ],
                    selected: {selectedPlan},
                    onSelectionChanged: (s) =>
                        setDialogState(() => selectedPlan = s.first),
                    style: ButtonStyle(
                      foregroundColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return const Color(0xFF5A7A5A);
                      }),
                      backgroundColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return selectedPlan == 'premium'
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF4CAF50);
                        }
                        return Colors.transparent;
                      }),
                    ),
                  ),
                  if (selectedPlan == 'premium') ...[
                    const SizedBox(height: 14),
                    // Start date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded,
                          color: Color(0xFF4CAF50), size: 20),
                      title: const Text('Mulai Berlangganan',
                          style: TextStyle(fontSize: 13, color: Color(0xFF5A7A5A))),
                      subtitle: Text(
                        startDate != null ? df.format(startDate!) : 'Belum diatur',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B2A1B),
                            fontSize: 13),
                      ),
                      trailing: TextButton(
                        onPressed: () => pickDate(isEnd: false),
                        child: const Text('Pilih'),
                      ),
                    ),
                    // End date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_rounded,
                          color: Color(0xFFFFB300), size: 20),
                      title: const Text('Akhir Berlangganan',
                          style: TextStyle(fontSize: 13, color: Color(0xFF5A7A5A))),
                      subtitle: Text(
                        endDate != null ? df.format(endDate!) : 'Belum diatur',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B2A1B),
                            fontSize: 13),
                      ),
                      trailing: TextButton(
                        onPressed: () => pickDate(isEnd: true),
                        child: const Text('Pilih'),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Batal',
                      style: TextStyle(color: Color(0xFF5A7A5A))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedPlan == 'premium'
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    await context.read<AdminUserController>().updateUserPlan(
                          user,
                          plan: selectedPlan,
                          subscriptionStart:
                              selectedPlan == 'premium' ? startDate : null,
                          subscriptionEnd:
                              selectedPlan == 'premium' ? endDate : null,
                        );
                    if (mounted) {
                      _showSnack(
                        'Plan ${user.name} diperbarui ke $selectedPlan',
                        selectedPlan == 'premium'
                            ? const Color(0xFFFFB300)
                            : _primary,
                      );
                    }
                  },
                  child: const Text('Simpan',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Manajemen Pengguna',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<AdminUserController>(
        builder: (context, controller, child) {
          final filtered = controller.filteredUsers;
          final pageItems = controller.pageItems;
          final safePage = controller.safePage;
          final totalPages = controller.totalPages;

          return Column(
            children: [
              _buildSearchBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} pengguna',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (filtered.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        'Hal. ${safePage + 1}/${totalPages < 1 ? 1 : totalPages}',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child:
                    filtered.isEmpty
                        ? _buildEmptyState()
                        : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20, 4, 20, 8,
                                ),
                                itemCount: pageItems.length,
                                itemBuilder:
                                    (_, i) => _UserCard(
                                      user: pageItems[i],
                                      onDetail: () => _showDetail(pageItems[i]),
                                      onBlock: () => _toggleBlock(pageItems[i]),
                                      onEdit: () => _editUser(pageItems[i]),
                                      onDelete: () =>
                                          _deleteUser(pageItems[i]),
                                    ),
                              ),
                            ),
                            if (totalPages > 1)
                              _buildPagination(
                                controller,
                                safePage,
                                totalPages,
                              ),
                          ],
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: 'Cari nama atau email pengguna...',
            hintStyle: const TextStyle(color: Color(0xFF9EAD9E), fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _primary,
              size: 20,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: _textMuted,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<AdminUserController>().search('');
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(
    AdminUserController controller,
    int current,
    int total,
  ) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            Icons.first_page_rounded,
            current > 0,
            () => controller.setPage(0),
          ),
          const SizedBox(width: 4),
          _pageBtn(
            Icons.chevron_left_rounded,
            current > 0,
            () => controller.setPage(current - 1),
          ),
          const SizedBox(width: 8),
          ...List.generate(total, (i) {
            final isActive = i == current;
            return GestureDetector(
              onTap: () => controller.setPage(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? _primary : const Color(0xFFD0E8D0),
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
          }).take(7),
          const SizedBox(width: 8),
          _pageBtn(
            Icons.chevron_right_rounded,
            current < total - 1,
            () => controller.setPage(current + 1),
          ),
          const SizedBox(width: 4),
          _pageBtn(
            Icons.last_page_rounded,
            current < total - 1,
            () => controller.setPage(total - 1),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _bg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFD0E8D0) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _primary : _textMuted.withValues(alpha: 0.3),
        ),
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
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 40,
              color: _primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Belum ada pengguna'
                : 'Pengguna tidak ditemukan',
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          if (_searchController.text.isNotEmpty)
            Text(
              'untuk "${_searchController.text}"',
              style: const TextStyle(color: _textMuted, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ─── Plan Badge Helper ────────────────────────────────────────────────────────
Color _planBorderColor(String plan) {
  return plan == 'premium' ? const Color(0xFFFFB300) : const Color(0xFF1E88E5);
}

Color _planBadgeBg(String plan) {
  return plan == 'premium' ? const Color(0xFFFFF8E1) : const Color(0xFFE3F2FD);
}

Color _planBadgeText(String plan) {
  return plan == 'premium' ? const Color(0xFFE65100) : const Color(0xFF1565C0);
}

IconData _planIcon(String plan) {
  return plan == 'premium'
      ? Icons.workspace_premium_rounded
      : Icons.person_outline_rounded;
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

  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);
  static const Color _danger = Color(0xFFE53935);
  static const Color _primary = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final planColor = _planBorderColor(user.plan);
    return GestureDetector(
      onTap: onDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: planColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: planColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(user: user, size: 48, fontSize: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + blocked badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                            decoration:
                                user.isBlocked
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
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFFCDD2),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'Diblokir',
                            style: TextStyle(
                              color: _danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Email
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: user.isBlocked ? _danger : _primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Plan badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _planBadgeBg(user.plan),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _planBorderColor(user.plan), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_planIcon(user.plan),
                            size: 12, color: _planBadgeText(user.plan)),
                        const SizedBox(width: 4),
                        Text(
                          user.plan == 'premium' ? 'Premium' : 'Free',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _planBadgeText(user.plan),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'Detail',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Icon(
                  user.isSynced
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_upload_rounded,
                  size: 16,
                  color: user.isSynced ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Sheet: Detail User ─────────────────────────────────────────────────
class _UserDetailSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onBlock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEditPlan;

  const _UserDetailSheet({
    required this.user,
    required this.onBlock,
    required this.onEdit,
    required this.onDelete,
    required this.onEditPlan,
  });

  static const Color _primary = Color(0xFF4CAF50);
  static const Color _textDark = Color(0xFF1B2A1B);
  static const Color _textMuted = Color(0xFF5A7A5A);
  static const Color _danger = Color(0xFFE53935);
  static const Color _border = Color(0xFFC8E6C9);

  static String _shortActivity(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final words = raw.trim().split(RegExp(r'\s+'));
    return words.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final bmi =
        (user.weight != null && user.height != null)
            ? user.weight! / ((user.height! / 100) * (user.height! / 100))
            : null;

    final dateFormat = DateFormat('d MMM yyyy', 'id');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
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
                UserAvatar(
                  user: user,
                  size: 56,
                  fontSize: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: _textMuted, fontSize: 13),
                      ),
                      if (user.isBlocked)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Akun Diblokir',
                            style: TextStyle(
                              color: _danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: _border, thickness: 0.8, height: 0),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Plan Info ──────────────────────────────────────
                  _sectionTitle('Status Langganan'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _planBadgeBg(user.plan),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _planBorderColor(user.plan), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Icon(_planIcon(user.plan),
                            color: _planBadgeText(user.plan), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.plan == 'premium' ? 'PREMIUM' : 'FREE',
                                style: TextStyle(
                                  color: _planBadgeText(user.plan),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                              if (user.plan == 'premium') ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Mulai: ${user.subscriptionStart != null ? dateFormat.format(user.subscriptionStart!) : '-'}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _planBadgeText(user.plan)),
                                ),
                                Text(
                                  'Berakhir: ${user.subscriptionEnd != null ? dateFormat.format(user.subscriptionEnd!) : '-'}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _planBadgeText(user.plan),
                                      fontWeight: FontWeight.w700),
                                ),
                              ] else
                                Text(
                                  'Tidak ada masa berlangganan aktif',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _planBadgeText(user.plan)),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onEditPlan,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _planBorderColor(user.plan)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _planBorderColor(user.plan),
                                  width: 0.8),
                            ),
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                  color: _planBadgeText(user.plan),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Fisik ──────────────────────────────────────────
                  _sectionTitle('Data Fisik'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statChip(
                        '${user.weight?.toStringAsFixed(1) ?? '-'} kg',
                        'Berat',
                        const Color(0xFFE8F5E9),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        '${user.height?.toStringAsFixed(0) ?? '-'} cm',
                        'Tinggi',
                        const Color(0xFFE3F2FD),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        '${user.age ?? '-'} thn',
                        'Usia',
                        const Color(0xFFFFF8E1),
                      ),
                      const SizedBox(width: 8),
                      if (bmi != null)
                        _statChip(
                          bmi.toStringAsFixed(1),
                          'BMI',
                          const Color(0xFFF3E5F5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Akun ──────────────────────────────────────────
                  _sectionTitle('Informasi Akun'),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.wc_rounded,
                    'Jenis kelamin',
                    user.gender ?? '-',
                  ),
                  _infoRow(
                    Icons.cake_rounded,
                    'Tanggal lahir',
                    user.birthDate != null
                        ? dateFormat.format(user.birthDate!)
                        : '-',
                  ),
                  _infoRow(
                    Icons.fitness_center_rounded,
                    'Aktivitas',
                    _shortActivity(user.activityLevel),
                  ),
                  const SizedBox(height: 14),

                  // ── Nutrisi ────────────────────────────────────────
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
                          color: Colors.blue,
                          onTap: onEdit,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: user.isBlocked ? 'Buka Blokir' : 'Blokir',
                          icon:
                              user.isBlocked
                                  ? Icons.lock_open_rounded
                                  : Icons.block_rounded,
                          color:
                              user.isBlocked
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

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: _textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: _textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 11)),
      ],
    );
  }
}

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
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: Text(
        message,
        style: const TextStyle(color: Color(0xFF5A7A5A), fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Batal',
            style: TextStyle(color: Color(0xFF5A7A5A)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: confirmColor, fontWeight: FontWeight.w700),
          ),
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
  static const Color _bg = Color(0xFFF4F6F0);
  static const Color _surface = Colors.white;
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

  final _genders = ['Laki-laki', 'Perempuan'];

  static const List<String> _activities = [
    'Jarang olahraga',
    'Sedikit aktif',
    'Cukup aktif',
    'Sangat aktif',
    'Ekstra aktif',
  ];

  static String _normalizeActivity(String? raw) {
    if (raw == null || raw.isEmpty) return 'Jarang olahraga';
    final words =
        raw.trim().split(RegExp(r'\s+')).take(2).join(' ').toLowerCase();

    if (words.contains('ekstra')) return 'Ekstra aktif';
    if (words.contains('sangat') || words.contains('berat')) {
      return 'Sangat aktif';
    }
    if (words.contains('cukup') || words.contains('sedang')) {
      return 'Cukup aktif';
    }
    if (words.contains('sedikit') || words.contains('ringan')) {
      return 'Sedikit aktif';
    }

    return 'Jarang olahraga';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _weightCtrl = TextEditingController(
      text: widget.user.weight?.toStringAsFixed(1) ?? '',
    );
    _heightCtrl = TextEditingController(
      text: widget.user.height?.toStringAsFixed(0) ?? '',
    );
    _ageCtrl = TextEditingController(text: widget.user.age?.toString() ?? '');
    _targetCtrl = TextEditingController(
      text: widget.user.targetWeightGainPerMonth?.toStringAsFixed(1) ?? '0',
    );

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
        const SnackBar(content: Text('Nama dan email wajib diisi')),
      );
      return;
    }

    final errorMsg = await context.read<AdminUserController>().updateUser(
      widget.user,
      name: name,
      email: email,
      weight: double.tryParse(_weightCtrl.text),
      height: double.tryParse(_heightCtrl.text),
      age: int.tryParse(_ageCtrl.text),
      target: double.tryParse(_targetCtrl.text) ?? 0,
      gender: _gender,
      activityLevel: _activityLevel,
    );

    if (errorMsg != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<AdminUserController>().isSaving;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          'Edit Data Pengguna',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Simpan',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Informasi Dasar', [
            _buildField('Nama Lengkap', _nameCtrl, icon: Icons.person_rounded),
            _buildField(
              'Email',
              _emailCtrl,
              icon: Icons.email_rounded,
              type: TextInputType.emailAddress,
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('Data Fisik', [
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Berat (kg)',
                    _weightCtrl,
                    icon: Icons.monitor_weight_rounded,
                    type: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    'Tinggi (cm)',
                    _heightCtrl,
                    icon: Icons.height_rounded,
                    type: TextInputType.number,
                  ),
                ),
              ],
            ),
            _buildField(
              'Usia',
              _ageCtrl,
              icon: Icons.cake_rounded,
              type: TextInputType.number,
            ),
            _buildDropdown(
              'Jenis Kelamin',
              _gender,
              _genders,
              (v) => setState(() => _gender = v!),
              icon: Icons.wc_rounded,
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('Target & Aktivitas', [
            _buildDropdown(
              'Level Aktivitas',
              _activityLevel,
              _activities,
              (v) => setState(() => _activityLevel = v!),
              icon: Icons.fitness_center_rounded,
            ),
            _buildField(
              'Target BB/bulan (kg, + naik / - turun)',
              _targetCtrl,
              icon: Icons.trending_up_rounded,
              type: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
            ),
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
        color: _surface,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
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
          labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: _primary, size: 18),
          filled: true,
          fillColor: const Color(0xFFE8F5E9).withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
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
          labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: _primary, size: 18),
          filled: true,
          fillColor: const Color(0xFFE8F5E9).withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC8E6C9), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items:
            items.map((i) {
              return DropdownMenuItem(value: i, child: Text(i));
            }).toList(),
      ),
    );
  }
}

// ─── UserAvatar Widget (Offline-First) ───────────────────────────────────────
class UserAvatar extends StatefulWidget {
  final UserModel user;
  final double size;
  final double fontSize;
  const UserAvatar({
    super.key,
    required this.user,
    this.size = 46,
    this.fontSize = 18,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  void initState() {
    super.initState();
    _triggerDownloadIfNeeded();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.id != oldWidget.user.id ||
        widget.user.profileImageUrl != oldWidget.user.profileImageUrl) {
      _triggerDownloadIfNeeded();
    }
  }

  void _triggerDownloadIfNeeded() {
    final user = widget.user;
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      final hasLocal = user.localProfileImagePath != null &&
          File(user.localProfileImagePath!).existsSync();
      if (!hasLocal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context
                .read<AdminUserController>()
                .downloadAndCacheProfileImage(user);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final size = widget.size;
    final initials = user.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    const Color danger = Color(0xFFE53935);
    final Color borderColor = _planBorderColor(user.plan);
    final Color textColor = user.isBlocked ? danger : borderColor;

    final hasLocal = user.localProfileImagePath != null &&
        user.localProfileImagePath!.isNotEmpty &&
        File(user.localProfileImagePath!).existsSync();

    Widget avatarContent;
    if (hasLocal) {
      avatarContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(user.localProfileImagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(initials, textColor),
        ),
      );
    } else if (user.profileImageUrl != null &&
        user.profileImageUrl!.isNotEmpty) {
      avatarContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          user.profileImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(initials, textColor),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitials(initials, textColor);
          },
        ),
      );
    } else {
      avatarContent = _buildInitials(initials, textColor);
    }

    // Wrap with plan-colored border ring
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: avatarContent,
      ),
    );
  }

  Widget _buildInitials(String initials, Color textColor) {
    final user = widget.user;
    final bgColor = user.isBlocked
        ? const Color(0xFFFFEBEE)
        : user.plan == 'premium'
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFE3F2FD);
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
