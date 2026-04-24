import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _isVoiceEnabled = true;
  bool _isHighContrast = false;
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark as per screenshot

  bool get isVoiceEnabled => _isVoiceEnabled;
  bool get isHighContrast => _isHighContrast;
  ThemeMode get themeMode => _themeMode;

  void toggleVoice(bool value) {
    _isVoiceEnabled = value;
    TTSService().setEnabled(value); // This ensures TTS engine stops immediately
    notifyListeners();
  }

  void toggleHighContrast(bool value) {
    _isHighContrast = value;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
