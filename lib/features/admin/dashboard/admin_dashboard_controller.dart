import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../general/submission/submission_controller.dart';
import '../../general/submission/submission_model.dart';

class AdminDashboardController extends GetxController {
  final today = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final weekDates = <DateTime>[].obs;

  final isPaginatedView = false.obs;
  final currentPage = 0.obs;
  final itemsPerPage = 3;

  final allSubmissions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initDates();
    // Data di-load via listenToSubmissions() yang dipanggil dari View
    // karena butuh BuildContext untuk akses Provider
  }

  void _initDates() {
    DateTime now = DateTime.now();
    DateTime normalizedToday = DateTime(now.year, now.month, now.day);
    today.value = normalizedToday;
    selectedDate.value = normalizedToday;
    weekDates.value = List.generate(
      7,
      (index) => normalizedToday.add(Duration(days: index - 3)),
    );
  }

  /// Dipanggil dari View dengan context agar bisa akses SubmissionController.
  /// Setiap kali submissions berubah di Firestore, dashboard ikut update otomatis.
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
            default:
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
            'icon': '🍲',
            'date': item.createdAt,
            'calories':
                item.calories != null ? '${item.calories!.toInt()} kkal' : '-',
            'notes': item.reviewNote ?? item.nutriNote ?? '-',
          };
        }).toList();

    allSubmissions.value = data;
  }

  // ── Statistik ─────────────────────────────────────────────────────────────

  int get totalPengajuan => allSubmissions.length;
  int get totalMenunggu =>
      allSubmissions.where((item) => item['status'] == 'Menunggu').length;
  int get totalDitolak =>
      allSubmissions.where((item) => item['status'] == 'Ditolak').length;
  int get totalPengguna =>
      allSubmissions.map((item) => item['author']).toSet().length;

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
