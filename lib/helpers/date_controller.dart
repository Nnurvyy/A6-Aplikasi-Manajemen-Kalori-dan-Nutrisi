import 'package:flutter/material.dart';

class DateController extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setDate(DateTime date) {
    // Keep the time if needed, but usually for logging we just want the day.
    // However, if we want to log at 'now' time on a previous day:
    final now = DateTime.now();
    _selectedDate = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    );
    notifyListeners();
  }

  void resetToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }
}
