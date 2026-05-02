import 'package:flutter/material.dart';

class AdminUserManagementView extends StatelessWidget {
  const AdminUserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Manajemen Pengguna',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Coming soon...'),
      ),
    );
  }
}