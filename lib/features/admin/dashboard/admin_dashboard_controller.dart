import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../general/submission/submission_hive_model.dart'; 

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
    _loadDataAsli(); 
  }

  void _initDates() {
    DateTime now = DateTime.now();
    DateTime normalizedToday = DateTime(now.year, now.month, now.day);
    today.value = normalizedToday;
    selectedDate.value = normalizedToday;
    weekDates.value = List.generate(7, (index) => normalizedToday.add(Duration(days: index - 3)));
  }

  void _loadDataAsli() {
    try {
      
      final box = Hive.box<SubmissionHiveModel>('submissions');
      
      final data = box.values.map((item) {
        String rawStatus = item.status.toString().toLowerCase();
        String statusStr = 'Menunggu';
        Color statusColor = Colors.orange;
        Color bgColor = Colors.orange.shade50;

        if (rawStatus.contains('approved') || rawStatus.contains('diterima')) {
          statusStr = 'Diterima';
          statusColor = const Color(0xFF2E7D32);
          bgColor = Colors.green.shade50;
        } else if (rawStatus.contains('canceled') || rawStatus.contains('rejected') || rawStatus.contains('ditolak')) {
          statusStr = 'Ditolak';
          statusColor = Colors.red;
          bgColor = Colors.red.shade50;
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
          'calories': item.calories != null ? '${item.calories} kkal' : '-', 
          'notes': item.reviewNote ?? item.nutriNote ?? '-',   
        };
      }).toList();

      allSubmissions.value = data;

    } catch (e) {
      debugPrint("Gagal load data dari Hive: $e");
    }
  }

  int get totalPengajuan => allSubmissions.length;
  int get totalMenunggu => allSubmissions.where((item) => item['status'] == 'Menunggu').length;
  int get totalDitolak => allSubmissions.where((item) => item['status'] == 'Ditolak').length;
  
  int get totalPengguna {
    
    return allSubmissions.map((item) => item['author']).toSet().length;
  }

  List<Map<String, dynamic>> getSubmissionsByStatus(String status) {
    return allSubmissions.where((item) => item['status'] == status).toList();
  }

  void changeDate(DateTime date) {
    selectedDate.value = date;
    isPaginatedView.value = false;
    currentPage.value = 0;
  }

  void togglePagination() {
    isPaginatedView.value = !isPaginatedView.value;
    currentPage.value = 0;
  }

  void changePage(int newPage) {
    currentPage.value = newPage;
  }

  void previousPage() {
    if (currentPage.value > 0) currentPage.value--;
  }

  void nextPage(int totalPages) {
    if (currentPage.value < totalPages - 1) currentPage.value++;
  }
}