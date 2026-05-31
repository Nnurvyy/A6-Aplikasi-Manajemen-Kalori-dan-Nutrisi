import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../general/submission/submission_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final today = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  
  final viewMonth = DateTime.now().month.obs;
  final viewYear = DateTime.now().year.obs;
  final weekDates = <DateTime>[].obs; 
  final monthDates = <DateTime>[].obs;

  final isPaginatedView = false.obs;
  final currentPage = 0.obs;
  final itemsPerPage = 3;

  final allSubmissions = <Map<String, dynamic>>[].obs;
  final totalUsersCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initDates();
    _generateMonthDates();
    fetchTotalUsers();
  }

  void _initDates() {
    DateTime now = DateTime.now();
    today.value = DateTime(now.year, now.month, now.day);
    selectedDate.value = today.value;
    
    int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;

    weekDates.value = List.generate(
      totalDaysInMonth,
      (index) => DateTime(now.year, now.month, index + 1),
    );
  }

  void _generateMonthDates() {
    final lastDay = DateTime(viewYear.value, viewMonth.value + 1, 0).day;
    monthDates.value = List.generate(
      lastDay,
      (index) => DateTime(viewYear.value, viewMonth.value, index + 1),
    );
  }

  void setMonthYear(int year, int month) {
    viewYear.value = year;
    viewMonth.value = month;
    _generateMonthDates();
    
    weekDates.value = List.generate(
      monthDates.length,
      (index) => DateTime(year, month, index + 1),
    );
    
    final now = DateTime.now();
    if (year == now.year && month == now.month) {
      changeDate(DateTime(now.year, now.month, now.day));
    } else {
      changeDate(DateTime(year, month, 1)); 
    }
  }

  bool hasSubmissionsOn(DateTime date) {
    return allSubmissions.any((s) {
      final sDate = s['date'] as DateTime;
      return sDate.year == date.year && sDate.month == date.month && sDate.day == date.day;
    });
  }

  void loadFromSubmissionController(List<SubmissionModel> submissions) {
    final data =
        submissions.map((item) {
          String statusStr;
          Color statusColor;
          Color bgColor;

          switch (item.status) {
            case SubmissionStatus.approved:
              statusStr = 'Diterima';
              statusColor = const Color(0xFF2E7D32);
              bgColor = Colors.green.shade50;
              break;
            case SubmissionStatus.canceled:
              statusStr = 'Ditolak';
              statusColor = Colors.red;
              bgColor = Colors.red.shade50;
              break;
            case SubmissionStatus.pending:
              statusStr = 'Menunggu';
              statusColor = Colors.orange;
              bgColor = Colors.orange.shade50;
              break;
          }

          return {
            'id': item.id,
            'name': item.foodName,
            'author': item.userName,
            'status': statusStr,
            'color': statusColor,
            'bgColor': bgColor,
            'imageUrl': item.imagePath,
            'date': item.createdAt,
            'calories':
                item.calories != null ? '${item.calories!.toInt()} kkal' : '-',
            'notes': item.reviewNote ?? item.nutriNote ?? '-',
          };
        }).toList();

    allSubmissions.value = data;
  }

  Future<void> fetchTotalUsers() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
          
      totalUsersCount.value = snapshot.docs.length; 
    } catch (e) {
      debugPrint("Gagal mengambil total pengguna dari Firebase: $e");
    }
  }

  // ── Statistik ─────────────────────────────────────────────────────────────

  int get totalPengajuan => allSubmissions.length;
  int get totalMenunggu =>
      allSubmissions.where((item) => item['status'] == 'Menunggu').length;
  int get totalDitolak =>
      allSubmissions.where((item) => item['status'] == 'Ditolak').length;
  int get totalPengguna => totalUsersCount.value;

  List<Map<String, dynamic>> getSubmissionsByStatus(String status) =>
      allSubmissions.where((item) => item['status'] == status).toList();

  // ── Navigasi ──────────────────────────────────────────────────────────────

  void changeDate(DateTime date) {
    selectedDate.value = date;
    isPaginatedView.value = false;
    currentPage.value = 0;
  }

  void togglePagination() {
    isPaginatedView.value = !isPaginatedView.value;
    currentPage.value = 0;
  }

  void changePage(int newPage) => currentPage.value = newPage;
  void previousPage() {
    if (currentPage.value > 0) currentPage.value--;
  }

  void nextPage(int totalPages) {
    if (currentPage.value < totalPages - 1) currentPage.value++;
  }
}
