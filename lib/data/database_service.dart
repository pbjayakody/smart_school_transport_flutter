import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();
  late Database db;
  late String dbPath;

  Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    dbPath = p.join(dir.path, 'nethsara_flutter.db');
    db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: (d, _) async => _createSchema(d),
      ),
    );
    await db.execute('CREATE TABLE IF NOT EXISTS skipped_months(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,ledger_year INTEGER NOT NULL,ledger_month INTEGER NOT NULL,reason TEXT,UNIQUE(student_id,ledger_year,ledger_month))');
    await _seed();
  }

  Future<void> _createSchema(Database d) async {
    for (final sql in _schema.split(';')) {
      if (sql.trim().isNotEmpty) await d.execute(sql);
    }
  }

  String hashPassword(String value) => sha256.convert(value.codeUnits).toString();

  bool verifyPassword(String plain, String stored) {
    if (!stored.contains(r'$')) return hashPassword(plain) == stored;
    final parts = stored.split(r'$');
    if (parts.length != 2) return false;
    try {
      final salt = _hex(parts[0]);
      final expected = _hex(parts[1]);
      final hmac = Hmac(sha256, plain.codeUnits);
      var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
      final derived = Uint8List.fromList(u);
      for (var round = 1; round < 260000; round++) {
        u = hmac.convert(u).bytes;
        for (var i = 0; i < derived.length; i++) derived[i] ^= u[i];
      }
      if (derived.length != expected.length) return false;
      var diff = 0;
      for (var i = 0; i < derived.length; i++) diff |= derived[i] ^ expected[i];
      return diff == 0;
    } catch (_) { return false; }
  }

  Uint8List _hex(String value) => Uint8List.fromList(List.generate(value.length ~/ 2, (i) => int.parse(value.substring(i * 2, i * 2 + 2), radix: 16)));

  Future<void> _seed() async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    if (count == 0) {
      await db.insert('users', {
        'username': 'admin',
        'password_hash': hashPassword('admin123'),
        'full_name': 'Administrator',
        'role': 'Administrator',
      });
    }
    final defaults = {
      'company_name': 'Nethsara Transport & Hiring Service',
      'company_phone': '',
      'company_whatsapp': '',
      'company_address': '',
      'receipt_prefix': 'RCT',
      'invoice_prefix': 'INV',
      'billing_year': DateTime.now().year.toString(),
      'billing_month': DateTime.now().month.toString(),
      'appearance_mode': 'Light',
    };
    for (final e in defaults.entries) {
      await db.insert('settings', {'setting_key': e.key, 'setting_value': e.value}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<String> backup() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'Nethsara Backups'));
    await folder.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final target = p.join(folder.path, 'nethsara_$stamp.db');
    await db.close();
    await File(dbPath).copy(target);
    await init();
    return target;
  }

  Future<void> restore(String source) async {
    await backup();
    await db.close();
    await File(source).copy(dbPath);
    await init();
  }

  Future<String> extractBundledLegacy() async {
    final bytes = await rootBundle.load('assets/database/nethsara_legacy.db');
    final dir = await getTemporaryDirectory();
    final out = File(p.join(dir.path, 'nethsara_legacy.db'));
    await out.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return out.path;
  }
}

