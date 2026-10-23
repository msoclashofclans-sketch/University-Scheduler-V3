import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // 🚨 تبدیل تاریخ هجری شمسی به میلادی
  DateTime? _parsePersianDate(String persianDate) {
    try {
      // فرض بر این است که فرمت تاریخ 8 رقمی است: yyyymmdd
      // برای سادگی، سال را به میلادی تبدیل نمی‌کنیم، بلکه یک اعتبارسنجی ساده انجام می‌دهیم
      if (persianDate.length != 8) return null;
      
      final year = int.parse(persianDate.substring(0, 4));
      final month = int.parse(persianDate.substring(4, 6));
      final day = int.parse(persianDate.substring(6, 8));
      
      // تبدیل تقریبی هجری شمسی به میلادی
      final gregorianYear = year + 621;
      return DateTime(gregorianYear, month, day);
    } catch (e) {
      return null;
    }
  }

  Future<void> _activateLicense() async {
    final code = _controller.text.trim();

    // ۱. بررسی فرمت لایسنس
    if (!code.startsWith('masoud@')) {
      _showError('لایسنس نامعتبر است. فرمت صحیح: masoud@تاریخ');
      return;
    }

    final datePart = code.replaceAll('masoud@', '');
    final licenseDate = _parsePersianDate(datePart);

    if (licenseDate == null) {
      _showError('تاریخ وارد شده نامعتبر است.');
      return;
    }

    // ۲. بررسی اینکه تاریخ لایسنس از امروز جلوتر باشد
    if (licenseDate.isBefore(DateTime.now())) {
      _showError('تاریخ لایسنس منقضی شده است.');
      return;
    }

    // ۳. ثبت لایسنس جدید (۴ ماه اعتبار)
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    // تاریخ انقضای جدید: ۴ ماه (۱۲۰ روز) بعد از تاریخ وارد شده در لایسنس
    final newExpireDate = licenseDate.add(const Duration(days: 120));
    await prefs.setString('expire_date', newExpireDate.toIso8601String());
    await prefs.setString('license_code', code);

    if (mounted) {
      // هدایت به برنامه اصلی
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  void _showError(String msg) {
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
