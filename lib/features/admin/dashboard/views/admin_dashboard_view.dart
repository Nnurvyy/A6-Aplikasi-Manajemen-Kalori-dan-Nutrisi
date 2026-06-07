import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_app/features/admin/dashboard/controllers/admin_dashboard_controller.dart';
import 'package:nutritrack_app/features/general/submission/controllers/submission_controller.dart'; 

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  String _formatDisplayDate(DateTime date) {
    List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDayShort(DateTime date) {
    List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    Get.put(AdminDashboardController());

    final submissions = context.watch<SubmissionController>().all;
    controller.loadFromSubmissionController(submissions);

    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Column(
        children: [
          
          Container(
            height: topPadding,
            width: double.infinity,
            color: const Color(0xFF2E7D32), 
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Obx(() {
                final filteredSubmissions =
                    controller.allSubmissions
                        .where(
                          (item) =>
                              item['date'].year ==
                                  controller.selectedDate.value.year &&
                              item['date'].month ==
                                  controller.selectedDate.value.month &&
                              item['date'].day == controller.selectedDate.value.day,
                        )
                        .toList();

                final totalPages =
                    (filteredSubmissions.length / controller.itemsPerPage).ceil();

                List<Map<String, dynamic>> displayedSubmissions;
                if (controller.isPaginatedView.value) {
                  int start =
                      controller.currentPage.value * controller.itemsPerPage;
                  int end = start + controller.itemsPerPage;
                  displayedSubmissions = filteredSubmissions.sublist(
                    start,
                    end > filteredSubmissions.length
                        ? filteredSubmissions.length
                        : end,
                  );
                } else {
                  displayedSubmissions =
                      filteredSubmissions.take(controller.itemsPerPage).toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context), 
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const SizedBox(height: 24),
                          _buildDateSelector(),
                          const SizedBox(height: 24),
                          _buildStatsGrid(context),
                          const SizedBox(height: 24),
                          _buildRecentSubmissionsHeader(filteredSubmissions.length),
                          const SizedBox(height: 12),
                          _buildSubmissionsList(context, displayedSubmissions),
                          if (controller.isPaginatedView.value && totalPages > 1)
                            _buildPaginationControls(totalPages),
                          
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NutriTrack',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showMonthYearPicker(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Obx(() {
                  DateTime date = controller.selectedDate.value;

                  List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
                  List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
                  String displayDateStr = '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        displayDateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded, 
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return AdminDateSelector(controller: controller);
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Pengguna',
                controller.totalPengguna.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Pengajuan',
                controller.totalPengajuan.toString(),
                Icons.description,
                const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Menunggu Validasi',
                controller.totalMenunggu.toString(),
                Icons.access_time_filled,
                Colors.orange,
                onTap:
                    () => _showStatusListBottomSheet(
                      context,
                      'Menunggu Validasi',
                      'Menunggu',
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pengajuan Ditolak',
                controller.totalDitolak.toString(),
                Icons.cancel,
                Colors.red,
                onTap:
                    () => _showStatusListBottomSheet(
                      context,
                      'Pengajuan Ditolak',
                      'Ditolak',
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSubmissionsHeader(int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar Pengajuan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (totalItems > 3)
          GestureDetector(
            onTap: () => controller.togglePagination(),
            child: Text(
              controller.isPaginatedView.value ? 'Tutup' : 'Lihat Semua',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionsList(
    BuildContext context,
    List<Map<String, dynamic>> submissions,
  ) {
    if (submissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pengajuan.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          submissions.map((item) {
            return GestureDetector(
              onTap: () => _showDetailDialog(context, item),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildSubmissionThumb(item['imageUrl'], size: 48),

                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Oleh: ${item['author']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item['bgColor'],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['status'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: item['color'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => controller.previousPage(),
          ),
          Text(
            '${controller.currentPage.value + 1} / $totalPages',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => controller.nextPage(totalPages),
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context) {
    int tempMonth = controller.selectedDate.value.month;
    int tempYear = controller.selectedDate.value.year;
    
    List<String> monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Pilih Bulan & Tahun',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Pilih Bulan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: tempMonth,
                        isExpanded: true,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(monthNames[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempMonth = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: tempYear,
                        isExpanded: true,
                        items: List.generate(10, (index) {
                          int year = DateTime.now().year - 5 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempYear = val);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                controller.setMonthYear(tempYear, tempMonth);
                Navigator.pop(context);
              },
              child: const Text('Pilih', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showStatusListBottomSheet(
    BuildContext context,
    String title,
    String status,
  ) {
    final list = controller.getSubmissionsByStatus(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${list.length} data ditemukan',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Data tidak tersedia')),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,

                        leading: _buildSubmissionThumb(item['imageUrl'], size: 40),

                        title: Text(
                          item['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          item['author'],
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.pop(context);
                          _showDetailDialog(context, item);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSubmissionThumb(item['imageUrl'], size: 160),

                const SizedBox(height: 16),
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Diajukan oleh: ${item['author']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                const Divider(),
                _detailRow('Status', item['status'], color: item['color']),
                _detailRow('Kalori', item['calories'] ?? '-'),
                _detailRow('Catatan', item['notes'] ?? '-', isLong: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? color,
    bool isLong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            isLong ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionThumb(String? imageUrl, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.fastfood_rounded,
                    color: Colors.grey.shade400, size: size * 0.5),
              ),
            )
          : Icon(Icons.fastfood_rounded,
              color: Colors.grey.shade400, size: size * 0.5),
    );
  }

}

class AdminDateSelector extends StatefulWidget {
  final AdminDashboardController controller;
  const AdminDateSelector({super.key, required this.controller});

  @override
  State<AdminDateSelector> createState() => _AdminDateSelectorState();
}

class _AdminDateSelectorState extends State<AdminDateSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients || widget.controller.weekDates.isEmpty) return;
    
    final now = DateTime.now();
    int todayIndex = widget.controller.weekDates.indexWhere((date) => 
      date.day == now.day && date.month == now.month && date.year == now.year
    );
    
    if (todayIndex != -1) {
      double offset = (todayIndex * 56.0) - (MediaQuery.of(context).size.width / 2) + 28.0;
      if (offset < 0) offset = 0;
      _scrollController.jumpTo(offset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDayShort(DateTime date) {
    List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Obx(() {
        if (widget.controller.weekDates.isEmpty) return const SizedBox();
        
        final now = DateTime.now();
        
        return ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.controller.weekDates.length,
          itemBuilder: (context, index) {
            final date = widget.controller.weekDates[index];
            
            bool isSelected = date.day == widget.controller.selectedDate.value.day &&
                              date.month == widget.controller.selectedDate.value.month &&
                              date.year == widget.controller.selectedDate.value.year;

            bool isToday = date.day == now.day &&
                           date.month == now.month &&
                           date.year == now.year;

            // Indikator Titik
            bool hasData = widget.controller.allSubmissions.any((s) => 
              s['date'].day == date.day && 
              s['date'].month == date.month && 
              s['date'].year == date.year
            );

            return GestureDetector(
              onTap: () => widget.controller.changeDate(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF2E7D32) 
                        : (isToday ? const Color(0xFF2E7D32).withValues(alpha: 0.5) : Colors.grey.shade200),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDayShort(date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isToday ? const Color(0xFF2E7D32) : Colors.black87),
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFFE57373),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
