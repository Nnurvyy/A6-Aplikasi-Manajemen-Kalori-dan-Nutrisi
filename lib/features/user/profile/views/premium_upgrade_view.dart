import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:nutritrack_app/features/general/auth/controllers/auth_controller.dart';
import 'package:nutritrack_app/helpers/app_colors.dart';

class PremiumUpgradeView extends StatefulWidget {
  const PremiumUpgradeView({super.key});

  @override
  State<PremiumUpgradeView> createState() => _PremiumUpgradeViewState();
}

class _PremiumUpgradeViewState extends State<PremiumUpgradeView> {
  bool _isLoading = false;
  String? _orderId;
  String? _redirectUrl;
  bool _isPendingPayment = false;
  Timer? _statusTimer;

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  static const _green = Color(0xFF2E7D32);
  static const _gold = Color(0xFFFFA000);

  Future<void> _initiatePayment() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    // Sanitize user.id to keep only characters allowed by Midtrans: alphanumeric, -, _, ., ~
    final cleanUserId = user.id.replaceAll(RegExp(r'[^a-zA-Z0-9\-\_\.\~]'), '_');
    final shortUserId = cleanUserId.length > 10 ? cleanUserId.substring(0, 10) : cleanUserId;
    final orderId = 'prem_${shortUserId}_${DateTime.now().millisecondsSinceEpoch}';
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final secretToken = dotenv.env['APP_SECRET_TOKEN'] ?? '';

