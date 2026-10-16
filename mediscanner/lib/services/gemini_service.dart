import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/medicine_analysis_result.dart';
import 'api_key_service.dart';

class GeminiServiceException implements Exception {
  final String message;
  final String? code;

  const GeminiServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

class GeminiService {
  /// Prioritized list of Gemini vision models.
  /// Automatically tries the next model if one is retired or not found on the user's API endpoint.
  static const List<String> _candidateModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
    'gemini-2.0-flash-exp',
    'gemini-1.5-pro',
  ];

  static String? _cachedWorkingModel;

  static const String _systemInstruction = '''
You are an expert clinical pharmacist, pharmaceutical vision OCR specialist, and bilingual medical communicator.
Your task is to analyze images of physical medicines (tablets, capsules, blister strips, syrup bottles, ointment tubes, inhalers, or medicine boxes) and accurately extract and identify:
1. Brand name (Trade name)
2. Generic active ingredient(s) and chemical composition
3. Dosage strength (e.g., 500mg, 10mg/5ml, 2% w/w)
4. Package/formulation type
5. Manufacturer (if visible or inferable)
6. Primary clinical uses and approved medical indications
7. General safe usage instructions (e.g., with water, with/after meals, dosage intervals, not chewing capsules)
8. Known common side effects and adverse reactions
9. Essential precautions, contraindications, and special warnings (e.g., liver/kidney disease, pregnancy, lactation, pediatric cautions, allergy risks)
10. Proper storage conditions (temperature, light, moisture, keep out of reach of children)
11. Label readability notice: explicitly state if any critical portion (such as batch number, expiry date, strength, or warnings) is blurry, cut off, worn off, or unreadable.

CRITICAL TRANSLATION REQUIREMENT:
You must provide complete and accurate data in TWO separate languages:
1. Sinhala (සිංහල): Use accurate, natural, professional Sri Lankan clinical Sinhala terminology (e.g., ඖෂධයේ නම, ක්‍රියාකාරී ද්‍රව්‍ය, භාවිතයන්, භාවිතය සඳහා උපදෙස්, අතුරු ආබාධ, පූර්වාරක්ෂාවන්, ගබඩා කිරීම).
2. English: Clear, professional clinical medical English.

OUTPUT FORMAT:
You MUST respond strictly with a valid JSON object matching the following structure without any extra commentary:
{
  "isMedicine": true,
  "confidenceRating": "High" | "Moderate" | "Low" | "Uncertain",
  "packageType": "Tablet/Capsule" | "Blister Pack" | "Syrup Bottle" | "Ointment Tube" | "Other",
  "identifiedManufacturer": "Manufacturer Name or Unknown",
  "sinhala": {
    "brandName": "වෙළඳ නාමය (සිංහලෙන්)",
    "genericName": "ක්‍රියාකාරී රසායනික නාමය සහ මාත්‍රාව (සිංහලෙන්)",
    "dosageStrength": "මාත්‍රාව (උදා: 500mg, 10mg/5ml)",
    "clinicalUses": ["භාවිතය 1", "භාවිතය 2", "භාවිතය 3"],
    "usageInstructions": "භාවිතය සඳහා උපදෙස් විස්තරාත්මකව",
    "sideEffects": ["අතුරු ආබාධය 1", "අතුරු ආබාධය 2"],
    "precautions": ["පූර්වාරක්ෂාව 1", "පූර්වාරක්ෂාව 2"],
    "storageGuidelines": "ගබඩා කිරීමේ උපදෙස්",
    "unreadableNotice": "පැකට්ටුවේ හෝ ලේබලයේ අපැහැදිලි කොටස් පිළිබඳ සටහනක් (ඇත්නම්)"
  },
  "english": {
    "brandName": "Brand Name",
    "genericName": "Generic active ingredient(s)",
    "dosageStrength": "Dosage Strength",
    "clinicalUses": ["Indication 1", "Indication 2", "Indication 3"],
    "usageInstructions": "Usage instructions and administration guidance",
    "sideEffects": ["Side effect 1", "Side effect 2"],
    "precautions": ["Precaution 1", "Precaution 2"],
    "storageGuidelines": "Storage guidelines",
    "unreadableNotice": "Notice regarding obscured or blurry text if any"
  },
  "generalWarning": "Medical Disclaimer: This AI analysis is for informational identification assistance only. Always consult a licensed physician or pharmacist before consuming any medicine."
}

If the image is NOT a medicine, or is too blurry/dark to recognize anything, set "isMedicine": false, "confidenceRating": "Uncertain", and provide constructive guidance in both Sinhala and English requesting a clearer photo with proper lighting.
''';

  /// Get prioritized list of models to try
  static List<String> _getModelsToTry() {
    if (_cachedWorkingModel != null) {
      return [
        _cachedWorkingModel!,
        ..._candidateModels.where((m) => m != _cachedWorkingModel),
      ];
    }
    return _candidateModels;
  }

  /// Analyze the medicine image using Gemini Multimodal Vision with automatic model fallback
  static Future<MedicineAnalysisResult> analyzeMedicineImage({
    required Uint8List imageBytes,
    required String mimeType,
    String? customApiKey,
    String? localImagePath,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : await ApiKeyService.getApiKey();

    if (apiKey.isEmpty) {
      throw const GeminiServiceException(
        'Gemini API key is not configured. Please tap the Settings key icon to enter your free Google AI Studio API key.',
        code: 'MISSING_API_KEY',
      );
    }

    final modelsToTry = _getModelsToTry();
    String? lastErrorMessage;

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.15,
            responseMimeType: 'application/json',
          ),
        );

        final promptText = TextPart(
          'Analyze this medicine image thoroughly. Read all printed, engraved, or embossed text, identify the brand, active ingredients, dosage, formulation, indications, usage, side effects, precautions, and storage in both Sinhala and English as specified. Output pure JSON.',
        );

