import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../general/auth/auth_controller.dart';
import 'dashboard/admin_dashboard_view.dart';
import 'food/admin_food_list_view.dart';
import 'submission/admin_submission_view.dart';
import '../general/auth/login_view.dart';

class AdminMainView extends StatefulWidget {
  const AdminMainView({super.key});

  @override
  State<AdminMainView> createState() => _AdminMainViewState();
}

class _AdminMainViewState extends State<AdminMainView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardView(),
    const AdminFoodListView(),
    const AdminSubmissionView(),
  ];

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final user = authCtrl.currentUser;

    if (user == null) {
      return const LoginView();
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF4CAF50),
            unselectedItemColor: const Color(0xFFB0BEC5),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fastfood_rounded),
                label: 'Database Makanan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: 'Pengajuan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