    // Clean customer details
    final cleanName = user.name.trim().isEmpty ? 'User' : user.name.trim();
    var cleanEmail = user.email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      cleanEmail = 'user@example.com'; // Fallback for invalid/empty emails during testing
    }

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/payment/charge'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Secret': secretToken,
        },
        body: jsonEncode({
          'orderId': orderId,
          'grossAmount': 20000,
          'name': cleanName,
          'email': cleanEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final redirectUrl = data['redirect_url'] as String;

        setState(() {
          _orderId = orderId;
          _redirectUrl = redirectUrl;
          _isPendingPayment = true;
          _isLoading = false;
        });
        _startStatusPolling();

        // Launch redirect URL in the external browser
        final uri = Uri.parse(redirectUrl);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Auto-launch failed: $e');
        }
      } else {
        // Parse the error message from the response body for better debugging
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_orderId == null) return;

    setState(() {
      _isLoading = true;
    });

    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final secretToken = dotenv.env['APP_SECRET_TOKEN'] ?? '';

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/payment/status/$_orderId'),
        headers: {
          'X-App-Secret': secretToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionStatus = data['transaction_status'] as String?;

        if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
          // Success! Update User state to premium
          final auth = context.read<AuthController>();
          final user = auth.currentUser;
          if (user != null) {
            final now = DateTime.now();
            final updated = user.copyWith(
              plan: 'premium',
              subscriptionStart: now,
              subscriptionEnd: now.add(const Duration(days: 30)),
            );
            await auth.updateProfile(updated);

            setState(() {
              _isLoading = false;
              _isPendingPayment = false;
            });

            if (mounted) {
              await _showSuccessDialog();
              Navigator.pop(context);
            }
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pembayaran belum diselesaikan. Status: ${transactionStatus ?? 'Unknown'}',
                ),
              ),
            );
          }
        }
      } else {
        throw Exception('Gagal mengecek status pembayaran.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || !_isPendingPayment || _orderId == null) {
        timer.cancel();
        return;
      }
      await _pollPaymentStatus(timer);
    });
  }

  Future<void> _pollPaymentStatus(Timer timer) async {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
    final secretToken = dotenv.env['APP_SECRET_TOKEN'] ?? '';

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/payment/status/$_orderId'),
        headers: {
          'X-App-Secret': secretToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionStatus = data['transaction_status'] as String?;

        if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
          timer.cancel();
          _statusTimer?.cancel();

          // Success! Update User state to premium
          final auth = context.read<AuthController>();
          final user = auth.currentUser;
          if (user != null) {
            final now = DateTime.now();
            final updated = user.copyWith(
              plan: 'premium',
              subscriptionStart: now,
              subscriptionEnd: now.add(const Duration(days: 30)),
            );
            await auth.updateProfile(updated);

            setState(() {
              _isPendingPayment = false;
            });

            if (mounted) {
              await _showSuccessDialog();
              Navigator.pop(context);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Polling status failed: $e');
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: _gold, size: 28),
            SizedBox(width: 8),
            Text('Upgrade Sukses!', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Selamat! Akun Anda kini menjadi Premium. Nikmati scan Gemini dan pencarian Groq AI tanpa batas tanpa iklan!',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mulai Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isPremium = user?.plan == 'premium';

    // Format Dates
    final today = DateTime.now();
    final nextMonth = today.add(const Duration(days: 30));
    final String formattedToday = DateFormat('d MMMM yyyy', 'id').format(today);
    final String formattedNextMonth = DateFormat('d MMMM yyyy', 'id').format(nextMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        title: Text(isPremium ? 'Status Keanggotaan' : 'Upgrade Premium'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isPremium) ...[
                      // ─── Premium Active Page ───
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: _gold, size: 70),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Premium Aktif',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Terima kasih telah bergabung dengan NutriTrack Premium!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subscription Details Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.calendar_today_rounded,
                              'Mulai Langganan',
                              user?.subscriptionStart != null
                                  ? DateFormat('d MMMM yyyy', 'id').format(user!.subscriptionStart!)
                                  : formattedToday,
                            ),
                            const Divider(height: 24, thickness: 0.8),
                            _buildDetailRow(
                              Icons.event_busy_rounded,
                              'Masa Berlaku Hingga',
                              user?.subscriptionEnd != null
                                  ? DateFormat('d MMMM yyyy', 'id').format(user!.subscriptionEnd!)
                                  : formattedNextMonth,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Benefits Section Title
                      Text(
                        'Keuntungan Premium Anda:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1A2E1A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Benefits List
                      _buildBenefitRow(Icons.auto_awesome_rounded, 'Scan Gemini Tanpa Batas', 'Estimasikan gizi dari foto porsi makanan tanpa batas harian.'),
                      const SizedBox(height: 16),
                      _buildBenefitRow(Icons.search_rounded, 'Pencarian AI Groq Tanpa Batas', 'Cari nutrisi makanan dari nama teks tanpa batas harian.'),
                      const SizedBox(height: 16),
                      _buildBenefitRow(Icons.no_photography_rounded, 'Bebas Iklan Selamanya', 'Nikmati aplikasi tanpa gangguan jeda iklan 15 detik.'),
                      const Spacer(),

                      // Back Button / Success Note
                      Center(
                        child: Text(
                          'Langganan Anda dikelola secara otomatis.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ] else if (!_isPendingPayment) ...[
                      // ─── Purchase Benefits Page (Free plan viewing upgrade) ───
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: _gold, size: 70),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'NutriTrack Premium',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tingkatkan pengalaman hidup sehatmu tanpa batasan!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subscription Dates Estimation Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.calendar_today_rounded,
                              'Estimasi Mulai',
                              formattedToday,
                              isHighlight: false,
                            ),
                            const Divider(height: 20, thickness: 0.8),
                            _buildDetailRow(
                              Icons.event_available_rounded,
                              'Masa Aktif (30 Hari)',
                              formattedNextMonth,
                              isHighlight: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Benefits List
                      _buildBenefitRow(Icons.auto_awesome_rounded, 'Scan Gemini Tanpa Batas', 'Estimasikan gizi dari foto porsi makanan tanpa batas harian.'),
                      const SizedBox(height: 16),
                      _buildBenefitRow(Icons.search_rounded, 'Pencarian AI Groq Tanpa Batas', 'Cari nutrisi makanan dari nama teks tanpa batas harian.'),
                      const SizedBox(height: 16),
                      _buildBenefitRow(Icons.no_photography_rounded, 'Bebas Iklan Selamanya', 'Nikmati aplikasi tanpa gangguan jeda iklan 15 detik.'),
                      const Spacer(),

                      // Price & Checkout Button
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Harga', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                Text('Rp 20.000 / bln', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: _green)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _initiatePayment,
                              child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // ─── Payment Pending Page ───
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payment_rounded, color: Colors.blue, size: 70),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Pembayaran Sedang Berlangsung',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Silakan selesaikan pembayaran pada tab browser yang telah dibuka. Jika halaman pembayaran tidak terbuka otomatis, silakan klik tombol "Buka Halaman Pembayaran" di bawah ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (_redirectUrl != null) {
                            await launchUrl(Uri.parse(_redirectUrl!), mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Buka Halaman Pembayaran'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const Spacer(),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _checkPaymentStatus,
                        child: const Text('Saya Sudah Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          _statusTimer?.cancel();
                          setState(() {
                            _isPendingPayment = false;
                            _orderId = null;
                            _redirectUrl = null;
                          });
                        },
                        child: const Text('Kembali / Batalkan', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, {bool isHighlight = true}) {
    return Row(
      children: [
        Icon(icon, color: isHighlight ? _gold : Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A2E1A),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _green, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1A2E1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
