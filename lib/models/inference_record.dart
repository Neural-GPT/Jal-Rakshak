import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class InferenceRecord {
  final int?   id;
  final String label;          // 'filling' | 'filled'
  final double confidence;     // 0.0 – 1.0
  final double rms;
  final DateTime timestamp;
  final String? audioPath;     // Optional saved recording

  const InferenceRecord({
    this.id,
    required this.label,
    required this.confidence,
    required this.rms,
    required this.timestamp,
    this.audioPath,
  });

  Map<String, dynamic> toMap() => {
    'id':         id,
    'label':      label,
    'confidence': confidence,
    'rms':        rms,
    'timestamp':  timestamp.toIso8601String(),
    'audio_path': audioPath,
  };

  factory InferenceRecord.fromMap(Map<String, dynamic> m) => InferenceRecord(
    id:         m['id'] as int?,
    label:      m['label'] as String,
    confidence: m['confidence'] as double,
    rms:        m['rms'] as double,
    timestamp:  DateTime.parse(m['timestamp'] as String),
    audioPath:  m['audio_path'] as String?,
  );

  bool get isFilling => label == 'filling';
}

// ── SQLite helper ────────────────────────────────────────────────────────────
class HistoryDatabase {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'jal_rakshak.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE history (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          label      TEXT    NOT NULL,
          confidence REAL    NOT NULL,
          rms        REAL    NOT NULL,
          timestamp  TEXT    NOT NULL,
          audio_path TEXT
        )
      '''),
    );
  }

  static Future<int> insert(InferenceRecord r) async {
    final d = await db;
    return d.insert('history', r.toMap()..remove('id'));
  }

  static Future<List<InferenceRecord>> fetchAll({int limit = 100}) async {
    final d = await db;
    final rows = await d.query(
      'history',
      orderBy: 'timestamp DESC',
      limit:   limit,
    );
    return rows.map(InferenceRecord.fromMap).toList();
  }

  static Future<List<InferenceRecord>> fetchRecent(int hours) async {
    final d = await db;
    final since = DateTime.now()
        .subtract(Duration(hours: hours))
        .toIso8601String();
    final rows = await d.query(
      'history',
      where:   'timestamp > ?',
      whereArgs: [since],
      orderBy: 'timestamp DESC',
    );
    return rows.map(InferenceRecord.fromMap).toList();
  }

  static Future<void> clear() async {
    final d = await db;
    await d.delete('history');
  }
}
