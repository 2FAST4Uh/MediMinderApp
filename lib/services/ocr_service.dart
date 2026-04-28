import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  // IMPORTANT: Replace with your actual Gemini API Key
  static const String _apiKey = 'your api key';
  
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _legacyRecognizer = TextRecognizer();
  late final GenerativeModel _model;

  OCRService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  Future<Map<String, String>?> scanPrescription({required Function(String) onStatusChange}) async {
    // 1. Capture the image
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (image == null) return null;
    final File imageFile = File(image.path);

    // --- TRY GEMINI AI FIRST ---
    try {
      onStatusChange("AI is analyzing...");
      final imageBytes = await image.readAsBytes();
      
      final prompt = 'Analyze this prescription. Return ONLY valid JSON: '
        '{"name": "", "dosage": "", "frequency": "Once|Twice|3x|4x", "mealInstruction": "Before|With|After", "stock": "15", "notes": ""}';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
      ]);

      if (response.text != null) {
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(response.text!);
        if (jsonMatch != null) {
          final Map<String, dynamic> data = jsonDecode(jsonMatch);
          return _formatResult(data);
        }
      }
      throw Exception("Invalid AI Response");
    } catch (e) {
      // --- FALLBACK TO LEGACY OCR ---
      onStatusChange("AI Failed. Using local scanner...");
      return await _performLegacyOCR(imageFile);
    }
  }

  Future<Map<String, String>> _performLegacyOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _legacyRecognizer.processImage(inputImage);
    
    String name = "Unknown";
    String dosage = "Check Label";
    
    final lines = recognizedText.text.split('\n');
    final dosageRegex = RegExp(r'(\d+\s?(mg|ml|tabs|pills))', caseSensitive: false);

    for (var line in lines) {
      if (dosageRegex.hasMatch(line)) {
        dosage = dosageRegex.firstMatch(line)?.group(0) ?? dosage;
        name = line.replaceAll(dosage, '').trim();
        if (name.length > 2) break;
      }
    }

    return {
      'name': name.isEmpty ? "Unknown" : name,
      'dosage': dosage,
      'frequency': "Once",
      'mealInstruction': "Before",
      'stock': "15",
      'notes': "Scanned via offline engine.",
    };
  }

  Map<String, String> _formatResult(Map<String, dynamic> data) {
    return {
      'name': data['name']?.toString() ?? "Unknown",
      'dosage': data['dosage']?.toString() ?? "Check Label",
      'frequency': data['frequency']?.toString() ?? "Once",
      'mealInstruction': data['mealInstruction']?.toString() ?? "Before",
      'stock': data['stock']?.toString() ?? "15",
      'notes': data['notes']?.toString() ?? "",
    };
  }

  void dispose() {
    _legacyRecognizer.close();
  }
}
