import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/classroom.dart';
import '../models/course_record.dart';
import '../models/attendance_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'university_scheduler_v4.db');
    return await openDatabase(path, version: 4, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE classrooms (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, capacity INTEGER NOT NULL)''');
    await db.execute('''CREATE TABLE course_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT, day TEXT NOT NULL, time_slot TEXT NOT NULL,
        classroom TEXT NOT NULL, week_type TEXT DEFAULT 'عادی', course_name TEXT NOT NULL,
        teacher TEXT, student_count TEXT, group_name TEXT, course_code TEXT, field TEXT,
        semester TEXT, source_row INTEGER, units_theoretical INTEGER DEFAULT 0,
        units_practical INTEGER DEFAULT 0, units_workshop INTEGER DEFAULT 0
    )''');
    await db.execute('''CREATE TABLE attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT, record_key TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL, registered_at TEXT, delay_minutes TEXT, day TEXT, time_slot TEXT,
        course_name TEXT, teacher TEXT, classroom TEXT, group_name TEXT
    )''');
  }

  Future<void> clearClassrooms() async => (await database).delete('classrooms');
  Future<void> insertClassrooms(List<Classroom> classrooms) async {
    final db = await database; final batch = db.batch();
    for (final c in classrooms) batch.insert('classrooms', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await batch.commit(noResult: true);
  }
  Future<List<Classroom>> getAllClassrooms() async => (await (await database).query('classrooms')).map((e) => Classroom.fromMap(e)).toList();

  Future<void> clearCourseRecords() async => (await database).delete('course_records');
  Future<void> insertCourseRecords(List<CourseRecord> records) async {
    final db = await database; final batch = db.batch();
    for (final r in records) batch.insert('course_records', r.toMap());
    await batch.commit(noResult: true);
  }
  Future<List<CourseRecord>> getAllCourseRecords() async => (await (await database).query('course_records')).map((e) => CourseRecord.fromMap(e)).toList();

  Future<void> upsertAttendance(AttendanceRecord record) async => (await database).insert('attendance_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<List<AttendanceRecord>> getAllAttendance() async => (await (await database).query('attendance_records')).map((e) => AttendanceRecord.fromMap(e)).toList();

  Future<void> deleteAllData() async {
    final db = await database; await db.delete('classrooms'); await db.delete('course_records'); await db.delete('attendance_records');
  }
}