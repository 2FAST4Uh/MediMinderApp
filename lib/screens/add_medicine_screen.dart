import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../services/notification_service.dart';
import '../services/tts_service.dart';
import '../services/ocr_service.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String _selectedFrequency = "Once daily";
  String _selectedMeal = "Before";
  String _selectedDuration = "Ongoing";
  String _selectedAlert = "Notification";
  int _stock = 15;
  bool _isReminderActive = true;
  
  bool _isScanning = false;
  String _scanStatus = "SCAN PRESCRIPTION";
  
  final NotificationService _notificationService = NotificationService();
  final TTSService _ttsService = TTSService();
  final OCRService _ocrService = OCRService();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanPrescription() async {
    setState(() {
      _isScanning = true;
      _scanStatus = "AI ANALYZING...";
    });
    
    _ttsService.speak("Analyzing prescription. Please wait.");
    
    try {
      final result = await _ocrService.scanPrescription(
        onStatusChange: (status) => setState(() => _scanStatus = status.toUpperCase())
      );
      
      if (result != null) {
        setState(() {
          _nameController.text = result['name'] ?? "";
          _dosageController.text = result['dosage'] ?? "";
          _notesController.text = result['notes'] ?? "";
          if (result['frequency'] != null) _selectedFrequency = result['frequency']!;
          if (result['mealInstruction'] != null) _selectedMeal = result['mealInstruction']!;
          if (result['stock'] != null) _stock = int.tryParse(result['stock']!) ?? 15;
        });
        _ttsService.speak("Found ${result['name']}. Details populated.");
      }
    } catch (e) {
      _ttsService.speak("Scanning failed.");
    } finally {
      setState(() {
        _isScanning = false;
        _scanStatus = "SCAN PRESCRIPTION";
      });
    }
  }

  void _saveMedicine() {
    if (_nameController.text.isEmpty) {
      _ttsService.speak("Please enter a medicine name.");
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final newMedicine = Medicine(
      id: id,
      name: _nameController.text,
      dosage: _dosageController.text.isEmpty ? "${_stock}mg" : _dosageController.text,
      scheduledTime: _selectedTime,
      notificationIds: [notificationId],
      frequency: _selectedFrequency,
      mealInstruction: _selectedMeal,
      stock: _stock,
      notes: _notesController.text,
      duration: _selectedDuration,
      alertType: _selectedAlert,
      isReminderActive: _isReminderActive,
    );

    Provider.of<MedicineProvider>(context, listen: false).addMedicine(newMedicine);

    if (_isReminderActive) {
      _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Time for your medicine!',
        body: 'Take ${newMedicine.name} (${newMedicine.dosage})',
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
    }

    _ttsService.speak("Medicine saved successfully.");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SCAN BUTTON
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanPrescription,
                  icon: _isScanning 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.document_scanner, size: 24),
                  label: Text(_scanStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel("Medicine Name"),
            _buildTextField(_nameController, "e.g., Aspirin"),

            _buildLabel("Dosage"),
            Row(
              children: [
                Expanded(child: _buildTextField(_dosageController, "e.g., 500mg")),
                const SizedBox(width: 12),
                _roundBtn(Icons.remove, () => setState(() => _stock = (_stock - 1).clamp(1, 1000))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("${_stock}mg", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                _roundBtn(Icons.add, () => setState(() => _stock = (_stock + 1).clamp(1, 1000))),
              ],
            ),

            _buildLabel("Time"),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                if (picked != null) setState(() => _selectedTime = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(_selectedTime), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Icon(Icons.access_time, color: Colors.white54, size: 20),
                  ],
                ),
              ),
            ),

            _buildLabel("Frequency"),
            Wrap(
              spacing: 8,
              children: ["Once daily", "Twice daily", "3x daily", "4x daily"].map((f) => _choiceChip(f, _selectedFrequency == f, (val) => setState(() => _selectedFrequency = f))).toList(),
            ),

            _buildLabel("With meal"),
            Wrap(
              spacing: 8,
              children: ["Before", "With food", "After"].map((m) => _choiceChip(m, _selectedMeal == m, (val) => setState(() => _selectedMeal = m))).toList(),
            ),

            _buildLabel("Duration"),
            Wrap(
              spacing: 8,
              children: ["Ongoing", "7 days", "14 days", "30 days"].map((d) => _choiceChip(d, _selectedDuration == d, (val) => setState(() => _selectedDuration = d))).toList(),
            ),

            _buildLabel("Starting stock"),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _stock / 100,
                    backgroundColor: const Color(0xFF2C2C2C),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4C66EE)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 16),
                _roundBtn(Icons.remove, () => setState(() => _stock = (_stock - 1).clamp(0, 100))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("$_stock tabs", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                _roundBtn(Icons.add, () => setState(() => _stock = (_stock + 1).clamp(0, 100))),
              ],
            ),

            _buildLabel("Alert type"),
            Wrap(
              spacing: 8,
              children: [
                _choiceChip("Notification", _selectedAlert == "Notification", (val) => setState(() => _selectedAlert = "Notification"), icon: Icons.notifications_none),
                _choiceChip("SMS", _selectedAlert == "SMS", (val) => setState(() => _selectedAlert = "SMS"), icon: Icons.phone_outlined),
                _choiceChip("Both", _selectedAlert == "Both", (val) => setState(() => _selectedAlert = "Both")),
              ],
            ),

            _buildLabel("Notes"),
            _buildTextField(_notesController, "e.g., Take with water. Avoid alcohol.", maxLines: 3),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Reminder active", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Enable alarm for this medicine", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: _isReminderActive,
                    onChanged: (val) => setState(() => _isReminderActive = val),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF4C66EE),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("SAVE MEDICINE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _choiceChip(String label, bool isSelected, Function(bool) onSelected, {IconData? icon}) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white54), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 14)),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF1E1E1E),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? const Color(0xFF4C66EE) : Colors.white24, width: 1.5),
      ),
      showCheckmark: false,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final amPm = time.period == DayPeriod.am ? "AM" : "PM";
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm";
  }
}
