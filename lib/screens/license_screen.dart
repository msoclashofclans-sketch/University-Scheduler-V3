import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'splash_screen.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _activateLicense() async {
    final code = _controller.text.trim();

    if (!code.startsWith('masoud@')) {
      _showError('لایسنس نامعتبر است. فرمت صحیح: masoud@تاریخ');
      return;
    }

    final datePart = code.replaceAll('masoud@', '');
    
    if (datePart.length != 8) {
      _showError('تاریخ باید ۸ رقم باشد (مثلاً 14050801).');
      return;
    }

    final licenseYear = int.tryParse(datePart.substring(0, 4));
    final licenseMonth = int.tryParse(datePart.substring(4, 6));
    final licenseDay = int.tryParse(datePart.substring(6, 8));

    if (licenseYear == null || licenseMonth == null || licenseDay == null) {
      _showError('تاریخ وارد شده معتبر نیست.');
      return;
    }

    final now = DateTime.now();
    final currentYear = now.year - 621; 
    final currentMonth = now.month;
    final currentDay = now.day;

    if (licenseYear < currentYear ||
        (licenseYear == currentYear && licenseMonth < currentMonth) ||
        (licenseYear == currentYear && licenseMonth == currentMonth && licenseDay < currentDay)) {
      _showError('تاریخ لایسنس منقضی شده است.');
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    final expireDate = now.add(const Duration(days: 120));
    await prefs.setString('expire_date', expireDate.toIso8601String());
    await prefs.setString('license_code', code);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConstants.dangerColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('فعال‌سازی لایسنس'), backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, size: 80, color: AppConstants.primaryColor),
                const SizedBox(height: 20),
                const Text('اعتبار نسخه شما به پایان رسیده است.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('برای ادامه استفاده، کد لایسنس دریافتی را وارد کنید.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'کد لایسنس',
                    hintText: 'masoud@14050801',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _activateLicense,
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('فعال‌سازی', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
