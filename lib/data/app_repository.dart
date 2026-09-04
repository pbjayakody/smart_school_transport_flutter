import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_service.dart';

class AppRepository {
  final DatabaseService database;
  AppRepository(this.database);
  Database get db => database.db;

  Future<Map<String, Object?>?> login(String username, String password) async {
    final rows = await db.query('users', where: 'username=? AND is_active=1', whereArgs: [username.trim()]);
    if (rows.isEmpty || !database.verifyPassword(password, '${rows.first['password_hash']}')) return null;
    await db.update('users', {'last_login_at': DateTime.now().toIso8601String()}, where: 'id=?', whereArgs: [rows.first['id']]);
    return rows.first;
  }
  Future<List<Map<String,Object?>>> users() => db.query('users', columns:['id','username','full_name','role','is_active','last_login_at'], orderBy:'full_name');
  Future<int> createUser(String username,String password,String name,String role) => db.insert('users', {'username':username.trim(),'password_hash':database.hashPassword(password),'full_name':name.trim(),'role':role});
  Future<void> setUserActive(int id,bool active)=>db.update('users',{'is_active':active?1:0},where:'id=?',whereArgs:[id]);

  Future<Map<String, Object?>> dashboard() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Future<num> scalar(String q, [List<Object?>? a]) async => (Sqflite.firstIntValue(await db.rawQuery(q, a)) ?? 0);
    final collectionRows = await db.rawQuery('SELECT COALESCE(SUM(amount),0) v FROM payments WHERE payment_date=?', [today]);
    final outstandingRows = await db.rawQuery('SELECT COALESCE(SUM(outstanding_balance),0) v FROM v_student_outstanding');
    final recent = await db.rawQuery('SELECT p.*,s.name,s.student_code FROM payments p JOIN students s ON s.id=p.student_id ORDER BY p.id DESC LIMIT 6');
    return {
      'today': (collectionRows.first['v'] as num?) ?? 0,
      'outstanding': (outstandingRows.first['v'] as num?) ?? 0,
      'students': await scalar('SELECT COUNT(*) FROM students WHERE is_active=1 AND is_deleted=0'),
      'vehicles': await scalar("SELECT COUNT(*) FROM vehicles WHERE status='Active' AND is_deleted=0"),
      'trips': await scalar("SELECT COUNT(*) FROM hiring WHERE trip_date=? AND booking_status!='Cancelled'", [today]),
      'recent': recent,
    };
  }

  Future<List<Map<String, Object?>>> vehicles({String query = ''}) => db.rawQuery('''
    SELECT v.*,(SELECT COUNT(*) FROM students s WHERE s.vehicle_id=v.id AND s.is_active=1 AND s.is_deleted=0) student_count
    FROM vehicles v WHERE v.is_deleted=0 AND (v.vehicle_number LIKE ? OR COALESCE(v.driver_name,'') LIKE ?) ORDER BY v.vehicle_number''', ['%$query%', '%$query%']);

  Future<int> saveVehicle(Map<String, Object?> data, [int? id]) async {
    final number = '${data['vehicle_number']}'.trim().toUpperCase();
    data = {...data, 'vehicle_number': number, 'vehicle_number_key': number.replaceAll(RegExp(r'[^A-Z0-9]'), '')};
    if (id == null) {
      final used = await db.rawQuery("SELECT bus_letter FROM vehicles WHERE bus_letter IS NOT NULL");
      final letters = used.map((e) => '${e['bus_letter']}').toSet();
      data['bus_letter'] ??= List.generate(26, (i) => String.fromCharCode(65 + i)).firstWhere((x) => !letters.contains(x), orElse: () => 'Z');
      return db.insert('vehicles', data);
    }
    await db.update('vehicles', data, where: 'id=?', whereArgs: [id]);
    return id;
  }

  Future<void> deleteVehicle(int id) => db.update('vehicles', {'is_deleted': 1}, where: 'id=?', whereArgs: [id]);
  Future<List<Map<String, Object?>>> vehicleServices(int id) => db.query('vehicle_services', where: 'vehicle_id=?', whereArgs: [id], orderBy: 'service_date DESC');
  Future<List<Map<String, Object?>>> fuelLogs(int id) => db.rawQuery('''SELECT f.*,(f.odometer_reading-LAG(f.odometer_reading) OVER(ORDER BY f.fuel_date,f.id))/NULLIF(f.litres_filled,0) km_per_litre FROM fuel_logs f WHERE vehicle_id=? ORDER BY fuel_date DESC,id DESC''', [id]);
  Future<int> addVehicleService(Map<String,Object?> data) => db.insert('vehicle_services', data);
  Future<int> addFuelLog(Map<String,Object?> data) => db.insert('fuel_logs', data);

  Future<List<Map<String, Object?>>> students({String query = '', int? vehicleId, bool? active}) {
    final where = <String>['s.is_deleted=0'];
    final args = <Object?>[];
    if (query.isNotEmpty) { where.add('(s.name LIKE ? OR s.student_code LIKE ? OR s.barcode_id LIKE ?)'); args.addAll(['%$query%', '%$query%', '%$query%']); }
    if (vehicleId != null) { where.add('s.vehicle_id=?'); args.add(vehicleId); }
    if (active != null) { where.add('s.is_active=?'); args.add(active ? 1 : 0); }
    return db.rawQuery('''SELECT s.*,v.vehicle_number,COALESCE(o.outstanding_balance,0) outstanding FROM students s LEFT JOIN vehicles v ON v.id=s.vehicle_id LEFT JOIN v_student_outstanding o ON o.student_id=s.id WHERE ${where.join(' AND ')} ORDER BY v.vehicle_number,s.display_order,s.name''', args);
  }

  Future<int> saveStudent(Map<String, Object?> data, [int? id]) async {
    if (id != null) {
      final old = (await db.query('students', where: 'id=?', whereArgs: [id])).first;
      final newVehicle = data['vehicle_id'];
      if (newVehicle != null && newVehicle != old['vehicle_id']) {
        final code = await _nextStudentCode(newVehicle as int);
        await db.insert('student_transfers', {'student_id': id, 'from_vehicle_id': old['vehicle_id'], 'to_vehicle_id': newVehicle, 'old_code': old['student_code'], 'new_code': code});
        data['student_code'] = code;
      }
      await db.update('students', data, where: 'id=?', whereArgs: [id]);
      return id;
    }
    final vehicleId = data['vehicle_id'] as int;
    data['student_code'] = await _nextStudentCode(vehicleId);
    data['barcode_id'] = '${DateTime.now().microsecondsSinceEpoch}'.substring(9, 16);
    final max = Sqflite.firstIntValue(await db.rawQuery('SELECT COALESCE(MAX(display_order),0) FROM students WHERE vehicle_id=?', [vehicleId])) ?? 0;
    data['display_order'] = max + 1;
    return db.insert('students', data);
  }

  Future<String> _nextStudentCode(int vehicleId) async {
    return db.transaction((txn) async {
      final v = (await txn.query('vehicles', columns: ['bus_letter'], where: 'id=?', whereArgs: [vehicleId])).first;
      await txn.insert('vehicle_student_sequences', {'vehicle_id': vehicleId, 'last_sequence': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.rawUpdate('UPDATE vehicle_student_sequences SET last_sequence=last_sequence+1 WHERE vehicle_id=?', [vehicleId]);
      final seq = Sqflite.firstIntValue(await txn.rawQuery('SELECT last_sequence FROM vehicle_student_sequences WHERE vehicle_id=?', [vehicleId]))!;
      return '${v['bus_letter']}/${seq.toString().padLeft(4, '0')}';
    });
  }

  Future<void> setStudentActive(int id, bool active) => db.update('students', {'is_active': active ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  Future<void> deleteStudent(int id) => db.update('students', {'is_deleted': 1}, where: 'id=?', whereArgs: [id]);

  Future<List<Map<String, Object?>>> ledger(int studentId) => db.rawQuery('SELECT * FROM v_ledger_status WHERE student_id=? ORDER BY ledger_year,ledger_month', [studentId]);
  Future<void> ensureLedger(int year, int month) async {
    await db.rawInsert('''INSERT OR IGNORE INTO student_monthly_ledger(student_id,ledger_year,ledger_month,fee_amount,due_date)
      SELECT id,?,?,monthly_fee,? FROM students WHERE is_active=1 AND is_deleted=0 AND id NOT IN(SELECT student_id FROM skipped_months WHERE ledger_year=? AND ledger_month=?)''', [year, month, '$year-${month.toString().padLeft(2, '0')}-10', year, month]);
    await setSetting('billing_year', '$year');
    await setSetting('billing_month', '$month');
  }

  Future<int> makePayment({required int studentId, required double amount, required String method, required String date, String notes = '', int? userId}) async {
    return db.transaction((txn) async {
      final sr = await txn.query('settings', columns: ['setting_value'], where: 'setting_key=?', whereArgs: ['receipt_prefix']);
      final prefix = sr.isEmpty ? 'RCT' : '${sr.first['setting_value']}';
      final count = Sqflite.firstIntValue(await txn.rawQuery('SELECT COALESCE(MAX(id),0)+1 FROM payments'))!;
      final receipt = '$prefix-${DateTime.now().year}-${count.toString().padLeft(6, '0')}';
      final paymentId = await txn.insert('payments', {'receipt_number': receipt, 'student_id': studentId, 'payment_date': date, 'amount': amount, 'payment_method': method, 'notes': notes, 'received_by': userId});
      var left = amount;
      final rows = await txn.rawQuery('SELECT * FROM v_ledger_status WHERE student_id=? AND balance_due>0 ORDER BY ledger_year,ledger_month', [studentId]);
      for (final row in rows) {
        if (left <= 0) break;
        final due = (row['balance_due'] as num).toDouble();
        final part = left < due ? left : due;
        await txn.insert('payment_allocations', {'payment_id': paymentId, 'ledger_id': row['ledger_id'], 'allocated_amount': part});
        left -= part;
      }
      await txn.insert('audit_logs', {'user_id': userId, 'action': 'CREATE', 'table_name': 'payments', 'record_id': paymentId, 'details': receipt});
      return paymentId;
    });
  }

  Future<List<Map<String, Object?>>> payments({String query = ''}) => db.rawQuery('''SELECT p.*,s.name,s.student_code,v.vehicle_number FROM payments p JOIN students s ON s.id=p.student_id LEFT JOIN vehicles v ON v.id=s.vehicle_id WHERE s.name LIKE ? OR s.student_code LIKE ? OR p.receipt_number LIKE ? ORDER BY p.payment_date DESC,p.id DESC''', ['%$query%', '%$query%', '%$query%']);
  Future<void> deletePayment(int id) => db.transaction((t) async { await t.delete('payment_allocations', where: 'payment_id=?', whereArgs: [id]); await t.delete('payments', where: 'id=?', whereArgs: [id]); });

  Future<List<Map<String, Object?>>> hiring({String query = ''}) => db.rawQuery('''SELECT h.*,v.vehicle_number,COALESCE(p.total_expenses,0) total_expenses,COALESCE(p.profit,h.trip_charge) profit FROM hiring h JOIN vehicles v ON v.id=h.vehicle_id LEFT JOIN v_hiring_profit p ON p.hiring_id=h.id WHERE h.customer_name LIKE ? OR h.destination LIKE ? OR h.invoice_number LIKE ? ORDER BY h.trip_date DESC''', ['%$query%', '%$query%', '%$query%']);
  Future<int> saveHiring(Map<String, Object?> data, [int? id]) async {
    if (id == null) {
      final conflict = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM hiring WHERE vehicle_id=? AND trip_date=? AND booking_status!='Cancelled'", [data['vehicle_id'], data['trip_date']])) ?? 0;
      if (conflict > 0) throw StateError('This vehicle already has a booking on this date.');
      final prefix = await setting('invoice_prefix') ?? 'INV';
      final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COALESCE(MAX(id),0)+1 FROM hiring'))!;
      data['invoice_number'] = '$prefix-${DateTime.now().year}-${n.toString().padLeft(6, '0')}';
      return db.insert('hiring', data);
    }
    await db.update('hiring', data, where: 'id=?', whereArgs: [id]); return id;
  }

  Future<List<Map<String, Object?>>> expenses(int hiringId) => db.query('hiring_expenses', where: 'hiring_id=?', whereArgs: [hiringId], orderBy: 'id DESC');
  Future<int> addExpense(Map<String, Object?> data) => db.insert('hiring_expenses', data);

  Future<String?> setting(String key) async { final r = await db.query('settings', where: 'setting_key=?', whereArgs: [key]); return r.isEmpty ? null : '${r.first['setting_value']}'; }
  Future<Map<String, String>> settings() async => {for (final r in await db.query('settings')) '${r['setting_key']}': '${r['setting_value'] ?? ''}'};
  Future<void> setSetting(String key, String value) => db.insert('settings', {'setting_key': key, 'setting_value': value, 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> saveSettings(Map<String, String> values) async { for (final e in values.entries) { await setSetting(e.key, e.value); } }
  Future<List<Map<String, Object?>>> audit() => db.rawQuery('SELECT a.*,u.full_name FROM audit_logs a LEFT JOIN users u ON u.id=a.user_id ORDER BY a.id DESC LIMIT 500');
}