const _schema = r'''
CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT,username TEXT NOT NULL UNIQUE,password_hash TEXT NOT NULL,full_name TEXT NOT NULL,role TEXT NOT NULL DEFAULT 'Cashier',is_active INTEGER NOT NULL DEFAULT 1,last_login_at TEXT,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE vehicles(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_number TEXT NOT NULL UNIQUE,vehicle_number_key TEXT NOT NULL UNIQUE,bus_letter TEXT UNIQUE,vehicle_type TEXT NOT NULL DEFAULT 'Bus',usage_type TEXT NOT NULL DEFAULT 'School',driver_name TEXT,driver_phone TEXT,chassis_number TEXT,seating_capacity INTEGER,insurance_expiry TEXT,licence_expiry TEXT,revenue_licence_expiry TEXT,emission_test_expiry TEXT,status TEXT NOT NULL DEFAULT 'Active',purchase_date TEXT,notes TEXT,is_deleted INTEGER NOT NULL DEFAULT 0,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE vehicle_student_sequences(vehicle_id INTEGER PRIMARY KEY REFERENCES vehicles(id) ON DELETE CASCADE,last_sequence INTEGER NOT NULL DEFAULT 0);
CREATE TABLE vehicle_documents(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,document_type TEXT NOT NULL,file_path TEXT NOT NULL,expiry_date TEXT,uploaded_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE vehicle_services(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,service_date TEXT NOT NULL,odometer_reading INTEGER NOT NULL,service_type TEXT NOT NULL,cost REAL NOT NULL DEFAULT 0,notes TEXT,next_service_mileage INTEGER,next_service_date TEXT,created_by INTEGER,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE fuel_logs(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,fuel_date TEXT NOT NULL,odometer_reading INTEGER NOT NULL,litres_filled REAL NOT NULL,fuel_cost REAL NOT NULL,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE students(id INTEGER PRIMARY KEY AUTOINCREMENT,student_code TEXT NOT NULL UNIQUE,display_order INTEGER NOT NULL DEFAULT 0,name TEXT NOT NULL,pickup_location TEXT,vehicle_id INTEGER REFERENCES vehicles(id),school TEXT,birth_year INTEGER,grade TEXT,monthly_fee REAL NOT NULL DEFAULT 0,whatsapp_number TEXT,phone_1 TEXT,phone_2 TEXT,previous_outstanding_balance REAL NOT NULL DEFAULT 0,barcode_id TEXT UNIQUE,photo_path TEXT,registration_date TEXT NOT NULL DEFAULT CURRENT_DATE,is_active INTEGER NOT NULL DEFAULT 1,is_deleted INTEGER NOT NULL DEFAULT 0,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE student_transfers(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,from_vehicle_id INTEGER,to_vehicle_id INTEGER NOT NULL,old_code TEXT NOT NULL,new_code TEXT NOT NULL,transferred_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE student_monthly_ledger(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,ledger_year INTEGER NOT NULL,ledger_month INTEGER NOT NULL,fee_amount REAL NOT NULL,due_date TEXT,notes TEXT,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE(student_id,ledger_year,ledger_month));
CREATE TABLE skipped_months(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,ledger_year INTEGER NOT NULL,ledger_month INTEGER NOT NULL,reason TEXT,UNIQUE(student_id,ledger_year,ledger_month));
CREATE TABLE additional_charges(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,label TEXT NOT NULL,amount REAL NOT NULL DEFAULT 0,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT,receipt_number TEXT NOT NULL UNIQUE,student_id INTEGER NOT NULL REFERENCES students(id),payment_date TEXT NOT NULL DEFAULT CURRENT_DATE,amount REAL NOT NULL,payment_method TEXT NOT NULL DEFAULT 'Cash',notes TEXT,receipt_pdf_path TEXT,received_by INTEGER,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE payment_allocations(id INTEGER PRIMARY KEY AUTOINCREMENT,payment_id INTEGER NOT NULL REFERENCES payments(id) ON DELETE CASCADE,ledger_id INTEGER NOT NULL REFERENCES student_monthly_ledger(id) ON DELETE CASCADE,allocated_amount REAL NOT NULL);
CREATE TABLE hiring(id INTEGER PRIMARY KEY AUTOINCREMENT,invoice_number TEXT NOT NULL UNIQUE,customer_name TEXT NOT NULL,customer_mobile TEXT NOT NULL,customer_whatsapp TEXT,customer_address TEXT,vehicle_id INTEGER NOT NULL REFERENCES vehicles(id),driver_name TEXT,trip_date TEXT NOT NULL,pickup_location TEXT,destination TEXT,trip_charge REAL NOT NULL DEFAULT 0,advance_payment REAL NOT NULL DEFAULT 0,payment_status TEXT NOT NULL DEFAULT 'Pending',booking_status TEXT NOT NULL DEFAULT 'Upcoming',notes TEXT,created_by INTEGER,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE hiring_expenses(id INTEGER PRIMARY KEY AUTOINCREMENT,hiring_id INTEGER NOT NULL REFERENCES hiring(id) ON DELETE CASCADE,expense_type TEXT NOT NULL,amount REAL NOT NULL,notes TEXT,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE notifications(id INTEGER PRIMARY KEY AUTOINCREMENT,notif_type TEXT NOT NULL,reference_table TEXT NOT NULL,reference_id INTEGER NOT NULL,message TEXT NOT NULL,due_date TEXT,is_read INTEGER NOT NULL DEFAULT 0,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE settings(setting_key TEXT PRIMARY KEY,setting_value TEXT,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE audit_logs(id INTEGER PRIMARY KEY AUTOINCREMENT,user_id INTEGER,action TEXT NOT NULL,table_name TEXT NOT NULL,record_id INTEGER,details TEXT,action_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE route_history(id INTEGER PRIMARY KEY AUTOINCREMENT,start_location TEXT NOT NULL,end_location TEXT NOT NULL,distance_km REAL,duration_minutes REAL,provider TEXT,calculated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE VIEW v_ledger_status AS SELECT l.id ledger_id,l.student_id,l.ledger_year,l.ledger_month,l.fee_amount,COALESCE(SUM(pa.allocated_amount),0) paid_amount,l.fee_amount-COALESCE(SUM(pa.allocated_amount),0) balance_due,CASE WHEN COALESCE(SUM(pa.allocated_amount),0)>=l.fee_amount THEN 'Paid' WHEN COALESCE(SUM(pa.allocated_amount),0)>0 THEN 'Partial' ELSE 'Pending' END status FROM student_monthly_ledger l LEFT JOIN payment_allocations pa ON pa.ledger_id=l.id GROUP BY l.id;
CREATE VIEW v_student_outstanding AS SELECT s.id student_id,s.previous_outstanding_balance+COALESCE(SUM(v.balance_due),0)+COALESCE((SELECT SUM(amount) FROM additional_charges c WHERE c.student_id=s.id),0) outstanding_balance FROM students s LEFT JOIN v_ledger_status v ON v.student_id=s.id GROUP BY s.id;
CREATE VIEW v_hiring_profit AS SELECT h.id hiring_id,h.trip_charge,COALESCE(SUM(e.amount),0) total_expenses,h.trip_charge-COALESCE(SUM(e.amount),0) profit,h.trip_charge-h.advance_payment balance_due FROM hiring h LEFT JOIN hiring_expenses e ON e.hiring_id=h.id GROUP BY h.id;
''';
