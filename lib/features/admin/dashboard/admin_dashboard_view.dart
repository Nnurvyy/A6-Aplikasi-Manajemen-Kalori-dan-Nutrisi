import 'package:flutter/material.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {

  late DateTime _today;
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;

  bool _isPaginatedView = false;
  int _currentPage = 0;
  final int _itemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    
    _today = DateTime(_today.year, _today.month, _today.day);
    _selectedDate = _today;
    
    _weekDates = List.generate(7, (index) => _today.add(Duration(days: index - 3)));
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isPaginatedView = false;
      _currentPage = 0;
    });
  }

  List<Map<String, dynamic>> _getAllSubmissions() {
    return [
      {'id': 1, 'name': 'Seblak Kuah Pedas', 'author': 'Budi Santoso', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🍲', 'date': _today},
      {'id': 2, 'name': 'Kopi Susu Gula Aren', 'author': 'Rina Purna', 'status': 'Diteruskan', 'color': const Color(0xFF2E7D32), 'bgColor': Colors.green.shade100, 'icon': '🥤', 'date': _today},
      {'id': 3, 'name': 'Ayam Geprek Nelongso', 'author': 'Siti Aminah', 'status': 'Ditolak', 'color': Colors.red, 'bgColor': Colors.red.shade100, 'icon': '🍗', 'date': _today},
      {'id': 4, 'name': 'Salad Buah Premium', 'author': 'Kevin Jaya', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🥗', 'date': _today},
      {'id': 5, 'name': 'Jus Alpukat Lumer', 'author': 'Dewi Lestari', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🥑', 'date': _today},
      {'id': 6, 'name': 'Nasi Goreng Spesial', 'author': 'Ahmad M', 'status': 'Diteruskan', 'color': const Color(0xFF2E7D32), 'bgColor': Colors.green.shade100, 'icon': '🍛', 'date': _today},
      {'id': 7, 'name': 'Mie Tek-Tek Abang', 'author': 'Joko Anwar', 'status': 'Ditolak', 'color': Colors.red, 'bgColor': Colors.red.shade100, 'icon': '🍜', 'date': _today.subtract(const Duration(days: 1))},
      {'id': 8, 'name': 'Es Teh Manis Jumbo', 'author': 'Siskaeee', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🍹', 'date': _today.add(const Duration(days: 1))},
    ];
  }

  String _formatDisplayDate(DateTime date) {
    List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDayShort(DateTime date) {
    List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final allSubmissions = _getAllSubmissions();
    final filteredSubmissions = allSubmissions.where((item) => item['date'] == _selectedDate).toList();
    final totalPages = (filteredSubmissions.length / _itemsPerPage).ceil();
    
    List<Map<String, dynamic>> displayedSubmissions;
    if (_isPaginatedView) {
      int start = _currentPage * _itemsPerPage;
      int end = start + _itemsPerPage;
      displayedSubmissions = filteredSubmissions.sublist(start, end > filteredSubmissions.length ? filteredSubmissions.length : end);
    } else {
      displayedSubmissions = filteredSubmissions.take(_itemsPerPage).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildGreetingCard(),
              const SizedBox(height: 24),
              _buildDateSelector(allSubmissions),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildRecentSubmissionsHeader(filteredSubmissions.length),
              const SizedBox(height: 12),
              _buildSubmissionsList(displayedSubmissions),
              if (_isPaginatedView && totalPages > 1) _buildPaginationControls(totalPages),
            ],
          ),
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
            Text(
              'NutriTrack',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5),
            ),
            Text(
              'Admin Panel',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.black54, size: 22),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade100),
            ),
            child: const Center(
              child: Text('A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDateSelector(List<Map<String, dynamic>> allSubmissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(
              _formatDisplayDate(_selectedDate),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _weekDates.map((date) {
            bool isSelected = date == _selectedDate;
            bool hasData = allSubmissions.any((s) => s['date'] == date);

            return GestureDetector(
              onTap: () => _onDateSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 68,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDayShort(date),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.green.shade100 : Colors.grey.shade400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
                    ),
                    if (hasData && !isSelected) ...[
                      const SizedBox(height: 4),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle))
                    ] else if (isSelected) ...[
                      
                      const SizedBox(height: 8),
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
            Expanded(child: _buildStatCard('Total Pengguna', '1.245', Icons.people, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total Pengajuan', '328', Icons.description, const Color(0xFF2E7D32))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Menunggu', '14', Icons.access_time_filled, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Ditolak', '42', Icons.cancel, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        ],
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
            onTap: () {
              setState(() {
                _isPaginatedView = !_isPaginatedView;
                _currentPage = 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
              child: Text(
                _isPaginatedView ? 'Tutup Paginasi' : 'Lihat Semua',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionsList(List<Map<String, dynamic>> submissions) {
    if (submissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.list_alt, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text('Kosong', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 4),
            Text('Tidak ada pengajuan di tanggal ini.', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return Column(
      children: submissions.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Center(child: Text(item['icon'], style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Oleh: ${item['author']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: item['bgColor'], borderRadius: BorderRadius.circular(6)),
                child: Text(
                  item['status'].toString().toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item['color'], letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: _currentPage == 0 ? Colors.grey.shade300 : Colors.black54,
            onPressed: _currentPage == 0 ? null : () => setState(() => _currentPage--),
          ),
          Row(
            children: List.generate(totalPages, (index) {
              return GestureDetector(
                onTap: () => setState(() => _currentPage = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: _currentPage == totalPages - 1 ? Colors.grey.shade300 : Colors.black54,
            onPressed: _currentPage == totalPages - 1 ? null : () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }
}