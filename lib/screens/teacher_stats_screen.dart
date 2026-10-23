import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class TeacherStatsScreen extends StatelessWidget {
  const TeacherStatsScreen({super.key});

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
      ),
    );
  }
}
