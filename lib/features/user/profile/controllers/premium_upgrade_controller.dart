import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/features/general/auth/models/user_model.dart';
import 'package:nutritrack_app/services/payment_service.dart';

class PremiumUpgradeController extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _orderId;
  String? _redirectUrl;
  bool _isPendingPayment = false;
  bool _isSuccess = false;
  String? _errorMessage;
  Timer? _statusTimer;

  bool get isLoading => _isLoading;
  String? get orderId => _orderId;
  String? get redirectUrl => _redirectUrl;
  bool get isPendingPayment => _isPendingPayment;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void resetState() {
    _statusTimer?.cancel();
    _statusTimer = null;
    _isLoading = false;
    _orderId = null;
    _redirectUrl = null;
    _isPendingPayment = false;
    _isSuccess = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initiatePayment(UserModel user, AuthController authController) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Sanitize user.id to keep only characters allowed by Midtrans: alphanumeric, -, _, ., ~
    final cleanUserId = user.id.replaceAll(RegExp(r'[^a-zA-Z0-9\-\_\.\~]'), '_');
    final shortUserId = cleanUserId.length > 10 ? cleanUserId.substring(0, 10) : cleanUserId;
    final generatedOrderId = 'prem_${shortUserId}_${DateTime.now().millisecondsSinceEpoch}';

    // Clean customer details
    final cleanName = user.name.trim().isEmpty ? 'User' : user.name.trim();
    var cleanEmail = user.email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      cleanEmail = 'user@example.com'; // Fallback for invalid/empty emails during testing
    }

    try {
      final data = await _paymentService.charge(
        orderId: generatedOrderId,
        grossAmount: 20000,
        name: cleanName,
        email: cleanEmail,
      );

      final snapUrl = data['redirect_url'] as String;

      _orderId = generatedOrderId;
      _redirectUrl = snapUrl;
      _isPendingPayment = true;
      _isLoading = false;
      notifyListeners();

      _startStatusPolling(authController);

      // Launch redirect URL in the external browser
      final uri = Uri.parse(snapUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Auto-launch failed: $e');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkPaymentStatus(AuthController authController) async {
    if (_orderId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transactionStatus = await _paymentService.checkTransactionStatus(_orderId!);

      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        _statusTimer?.cancel();
        _statusTimer = null;
        
        // Success! Update User state to premium
        final user = authController.currentUser;
        if (user != null) {
          final now = DateTime.now();
          final updated = user.copyWith(
            plan: 'premium',
            subscriptionStart: now,
            subscriptionEnd: now.add(const Duration(days: 30)),
          );
          await authController.updateProfile(updated);

          _isPendingPayment = false;
          _isSuccess = true;
          _isLoading = false;
          notifyListeners();
        }
      } else {
        _isLoading = false;
        _errorMessage = 'Pembayaran belum diselesaikan. Status: ${transactionStatus ?? 'Unknown'}';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _startStatusPolling(AuthController authController) {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!_isPendingPayment || _orderId == null) {
        timer.cancel();
        return;
      }
      await _pollPaymentStatus(timer, authController);
    });
  }

  Future<void> _pollPaymentStatus(Timer timer, AuthController authController) async {
    try {
      final transactionStatus = await _paymentService.checkTransactionStatus(_orderId!);

      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        timer.cancel();
        _statusTimer?.cancel();
        _statusTimer = null;

        // Success! Update User state to premium
        final user = authController.currentUser;
        if (user != null) {
          final now = DateTime.now();
          final updated = user.copyWith(
            plan: 'premium',
            subscriptionStart: now,
            subscriptionEnd: now.add(const Duration(days: 30)),
          );
          await authController.updateProfile(updated);

          _isPendingPayment = false;
          _isSuccess = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Polling status failed: $e');
    }
  }
}
