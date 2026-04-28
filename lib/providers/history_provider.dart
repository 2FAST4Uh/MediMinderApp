import 'package:flutter/material.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';

class HistoryProvider with ChangeNotifier {
  List<HistoryRecord> _records = [];
  bool _isLoading = false;

  List<HistoryRecord> get records => _records;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    loadHistory();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _records = await DatabaseService().getHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecord(HistoryRecord record) async {
    _records.insert(0, record);
    await DatabaseService().insertHistory(record);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _records.clear();
    await DatabaseService().clearHistory();
    notifyListeners();
  }
}
