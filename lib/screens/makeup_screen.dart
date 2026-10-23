import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class MakeupScreen extends StatefulWidget {
  const MakeupScreen({super.key});

  @override
  State<MakeupScreen> createState() => _MakeupScreenState();
}

class _MakeupScreenState extends State<MakeupScreen> {
  String _selectedDay = AppConstants.days.first;
  String _selectedTime = AppConstants.timeSlots.first;

  Future<void> _exportExcel(AppProvider provider) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['کلاس‌های جبرانی'];
    if (excel.tables.containsKey('Sheet1')) excel.delete('Sheet1');

    sheet.appendRow([
      xl.TextCellValue('نام درس'),
      xl.TextCellValue('استاد'),
      xl.TextCellValue('روز جبرانی'),
      xl.TextCellValue('ساعت جبرانی'),
    ]);

    for (var m in provider.makeupRecords) {
      final records = provider.courseRecords.where((r) => r.uniqueKey == m.recordKey).toList();
      if (records.isEmpty) continue;
      final r = records.first;
      
      sheet.appendRow([
        xl.TextCellValue(r.courseName),
        xl.TextCellValue(r.teacher),
        xl.TextCellValue(m.day),
        xl.TextCellValue(m.timeSlot),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/MakeupClasses.xlsx';
    final file = File(path);
    final bytes = excel.encode();
    
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(path)], text: 'خروجی اکسل کلاس‌های جبرانی');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت کلاس‌های جبرانی'), backgroundColor: AppConstants.primaryColor),
        body: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final records = provider.getByDayAndTime(_selectedDay, _selectedTime);
            
            // پیدا کردن دروسی که جبرانی دارند
            final makeupCourses = provider.courseRecords.where((r) => provider.getMakeupRecordsFor(r).isNotEmpty).toList();

            return Column(
              children: [
                // 🚨 منوی کشویی بالای صفحه
                if (makeupCourses.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: ExpansionTile(
                      title: Text('تعداد دروس جبرانی: ${makeupCourses.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                      leading: const Icon(Icons.info, color: Colors.pink),
                      children: makeupCourses.map((c) => ListTile(
                        dense: true,
                        title: Text(c.courseName),
                        subtitle: Text('استاد: ${c.teacher}'),
                      )).toList(),
                    ),
                  ),

                // فیلترها
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(child: DropdownButtonFormField<String>(value: _selectedDay, items: AppConstants.days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _selectedDay = v!))),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField<String>(value: _selectedTime, items: AppConstants.timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedTime = v!))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // لیست دروس
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: records.length,
                    itemBuilder: (context, i) {
                      final r = records[i];
                      final makeups = provider.getMakeupRecordsFor(r);
                      final hasMakeup = makeups.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: hasMakeup ? Colors.pink.shade50 : null, // 🚨 تغییر رنگ
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(r.courseName, style: TextStyle(fontWeight: FontWeight.bold, color: hasMakeup ? Colors.pink.shade900 : null)),
                              subtitle: Text('${r.teacher} • ${r.classroom}'),
                              trailing: ElevatedButton(
                                onPressed: () => _showAddMakeupDialog(context, provider, r),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                                child: const Text('ثبت جبرانی', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            // 🚨 منوی کشویی زمان‌های جبرانی
                            if (hasMakeup)
                              ExpansionTile(
                                title: const Text('زمان‌های جبرانی ثبت شده', style: TextStyle(fontSize: 13, color: Colors.pink)),
                                children: makeups.map((m) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.access_time, color: Colors.pink),
                                  title: Text('${m.day} - ${m.timeSlot}'),
                                )).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final provider = context.read<AppProvider>();
            _exportExcel(provider);
          },
          backgroundColor: AppConstants.successColor,
          icon: const Icon(Icons.file_download),
          label: const Text('خروجی اکسل'),
        ),
      ),
    );
  }

  // پنجره ثبت جبرانی
  Future<void> _showAddMakeupDialog(BuildContext context, AppProvider provider, r) async {
    String selectedDay = AppConstants.days.first;
    String selectedTime = AppConstants.timeSlots.first;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت زمان جبرانی'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'روز هفته'),
                  items: AppConstants.days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => selectedDay = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: const InputDecoration(labelText: 'ساعت'),
                  items: AppConstants.timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => selectedTime = v!),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () async {
              await provider.addMakeupRecord(r, selectedDay, selectedTime);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ثبت'),
          ),
        ],
      ),
    );
  }
}
