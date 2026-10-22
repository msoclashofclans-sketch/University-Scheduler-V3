import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class TeacherAbsenceScreen extends StatelessWidget {
  const TeacherAbsenceScreen({super.key});

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
      ),
    );
  }
}