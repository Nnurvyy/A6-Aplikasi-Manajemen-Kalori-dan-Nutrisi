import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../dashboard/admin_dashboard_controller.dart'; 

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  String _formatDisplayDate(DateTime date) {
    List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
          child: Obx(() {
            // Filter data untuk list bawah berdasarkan tanggal terpilih
            final filteredSubmissions = controller.allSubmissions
                .where((item) => 
                    item['date'].year == controller.selectedDate.value.year &&
                    item['date'].month == controller.selectedDate.value.month &&
                    item['date'].day == controller.selectedDate.value.day)
                .toList();

            final totalPages = (filteredSubmissions.length / controller.itemsPerPage).ceil();
            
            List<Map<String, dynamic>> displayedSubmissions;
            if (controller.isPaginatedView.value) {
              int start = controller.currentPage.value * controller.itemsPerPage;
              int end = start + controller.itemsPerPage;
              displayedSubmissions = filteredSubmissions.sublist(
                  start, end > filteredSubmissions.length ? filteredSubmissions.length : end);
            } else {
              displayedSubmissions = filteredSubmissions.take(controller.itemsPerPage).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildGreetingCard(),
                const SizedBox(height: 24),
                _buildDateSelector(),
                const SizedBox(height: 24),
                _buildStatsGrid(), 
                const SizedBox(height: 24),
                _buildRecentSubmissionsHeader(filteredSubmissions.length),
                const SizedBox(height: 12),
                _buildSubmissionsList(displayedSubmissions),
                if (controller.isPaginatedView.value && totalPages > 1) 
                  _buildPaginationControls(totalPages),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('NutriTrack', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5)),
            Text('Admin Panel', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
        _buildNotificationIcon(),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
          child: const Icon(Icons.notifications_outlined, color: Colors.black54, size: 22),
        ),
        Positioned(
          top: 8, right: 10,
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))),
        )
      ],
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Halo, Admin! 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('Berikut ringkasan sistem hari ini.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.green.shade100)),
            child: const Center(child: Text('A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
          )
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(_formatDisplayDate(controller.selectedDate.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: controller.weekDates.map((date) {
            bool isSelected = date.day == controller.selectedDate.value.day && date.month == controller.selectedDate.value.month;
            bool hasData = controller.allSubmissions.any((s) => s['date'].day == date.day && s['date'].month == date.month);

            return GestureDetector(
              onTap: () => controller.changeDate(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44, height: 68,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatDayShort(date), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.green.shade100 : Colors.grey.shade400)),
                    const SizedBox(height: 4),
                    Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                    if (hasData && !isSelected) ...[
                      const SizedBox(height: 4),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle))
                    ]
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Pengguna', controller.totalPengguna.toString(), Icons.people, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total Pengajuan', controller.totalPengajuan.toString(), Icons.description, const Color(0xFF2E7D32))),
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
                onTap: () => _showStatusListBottomSheet('Menunggu Validasi', 'Menunggu'),
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pengajuan Ditolak', 
                controller.totalDitolak.toString(), 
                Icons.cancel, 
                Colors.red,
                onTap: () => _showStatusListBottomSheet('Pengajuan Ditolak', 'Ditolak'),
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSubmissionsHeader(int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Daftar Pengajuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (totalItems > 3)
          GestureDetector(
            onTap: () => controller.togglePagination(),
            child: Text(
              controller.isPaginatedView.value ? 'Tutup' : 'Lihat Semua',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionsList(List<Map<String, dynamic>> submissions) {
    if (submissions.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text('Tidak ada pengajuan.', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: submissions.map((item) {
        return GestureDetector(
          onTap: () => _showDetailDialog(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(item['icon'], style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('Oleh: ${item['author']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: item['bgColor'], borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    item['status'].toString().toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item['color']),
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
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => controller.previousPage()),
          Text('${controller.currentPage.value + 1} / $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => controller.nextPage(totalPages)),
        ],
      ),
    );
  }

  void _showStatusListBottomSheet(String title, String status) {
    final list = controller.getSubmissionsByStatus(status);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Total: ${list.length} data ditemukan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                      leading: Text(item['icon'], style: const TextStyle(fontSize: 24)),
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(item['author'], style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        Get.back();
                        _showDetailDialog(item);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item['icon'], style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Diajukan oleh: ${item['author']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isLong ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? Colors.black87),
              textAlign: TextAlign.right,
            )
          ),
        ],
      ),
    );
  }
}