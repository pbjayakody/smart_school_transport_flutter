import 'package:flutter/material.dart';
import 'data/app_repository.dart';
import 'data/database_service.dart';

class AppState extends ChangeNotifier {
  final db = DatabaseService.instance;
  late final AppRepository repo = AppRepository(db);
  Map<String, Object?>? user;
  bool darkMode = false;
  bool busy = false;

  Future<void> initialize() async {
    await db.init();
    darkMode = (await repo.setting('appearance_mode')) == 'Dark';
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    user = await repo.login(username, password);
    notifyListeners();
    return user != null;
  }

  void logout() { user = null; notifyListeners(); }
  bool get canDelete => user?['role'] != 'Cashier';
  bool get isAdmin => user?['role'] == 'Administrator';
  void setDark(bool value) { darkMode = value; repo.setSetting('appearance_mode', value ? 'Dark' : 'Light'); notifyListeners(); }
}
