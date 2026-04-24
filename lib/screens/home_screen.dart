import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../models/medicine.dart';
import 'add_medicine_screen.dart';
import 'settings_screen.dart';
import '../services/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeContent(),
    Center(child: Text("History", style: TextStyle(fontSize: 24, color: Colors.white))),
    Center(child: Text("Family Connect", style: TextStyle(fontSize: 24, color: Colors.white))),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF121212),
        indicatorColor: const Color(0xFF4C66EE).withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home, color: Colors.white), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history, color: Colors.white), label: 'History'),
          NavigationDestination(icon: Icon(Icons.people, color: Colors.white), label: 'Family'),
          NavigationDestination(icon: Icon(Icons.settings, color: Colors.white), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicineProvider>(context);
    final medicines = provider.todayMedicines;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MediMinder', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medicines.length,
              itemBuilder: (context, index) => MedicineCardUI(medicine: medicines[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicineScreen())),
        backgroundColor: const Color(0xFFE65100),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class MedicineCardUI extends StatefulWidget {
  final Medicine medicine;
  const MedicineCardUI({super.key, required this.medicine});

  @override
  State<MedicineCardUI> createState() => _MedicineCardUIState();
}

class _MedicineCardUIState extends State<MedicineCardUI> {
  late TextEditingController _notesController;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.medicine.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MedicineProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.medical_services, color: Color(0xFF1A1C1E), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.medicine.name.toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    Text(widget.medicine.formattedTime, 
                      style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 16)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: widget.medicine.isTaken ? const Color(0xFF4C66EE) : Colors.transparent,
                  border: Border.all(color: const Color(0xFF4C66EE), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.check, color: widget.medicine.isTaken ? Colors.white : const Color(0xFF4C66EE)),
                  onPressed: () => provider.toggleTaken(widget.medicine.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF444444)),
          
          _buildRow("Dosage:", Row(
            children: [
              _roundBtn(Icons.remove, () => _updateDosage(context, widget.medicine, -1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(widget.medicine.dosage, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _roundBtn(Icons.add, () => _updateDosage(context, widget.medicine, 1)),
            ],
          )),
          
          _buildRow("Frequency:", Row(
            children: [widget.medicine.frequency].map((f) => _choiceChip(f, true)).toList(),
          )),
          
          _buildRow("With meal:", Row(
            children: [widget.medicine.mealInstruction].map((m) => _choiceChip(m, true)).toList(),
          )),
          
          _buildRow("Stock left:", Row(
            children: [
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: widget.medicine.stock / 30,
                  backgroundColor: const Color(0xFF444444),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4C66EE)),
                ),
              ),
              const SizedBox(width: 12),
              Text("${widget.medicine.stock} tabs", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Text("refill", style: TextStyle(color: Color(0xFFAAAAAA), decoration: TextDecoration.underline)),
            ],
          )),
          
          // NOTES with Edit Functionality
          _buildRow("Notes:", Expanded(
            child: _isEditingNotes 
              ? TextField(
                  controller: _notesController,
                  autofocus: true,
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onSubmitted: (val) {
                    setState(() => _isEditingNotes = false);
                    widget.medicine.notes = val;
                    provider.updateMedicineInDb(widget.medicine);
                  },
                )
              : GestureDetector(
                  onTap: () => setState(() => _isEditingNotes = true),
                  child: Text(widget.medicine.notes, 
                    textAlign: TextAlign.right, 
                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14)
                  ),
                ),
          )),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFDDE3F9), borderRadius: BorderRadius.circular(20)),
                child: const Text("Upcoming", style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  _actionBtn("Snooze 10m", Colors.transparent, const Color(0xFFAAAAAA)),
                  const SizedBox(width: 8),
                  _actionBtn("Take now", const Color(0xFF4C66EE), Colors.white),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          child,
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _choiceChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4C66EE) : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFAAAAAA), fontSize: 12)),
    );
  }

  Widget _actionBtn(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: bg == Colors.transparent ? Border.all(color: const Color(0xFF444444)) : null,
      ),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
    );
  }

  void _updateDosage(BuildContext context, Medicine med, int change) {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(med.dosage);
    if (match != null) {
      int value = int.parse(match.group(0)!);
      value = (value + change).clamp(1, 999);
      final newDosage = med.dosage.replaceFirst(match.group(0)!, value.toString());
      
      final updatedMed = Medicine(
        id: med.id,
        name: med.name,
        dosage: newDosage,
        scheduledTime: med.scheduledTime,
        notificationIds: med.notificationIds,
        isTaken: med.isTaken,
        frequency: med.frequency,
        mealInstruction: med.mealInstruction,
        stock: med.stock,
        notes: med.notes,
        duration: med.duration,
        alertType: med.alertType,
        isReminderActive: med.isReminderActive,
      );
      provider.updateMedicineInDb(updatedMed);
    }
  }
}
