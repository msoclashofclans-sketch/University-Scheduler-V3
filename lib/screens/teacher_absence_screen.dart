import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class TeacherAbsenceScreen extends StatelessWidget {
  const TeacherAbsenceScreen({super.key});

  // 🚨 تابع ساخت خروجی اکسل
  Future<void> _exportExcel(BuildContext context, AppProvider provider) async {
    final teachers = provider.getAllTeachers();
    final absentTeachers = teachers.where((t) {
      final records = provider.getByTeacher(t);
      return records.any((r) => provider.getAttendance(r)?.status == AppConstants.statusAbsent);
    }).toList();

    if (absentTeachers.isEmpty) return;

    final excel = xl.Excel.createExcel();
    final sheet = excel['غیبت‌های اساتید'];
    
    if (excel.tables.containsKey('Sheet1')) excel.delete('Sheet1');

    sheet.appendRow([
      xl.TextCellValue('نام استاد'),
      xl.TextCellValue('نام درس'),
      xl.TextCellValue('روز'),
      xl.TextCellValue('ساعت'),
      xl.TextCellValue('کلاس'),
      xl.TextCellValue('زمان ثبت غیبت'),
    ]);

    for (final t in absentTeachers) {
      final records = provider.getByTeacher(t);
      final absentRecords = records.where((r) => provider.getAttendance(r)?.status == AppConstants.statusAbsent).toList();
      
      for (var r in absentRecords) {
        final att = provider.getAttendance(r);
        sheet.appendRow([
          xl.TextCellValue(t),
          xl.TextCellValue(r.courseName),
          xl.TextCellValue(r.day),
          xl.TextCellValue(r.timeSlot),
          xl.TextCellValue(r.classroom),
          xl.TextCellValue(att?.registeredAt ?? ''),
        ]);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/TeacherAbsences.xlsx';
    final file = File(path);
    final bytes = excel.encode();
    
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(path)], text: 'خروجی اکسل غیبت‌های اساتید');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('غیبت‌های اساتید'), backgroundColor: AppConstants.primaryColor),
        body: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final teachers = provider.getAllTeachers();
            if (teachers.isEmpty) return const Center(child: Text('داده‌ای وجود ندارد'));

            final absentTeachers = teachers.where((t) {
              final records = provider.getByTeacher(t);
              return records.any((r) => provider.getAttendance(r)?.status == AppConstants.statusAbsent);
            }).toList();

            if (absentTeachers.isEmpty) {
              return const Center(child: Text('هیچ استادی غیبت ثبت‌شده ندارد.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: absentTeachers.length,
              itemBuilder: (context, i) {
                final t = absentTeachers[i];
                final records = provider.getByTeacher(t);
                final absentRecords = records.where((r) => provider.getAttendance(r)?.status == AppConstants.statusAbsent).toList();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: CircleAvatar(backgroundColor: AppConstants.dangerColor, child: Text(t[0], style: const TextStyle(color: Colors.white))),
                    title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('تعداد غیبت: ${absentRecords.length} جلسه', style: const TextStyle(color: Colors.red)),
                    children: absentRecords.map((r) {
                      final att = provider.getAttendance(r);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.event_busy, color: AppConstants.dangerColor),
                        title: Text(r.courseName),
                        subtitle: Text('${r.day} - ${r.timeSlot} | کلاس: ${r.classroom}\nزمان ثبت: ${att?.registeredAt ?? ''}'),
                        isThreeLine: true,
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
