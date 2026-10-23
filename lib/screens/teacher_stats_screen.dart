import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class TeacherStatsScreen extends StatelessWidget {
  const TeacherStatsScreen({super.key});

  // 🚨 تابع ساخت خروجی اکسل
  Future<void> _exportExcel(BuildContext context, AppProvider provider) async {
    final teachers = provider.getAllTeachers();
    if (teachers.isEmpty) return;

    final excel = xl.Excel.createExcel();
    final sheet = excel['آمار اساتید'];
    
    if (excel.tables.containsKey('Sheet1')) excel.delete('Sheet1');

    // هدر جدول
    sheet.appendRow([
      xl.TextCellValue('نام استاد'),
      xl.TextCellValue('تعداد کل واحدها'),
      xl.TextCellValue('واحد تئوری'),
      xl.TextCellValue('واحد عملی'),
      xl.TextCellValue('واحد کارگاهی'),
      xl.TextCellValue('لیست دروس (تئوری/عملی/کارگاهی)'),
    ]);

    for (final t in teachers) {
      final records = provider.getByTeacher(t);
      int totalT = 0, totalP = 0, totalW = 0;
      List<String> coursesList = [];

      for (var r in records) {
        totalT += r.unitsTheoretical;
        totalP += r.unitsPractical;
        totalW += r.unitsWorkshop;
        coursesList.add('${r.courseName} (${r.unitsTheoretical}/${r.unitsPractical}/${r.unitsWorkshop})');
      }

      final totalAll = totalT + totalP + totalW;

      sheet.appendRow([
        xl.TextCellValue(t),
        xl.IntCellValue(totalAll),
        xl.IntCellValue(totalT),
        xl.IntCellValue(totalP),
        xl.IntCellValue(totalW),
        xl.TextCellValue(coursesList.join(' | ')),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/TeacherStats.xlsx';
    final file = File(path);
    final bytes = excel.encode();
    
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      // نمایش پنجره اشتراک‌گذاری
      await Share.shareXFiles([XFile(path)], text: 'خروجی اکسل آمار اساتید');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('آمار اساتید'), backgroundColor: AppConstants.primaryColor),
        body: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final teachers = provider.getAllTeachers();
            if (teachers.isEmpty) return const Center(child: Text('داده‌ای وجود ندارد'));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: teachers.length,
              itemBuilder: (context, i) {
                final t = teachers[i];
                final records = provider.getByTeacher(t);
                
                int totalT = 0, totalP = 0, totalW = 0;
                for (var r in records) {
                  totalT += r.unitsTheoretical;
                  totalP += r.unitsPractical;
                  totalW += r.unitsWorkshop;
                }
                final totalAll = totalT + totalP + totalW;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: CircleAvatar(backgroundColor: AppConstants.primaryColor, child: Text(t[0], style: const TextStyle(color: Colors.white))),
                    title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('کل واحدها: $totalAll\n(تئوری: $totalT | عملی: $totalP | کارگاهی: $totalW)', style: const TextStyle(fontSize: 12)),
                    children: records.map((r) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.book, color: AppConstants.accentColor),
                        title: Text(r.courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('تئوری: ${r.unitsTheoretical} | عملی: ${r.unitsPractical} | کارگاهی: ${r.unitsWorkshop}'),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        ),
        // 🚨 دکمه شناور برای خروجی اکسل
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final provider = context.read<AppProvider>();
            _exportExcel(context, provider);
          },
          backgroundColor: AppConstants.successColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.file_download),
          label: const Text('خروجی اکسل'),
        ),
      ),
    );
  }
}
