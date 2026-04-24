import 'package:flutter/material.dart';
import '../models/medicine.dart';
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
      _medicines[index].isTaken = !_medicines[index].isTaken;
      await DatabaseService().updateMedicine(_medicines[index]);
      notifyListeners();
    }
  }

  List<Medicine> get todayMedicines {
    return _medicines;
  }
}
