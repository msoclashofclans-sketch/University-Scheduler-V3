class MakeupRecord {
  final int? id;
  final String recordKey;
  final String day;
  final String timeSlot;

  MakeupRecord({
    this.id, required this.recordKey, required this.day, required this.timeSlot,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'record_key': recordKey, 'day': day, 'time_slot': timeSlot,
      };

  factory MakeupRecord.fromMap(Map<String, dynamic> map) => MakeupRecord(
        id: map['id'] as int?,
        recordKey: (map['record_key'] as String?) ?? '',
        day: (map['day'] as String?) ?? '',
        timeSlot: (map['time_slot'] as String?) ?? '',
      );
}
