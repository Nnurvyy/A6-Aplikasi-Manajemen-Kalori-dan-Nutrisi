import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  final String _secretToken = dotenv.env['APP_SECRET_TOKEN'] ?? '';

  /// Melakukan request charge/pembuatan pembayaran ke Midtrans melalui backend Hono
  Future<Map<String, dynamic>> charge({
    required String orderId,
    required double grossAmount,
    required String name,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/api/payment/charge'),
      headers: {
        'Content-Type': 'application/json',
        'X-App-Secret': _secretToken,
      },
      body: jsonEncode({
        'orderId': orderId,
        'grossAmount': grossAmount.toInt(),
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMsg = response.statusCode.toString();
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          errorMsg = '$errorMsg - ${errorData['error']}';
        }
      } catch (_) {
        errorMsg = '$errorMsg - ${response.body}';
      }
      throw Exception('Gagal menghubungi Payment Gateway: $errorMsg');
    }
  }

  /// Memeriksa status transaksi pembayaran ke backend Hono
  Future<String?> checkTransactionStatus(String orderId) async {
    final response = await http.get(
      Uri.parse('$_backendUrl/api/payment/status/$orderId'),
      headers: {
        'X-App-Secret': _secretToken,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['transaction_status'] as String?;
    } else {
      throw Exception('Gagal mengecek status pembayaran.');
    }
  }
}
