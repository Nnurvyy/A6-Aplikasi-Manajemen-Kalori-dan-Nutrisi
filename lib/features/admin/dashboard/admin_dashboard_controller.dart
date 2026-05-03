import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    _loadDataPengajuan(); 
  }

  void _initDates() {
    DateTime now = DateTime.now();
    DateTime normalizedToday = DateTime(now.year, now.month, now.day);
    
    today.value = normalizedToday;
    selectedDate.value = normalizedToday;
    
    weekDates.value = List.generate(7, (index) => normalizedToday.add(Duration(days: index - 3)));
  }

  void _loadDataPengajuan() {
    allSubmissions.value = [
      {'id': 1, 'name': 'Seblak Kuah Pedas', 'author': 'Budi Santoso', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🍲', 'date': today.value},
      {'id': 2, 'name': 'Kopi Susu Gula Aren', 'author': 'Rina Purna', 'status': 'Diteruskan', 'color': const Color(0xFF2E7D32), 'bgColor': Colors.green.shade100, 'icon': '🥤', 'date': today.value},
      {'id': 3, 'name': 'Ayam Geprek Nelongso', 'author': 'Siti Aminah', 'status': 'Ditolak', 'color': Colors.red, 'bgColor': Colors.red.shade100, 'icon': '🍗', 'date': today.value},
      {'id': 4, 'name': 'Salad Buah Premium', 'author': 'Kevin Jaya', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🥗', 'date': today.value},
      {'id': 5, 'name': 'Jus Alpukat Lumer', 'author': 'Dewi Lestari', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🥑', 'date': today.value},
      {'id': 6, 'name': 'Nasi Goreng Spesial', 'author': 'Ahmad M', 'status': 'Diteruskan', 'color': const Color(0xFF2E7D32), 'bgColor': Colors.green.shade100, 'icon': '🍛', 'date': today.value},
      {'id': 7, 'name': 'Mie Tek-Tek Abang', 'author': 'Joko Anwar', 'status': 'Ditolak', 'color': Colors.red, 'bgColor': Colors.red.shade100, 'icon': '🍜', 'date': today.value.subtract(const Duration(days: 1))},
      {'id': 8, 'name': 'Es Teh Manis Jumbo', 'author': 'Siskaeee', 'status': 'Menunggu', 'color': Colors.orange, 'bgColor': Colors.orange.shade100, 'icon': '🍹', 'date': today.value.add(const Duration(days: 1))},
    ];
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