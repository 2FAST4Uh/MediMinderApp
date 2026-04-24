import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSection(context, "Appearance"),
          _buildTile(
            context,
            "Dark Mode",
            "Switch between light and dark themes",
            Icons.dark_mode,
            DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (mode) {
                if (mode != null) settings.setThemeMode(mode);
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text("System")),
                DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark")),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(context, "Voice & Alerts"),
          _buildTile(
            context,
            "Voice Guidance",
            "Read instructions out loud",
            Icons.record_voice_over,
            Switch(
              value: settings.isVoiceEnabled,
              onChanged: (val) {
                settings.toggleVoice(val);
                TTSService().speak(val ? "Voice guidance enabled" : "Voice guidance disabled");
              },
            ),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text("MediMinder v1.1.0\nBy CareSync Health", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey)
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title.toUpperCase(), style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary
      )),
    );
  }

  Widget _buildTile(BuildContext context, String title, String subtitle, IconData icon, Widget trailing) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
