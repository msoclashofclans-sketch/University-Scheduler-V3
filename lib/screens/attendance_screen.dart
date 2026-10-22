import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedDay = AppConstants.days.first;
  String _selectedTime = AppConstants.timeSlots.first;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حضور و غیاب اساتید')),
        body: Consumer<AppProvider>(
          builder: (context, provider, _) {
            if (!provider.hasData) return const EmptyState(icon: Icons.fact_check_outlined, title: 'هنوز اطلاعاتی وارد نشده', subtitle: 'ابتدا فایل‌ها را وارد کنید');
            final records = provider.getByDayAndTime(_selectedDay, _selectedTime);

            return Column(
              children: [
                _buildFilters(),
                _buildStats(records, provider),
                Expanded(
                  child: records.isEmpty
                      ? const EmptyState(icon: Icons.event_busy_rounded, title: 'برای این سانس کلاسی وجود ندارد')
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: records.length,
                          itemBuilder: (context, i) {
                            final r = records[i];
                            final att = provider.getAttendance(r);
                            return _buildCard(r, att, provider, i);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(child: DropdownButtonFormField<String>(value: _selectedDay, items: AppConstants.days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _selectedDay = v!))),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(value: _selectedTime, items: AppConstants.timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedTime = v!))),
        ],
      ),
    );
  }

  Widget _buildStats(records, AppProvider provider) {
    int present = 0, absent = 0, delay = 0, early = 0;
    for (final r in records) {
      final att = provider.getAttendance(r);
      if (att == null) continue;
      if (att.status == AppConstants.statusPresent) present++;
      else if (att.status == AppConstants.statusAbsent) absent++;
      else if (att.status == 'تاخیر') delay++;
      else if (att.status == 'تعجیل') early++;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Theme.of(context).cardColor,
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          _statChip('حاضر', present, AppConstants.successColor),
          _statChip('غایب', absent, AppConstants.dangerColor),
          _statChip('تاخیر', delay, AppConstants.warningColor),
          _statChip('تعجیل', early, Colors.purple),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Text('$label: $count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildCard(r, att, AppProvider provider, int index) {
    Color bgColor = AppConstants.pendingColor;
    Color textColor = AppConstants.pendingTextColor;
    String status = 'ثبت نشده';

    if (att != null) {
      status = att.status;
      if (status == AppConstants.statusPresent) { bgColor = AppConstants.presentColor; textColor = AppConstants.presentTextColor; }
      else if (status == AppConstants.statusAbsent) { bgColor = AppConstants.absentColor; textColor = AppConstants.absentTextColor; }
      else if (status == 'تاخیر') { bgColor = Colors.yellow.shade200; textColor = Colors.orange.shade900; }
      else if (status == 'تعجیل') { bgColor = Colors.purple.shade100; textColor = Colors.purple.shade900; }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.courseName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                const SizedBox(height: 4),
                Text('${r.teacher} • ${r.classroom}', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.8))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  status == 'تاخیر' || status == 'تعجیل' ? '$status (${att?.delayMinutes} دقیقه)' : status,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _actionButton('حاضر', AppConstants.successColor, () => provider.setAttendance(record: r, status: AppConstants.statusPresent)),
              _actionButton('غایب', AppConstants.dangerColor, () => provider.setAttendance(record: r, status: AppConstants.statusAbsent)),
              _actionButton('تاخیر', Colors.amber.shade700, () => _askMinutes(context, provider, r, 'تاخیر')),
              _actionButton('تعجیل', Colors.purple, () => _askMinutes(context, provider, r, 'تعجیل')),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _askMinutes(BuildContext context, AppProvider provider, r, String type) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ثبت $type'),
        content: TextField(
          controller: controller, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'تعداد دقیقه', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('ثبت')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await provider.setAttendance(record: r, status: type, delayMinutes: result);
    }
  }
}