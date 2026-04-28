import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<HistoryProvider>(context);
    final records = historyProvider.records;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Intake History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () => _confirmClear(context, historyProvider),
          )
        ],
      ),
      body: historyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => historyProvider.loadHistory(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4C66EE).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: Color(0xFF4C66EE)),
                          ),
                          title: Text(record.medicineName, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text(record.dosage, 
                            style: const TextStyle(color: Colors.white60)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(DateFormat('MMM dd').format(record.takenDateTime),
                                style: const TextStyle(color: Color(0xFF4C66EE), fontWeight: FontWeight.bold)),
                              Text(DateFormat('hh:mm a').format(record.takenDateTime),
                                style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("No history found", style: TextStyle(color: Colors.white38, fontSize: 18)),
          const Text("Completed doses will appear here", style: TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Clear History?", style: TextStyle(color: Colors.white)),
        content: const Text("This will permanently delete all records.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text("CLEAR ALL", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
