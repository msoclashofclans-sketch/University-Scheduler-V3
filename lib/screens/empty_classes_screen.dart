import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class EmptyClassesScreen extends StatelessWidget {
  const EmptyClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('کلاس‌های خالی'), backgroundColor: AppConstants.primaryColor),
        body: Consumer<AppProvider>(
          builder: (context, provider, _) {
            if (!provider.hasData) return const Center(child: Text('ابتدا اطلاعات را وارد کنید'));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: AppConstants.days.length,
              itemBuilder: (context, dayIndex) {
                final day = AppConstants.days[dayIndex];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primaryColor)),
                    leading: const Icon(Icons.calendar_today, color: AppConstants.primaryColor),
                    children: AppConstants.timeSlots.map((timeSlot) {
                      final busyClasses = provider.courseRecords.where((r) => r.day == day && r.timeSlot == timeSlot).map((r) => r.classroom).toSet();
                      final emptyClasses = provider.classrooms.where((c) => !busyClasses.contains(c.name)).map((c) => c.name).toList();

                      if (emptyClasses.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('سانس: $timeSlot', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: emptyClasses.map((name) => Chip(label: Text(name), backgroundColor: Colors.green.shade100, labelStyle: TextStyle(color: Colors.green.shade900))).toList(),
                            ),
                            const Divider(),
                          ],
                        ),
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