import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';

class MedicineProvider with ChangeNotifier {
  List<Medicine> _medicines = [];
  bool _isLoading = true;

  List<Medicine> get medicines => [..._medicines];
  bool get isLoading => _isLoading;

  MedicineProvider() {
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();
    _medicines = await DatabaseService().getMedicines();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    _medicines.add(medicine);
    await DatabaseService().insertMedicine(medicine);
    notifyListeners();
  }

  Future<void> removeMedicine(String id) async {
    _medicines.removeWhere((med) => med.id == id);
    await DatabaseService().deleteMedicine(id);
    notifyListeners();
  }

  Future<void> updateMedicineInDb(Medicine medicine) async {
    final index = _medicines.indexWhere((med) => med.id == medicine.id);
    if (index != -1) {
      _medicines[index] = medicine;
      await DatabaseService().updateMedicine(medicine);
      notifyListeners();
    }
  }

  Future<void> toggleTaken(String id) async {
    final index = _medicines.indexWhere((med) => med.id == id);
    if (index != -1) {
      final medicine = _medicines[index];
      medicine.isTaken = !medicine.isTaken;
      
      // If marked as taken, record in history
      if (medicine.isTaken) {
        final record = HistoryRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          medicineName: medicine.name,
          dosage: medicine.dosage,
          takenDateTime: DateTime.now(),
        );
        await DatabaseService().insertHistory(record);
      }
      
      await DatabaseService().updateMedicine(medicine);
      notifyListeners();
    }
  }

  List<Medicine> get todayMedicines {
    return _medicines;
  }
}