        final imagePart = DataPart(mimeType, imageBytes);

        final response = await model.generateContent([
          Content.text(_systemInstruction),
          Content.multi([promptText, imagePart]),
        ]);

        final rawText = response.text;
        if (rawText == null || rawText.trim().isEmpty) {
          throw const GeminiServiceException(
            'Gemini Vision returned an empty response. Please capture a clearer picture in better lighting.',
            code: 'EMPTY_RESPONSE',
          );
        }

        final cleanedJsonString = _extractJson(rawText);
        final dynamic decoded = jsonDecode(cleanedJsonString);

        if (decoded is! Map<String, dynamic>) {
          throw const GeminiServiceException(
            'Unexpected data format returned from AI model. Please try again.',
            code: 'INVALID_JSON_STRUCTURE',
          );
        }

        // Cache working model for future calls
        _cachedWorkingModel = modelName;

        return MedicineAnalysisResult.fromJson(
          decoded,
          imagePath: localImagePath,
        );
      } on GenerativeAIException catch (e) {
        final msg = e.message.toLowerCase();
        // If model not found or not supported for this version, try next candidate
        if (msg.contains('not found') || msg.contains('not supported') || msg.contains('404')) {
          lastErrorMessage = e.message;
          continue;
        }

        if (msg.contains('api_key') || msg.contains('unauthorized') || msg.contains('invalid api key')) {
          throw const GeminiServiceException(
            'The provided Google Gemini API key is invalid or unauthorized. Please verify your key in Settings.',
            code: 'INVALID_API_KEY',
          );
        } else if (msg.contains('quota') || msg.contains('resource_exhausted') || msg.contains('rate limit')) {
          throw const GeminiServiceException(
            'Gemini free tier quota exceeded or rate limit reached. Please wait a minute and retry.',
            code: 'QUOTA_EXCEEDED',
          );
        } else {
          throw GeminiServiceException(
            'Gemini Vision error: ${e.message}',
            code: 'GEMINI_ERROR',
          );
        }
      } on FormatException catch (e) {
        throw GeminiServiceException(
          'Failed to parse medical insight data: ${e.message}. Please try scanning again with better focus.',
          code: 'PARSE_ERROR',
        );
      } catch (e) {
        if (e is GeminiServiceException) rethrow;
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('not found') || errorStr.contains('404')) {
          lastErrorMessage = e.toString();
          continue;
        }
        throw GeminiServiceException(
          'Failed to connect to Gemini Vision: $e. Please check your internet connection and try again.',
          code: 'NETWORK_OR_UNKNOWN',
        );
      }
    }

    throw GeminiServiceException(
      'Could not access Gemini model: $lastErrorMessage. Please ensure your Google AI Studio API key has Gemini API enabled.',
      code: 'MODEL_UNAVAILABLE',
    );
  }

  /// Analyze drug-to-drug interactions using multimodal vision with model fallback
  static Future<String> checkDrugInteraction({
    required Uint8List bytesA,
    required Uint8List bytesB,
    String? customApiKey,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : await ApiKeyService.getApiKey();

    if (apiKey.isEmpty) {
      throw const GeminiServiceException(
        'Please configure your Gemini API Key in Settings first.',
        code: 'MISSING_API_KEY',
      );
    }

    const prompt = '''
You are an expert clinical pharmacologist.
Analyze these two medicine images (Medicine 1 and Medicine 2).
Identify the active ingredients of both.
Determine whether there is any known Drug-to-Drug Interaction (DDI), contraindication, or danger if a patient consumes both concurrently.

Format your answer clearly in TWO sections:
1. සිංහලෙන් (Sinhala):
- ඖෂධ 1 සහ ඖෂධ 2 හි ක්‍රියාකාරී රසායනික ද්‍රව්‍ය
- අන්තර්ක්‍රියා අවදානම් මට්ටම: [ආරක්ෂිතයි / ප්‍රවේශම් වන්න / ඉතා අනතුරුදායකයි]
- විස්තරාත්මක වෛද්‍ය පැහැදිලි කිරීම
- නිර්දේශිත ක්‍රියාමාර්ග

2. In English:
- Identified compounds
- Interaction Risk Level: [Safe / Moderate Caution / Severe Danger]
- Clinical mechanism of interaction
- Pharmacist recommendations

Finish with a clear medical disclaimer.
''';

    final modelsToTry = _getModelsToTry();
    String? lastError;

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final response = await model.generateContent([
          Content.text(prompt),
          Content.multi([
            DataPart('image/jpeg', bytesA),
            DataPart('image/jpeg', bytesB),
          ]),
        ]);

        final text = response.text;
        if (text != null && text.trim().isNotEmpty) {
          _cachedWorkingModel = modelName;
          return text;
        }
      } on GenerativeAIException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('not found') || msg.contains('not supported') || msg.contains('404')) {
          lastError = e.message;
          continue;
        }
        rethrow;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('not found') || msg.contains('404')) {
          lastError = e.toString();
          continue;
        }
        rethrow;
      }
    }

    throw GeminiServiceException(
      'Could not connect to Gemini model for interaction check: $lastError',
      code: 'MODEL_UNAVAILABLE',
    );
  }

  /// Strip markdown ```json ... ``` wrapper if present
  static String _extractJson(String text) {
    var trimmed = text.trim();
    if (trimmed.startsWith('```json')) {
      trimmed = trimmed.substring(7);
    } else if (trimmed.startsWith('```')) {
      trimmed = trimmed.substring(3);
    }
    if (trimmed.endsWith('```')) {
      trimmed = trimmed.substring(0, trimmed.length - 3);
    }
    return trimmed.trim();
  }
}
