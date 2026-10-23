import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../utils/constants.dart';
import 'splash_screen.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final TextEditingController _controller = TextEditingController();
  String _deviceId = 'در حال دریافت...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  // 🚨 دریافت کد یکتای دستگاه
  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      String id = '';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // استفاده از id (Android 8+) یا fingerprint برای دستگاه‌های قدیمی‌تر
        id = androidInfo.id; 
        if (id.isEmpty) id = androidInfo.fingerprint;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor ?? '';
      }
      
      // کوتاه کردن کد برای راحتی کار
      final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
      
      setState(() {
        _deviceId = shortId;
      });
    } catch (e) {
      setState(() {
        _deviceId = 'ERROR-0000';
      });
    }
  }

  Future<void> _activateLicense() async {
    final inputCode = _controller.text.trim();

    if (inputCode.isEmpty) {
      _showError('لطفاً کد لایسنس را وارد کنید.');
      return;
    }

    // 🚨 فرمت لایسنس: کد دستگاه + یک خط تیره + تاریخ امروز (مثلاً A1B2C3D4-20261023)
    final now = DateTime.now();
    final todayDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final expectedLicense = '$_deviceId-$todayDate';

    // بررسی اینکه آیا کد وارد شده با فرمول ما همخوانی دارد یا نه
    if (inputCode != expectedLicense) {
      _showError('کد لایسنس نامعتبر است. لطفاً کد را با دقت وارد کنید.');
      return;
    }

    // اگر درست بود، ثبت می‌کنیم
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    // محاسبه تاریخ انقضا: ۱۲۰ روز بعد از امروز
    final expireDate = now.add(const Duration(days: 120));
    
    await prefs.setString('expire_date', expireDate.toIso8601String());
    await prefs.setString('license_code', inputCode);
    await prefs.setString('device_id', _deviceId);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, size: 80, color: AppConstants.primaryColor),
                const SizedBox(height: 20),
                const Text('اعتبار نسخه شما به پایان رسیده است.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('این کد شناسایی گوشی شماست. آن را برای مدیر برنامه ارسال کنید تا لایسنس را دریافت کنید:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                
                // 🚨 نمایش کد دستگاه در یک کادر زیبا
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.primaryColor, width: 2),
                  ),
                  child: SelectableText(
                    _deviceId,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                const Text('کد لایسنس دریافتی را در کادر زیر وارد کنید:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'کد لایسنس',
                    hintText: 'کد لایسنس را وارد نمایید',
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
