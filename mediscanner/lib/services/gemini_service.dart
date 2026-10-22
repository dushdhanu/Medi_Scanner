import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/medicine_analysis_result.dart';
import '../models/prescription_analysis_result.dart';
import 'api_key_service.dart';

class GeminiServiceException implements Exception {
  final String message;
  final String? code;

  const GeminiServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

class GeminiService {
  /// Prioritized list of active, verified Gemini vision models.
  /// gemini-3.7-flash and gemini-3.5-flash have been verified with HTTP 200 on this account.
  static const List<String> _candidateModels = [
    'gemini-3.7-flash',
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemini-3.8-flash',
    'gemini-flash-latest',
    'gemini-3-flash-preview',
    'gemini-2.5-pro',
  ];

  static String? _cachedWorkingModel = 'gemini-3.7-flash';

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
12. Sri Lankan SPC / Rajya Osu Sala Generic Alternative: approved State Pharmaceuticals Corporation generic equivalent (e.g. for branded Augmentin -> Co-Amoxiclav SPC, for Panadol -> Paracetamol SPC) with estimated affordability benefits.
13. Critical Dietary & Beverage Contraindications: Specific food/drink warnings (e.g., Avoid Milk/Dairy with Tetracycline/Ciprofloxacin, Avoid Tea/Coffee within 2 hours of Iron supplements, Strict NO Alcohol with Metronidazole/sedatives, Take Before/With/After meals).

CRITICAL TRANSLATION REQUIREMENT:
You must provide complete and accurate data in TWO separate languages:
1. Sinhala (සිංහල): Use accurate, natural, professional Sri Lankan clinical Sinhala terminology (e.g., ඖෂධයේ නම, ක්‍රියාකාරී ද්‍රව්‍ය, භාවිතයන්, භාවිතය සඳහා උපදෙස්, අතුරු ආබාධ, පූර්වාරක්ෂාවන්, ගබඩා කිරීම, රාජ්‍ය ඔසු සල / SPC ලාභදායී ආදේශක, ආහාර සහ පාන වර්ග අවවාද).
2. English: Clear, professional clinical medical English.

OUTPUT FORMAT:
You MUST respond strictly with a valid JSON object matching the following structure without any extra commentary:
{
  "isMedicine": true,
  "confidenceRating": "High" | "Moderate" | "Low" | "Uncertain",
  "packageType": "Tablet/Capsule" | "Blister Pack" | "Syrup Bottle" | "Ointment Tube" | "Other",
  "identifiedManufacturer": "Manufacturer Name or Unknown",
  "expiryDate": "MM/YYYY (e.g. 10/2027 or null if not visible)",
  "batchNumber": "Batch or Lot number if visible, or null",
  "sinhala": {
    "brandName": "වෙළඳ නාමය (සිංහලෙන්)",
    "genericName": "ක්‍රියාකාරී රසායනික නාමය සහ මාත්‍රාව (සිංහලෙන්)",
    "dosageStrength": "මාත්‍රාව (උදා: 500mg, 10mg/5ml)",
    "clinicalUses": ["භාවිතය 1", "භාවිතය 2", "භාවිතය 3"],
    "usageInstructions": "භාවිතය සඳහා උපදෙස් විස්තරාත්මකව",
    "sideEffects": ["අතුරු ආබාධය 1", "අතුරු ආබාධය 2"],
    "precautions": ["පූර්වාරක්ෂාව 1", "පූර්වාරක්ෂාව 2"],
    "storageGuidelines": "ගබඩා කිරීමේ උපදෙස්",
    "unreadableNotice": "පැකට්ටුවේ හෝ ලේබලයේ අපැහැදිලි කොටස් පිළිබඳ සටහනක් (ඇත්නම්)",
    "spcGenericAlternative": "රාජ්‍ය ඔසු සල / SPC අනුමත ලාභදායී ආදේශක ඖෂධය",
    "dietaryWarnings": ["කිරි හෝ කිරි නිෂ්පාදන අවවාදය", "තේ/කෝපි අවවාදය", "මධ්‍යසාර අවවාදය"]
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
    "unreadableNotice": "Notice regarding obscured or blurry text if any",
    "spcGenericAlternative": "Approved SPC / Rajya Osu Sala generic alternative",
    "dietaryWarnings": ["Dietary/drink contraindication 1", "Dietary/drink contraindication 2"]
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
    return List<String>.from(_candidateModels);
  }

  /// Check whether an error message indicates an outdated, unavailable, or busy model
  static bool _isModelUnavailableOrBusy(String msg) {
    return msg.contains('not found') ||
        msg.contains('not supported') ||
        msg.contains('no longer available') ||
        msg.contains('deprecated') ||
        msg.contains('update your code') ||
        msg.contains('503') ||
        msg.contains('high demand') ||
        msg.contains('unavailable') ||
        msg.contains('server error') ||
        msg.contains('overloaded') ||
        msg.contains('404');
  }

  /// Analyze the medicine image using Gemini Multimodal Vision with automatic model fallback & busy retry
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

    int i = 0;
    while (i < modelsToTry.length) {
      final modelName = modelsToTry[i];
      i++;

      // Retry up to 3 times per model in case of temporary 503 High Demand spikes
      for (int attempt = 0; attempt < 3; attempt++) {
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

          // If Google returns 503 / High Demand / Busy, wait briefly and retry
          if (msg.contains('503') || msg.contains('high demand') || msg.contains('unavailable') || msg.contains('overloaded')) {
            if (attempt < 2) {
              await Future.delayed(Duration(milliseconds: 1500 * (attempt + 1)));
              continue; // retry current model
            }
          }

          // If model retired, no longer available, or still busy after retries, try next candidate model
          if (_isModelUnavailableOrBusy(msg)) {
            lastErrorMessage = e.message;

            // If Google recommends a specific model in the error message, add it to the front
            final matches = RegExp(r'models/([a-zA-Z0-9._-]+)').allMatches(e.message);
            for (final m in matches) {
              final suggested = m.group(1);
              if (suggested != null && !modelsToTry.contains(suggested)) {
                modelsToTry.insert(i, suggested);
              }
            }
            break; // break retry loop to try next model in candidate list
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
          if (_isModelUnavailableOrBusy(errorStr)) {
            lastErrorMessage = e.toString();
            break; // try next candidate model
          }
          throw GeminiServiceException(
            'Failed to connect to Gemini Vision: $e. Please check your internet connection and try again.',
            code: 'NETWORK_OR_UNKNOWN',
          );
        }
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

    int i = 0;
    while (i < modelsToTry.length) {
      final modelName = modelsToTry[i];
      i++;

      for (int attempt = 0; attempt < 3; attempt++) {
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
          if (msg.contains('503') || msg.contains('high demand') || msg.contains('unavailable')) {
            if (attempt < 2) {
              await Future.delayed(Duration(milliseconds: 1500 * (attempt + 1)));
              continue;
            }
          }
          if (_isModelUnavailableOrBusy(msg)) {
            lastError = e.message;

            final matches = RegExp(r'models/([a-zA-Z0-9._-]+)').allMatches(e.message);
            for (final m in matches) {
              final suggested = m.group(1);
              if (suggested != null && !modelsToTry.contains(suggested)) {
                modelsToTry.insert(i, suggested);
              }
            }
            break;
          }
          rethrow;
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (_isModelUnavailableOrBusy(msg)) {
            lastError = e.toString();
            break;
          }
          rethrow;
        }
      }
    }

    throw GeminiServiceException(
      'Could not connect to Gemini model for interaction check: $lastError',
      code: 'MODEL_UNAVAILABLE',
    );
  }

  /// Decipher and analyze handwritten doctor's prescriptions using Gemini Multimodal OCR
  static Future<PrescriptionAnalysisResult> analyzePrescriptionImage({
    required Uint8List imageBytes,
    String? imagePath,
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

    const prescriptionPrompt = '''
You are a senior clinical pharmacist and medical OCR handwriting recognition expert specializing in deciphering doctors' cursive handwritten prescriptions, clinical notations, and Latin medical abbreviations.

Carefully examine this handwritten prescription image.
Identify:
1. Doctor or Hospital/Clinic Name and Date (if visible).
2. Patient Name (if visible).
3. The list of all prescribed medicines line-by-line.

For each medication line, extract:
- "drugName": Brand or generic medicine name (e.g. "Amoxicillin", "Paracetamol", "Omeprazole", "Metformin").
- "genericName": Active chemical compound name.
- "dosageStrength": Strength / formulation (e.g. "500mg tab", "250mg/5ml syrup", "20mg cap").
- "frequencyCode": Medical abbreviation used on the script:
  - "o.d." or "mane" = Once daily (morning)
  - "nocte" = Once daily at bedtime
  - "b.d." or "b.i.d." = Twice daily (every 12 hours)
  - "t.d.s." or "t.i.d." = Thrice daily (every 8 hours)
  - "q.d.s." or "q.i.d." = Four times daily (every 6 hours)
  - "p.r.n." = As needed / when necessary
  - "stat" = Immediately
- "instructionsEn": Clear English dosage instruction (e.g. "Take 1 tablet twice daily after meals").
- "instructionsSi": Fluent, natural Sinhala dosage instruction (e.g. "කෑමට පසු දිනකට දෙවරක් පෙති 1 බැගින් ගන්න").
- "mealTiming": One of: "Before meals", "After meals", "With meals", "Unspecified".
- "mealTimingSi": One of: "කෑමට පෙර", "කෑමට පසු", "ආහාර සමඟ", "සඳහන්ව නැත".
- "duration": Duration of treatment in English (e.g. "5 days", "1 week", "1 month"). Note: "x 5/7" means 5 days, "x 2/52" means 2 weeks, "x 1/12" means 1 month.
- "durationSi": Treatment duration in Sinhala (e.g. "දින 5ක්", "සති 2ක්", "මාස 1ක්").
- "specialPrecautions": Any warning, e.g., "Complete full antibiotic course", "Take with plenty of water".

Return STRICT VALID JSON ONLY (no markdown formatting, no commentary):
{
  "doctorOrClinicName": string or null,
  "prescriptionDate": string or null,
  "patientName": string or null,
  "medicines": [
    {
      "drugName": "string",
      "genericName": "string",
      "dosageStrength": "string",
      "frequencyCode": "string",
      "instructionsEn": "string",
      "instructionsSi": "string",
      "mealTiming": "string",
      "mealTimingSi": "string",
      "duration": "string",
      "durationSi": "string",
      "specialPrecautions": "string or null"
    }
  ],
  "clinicalNotesEn": "string",
  "clinicalNotesSi": "string",
  "generalWarning": "Handwritten prescriptions must be formally checked and dispensed by a licensed registered pharmacist."
}
''';

    final modelsToTry = _getModelsToTry();
    String? lastErrorMessage;

    int i = 0;
    while (i < modelsToTry.length) {
      final modelName = modelsToTry[i];
      i++;

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
          );

          final response = await model.generateContent([
            Content.text(prescriptionPrompt),
            Content.data('image/jpeg', imageBytes),
          ]);

          final rawText = response.text;
          if (rawText == null || rawText.trim().isEmpty) {
            throw const GeminiServiceException(
              'Received an empty response from Gemini Vision. Please try a clearer prescription photo.',
              code: 'EMPTY_RESPONSE',
            );
          }

          final cleanedJson = _extractJson(rawText);
          final Map<String, dynamic> decoded = jsonDecode(cleanedJson) as Map<String, dynamic>;
          _cachedWorkingModel = modelName;
          return PrescriptionAnalysisResult.fromJson(decoded, imagePath: imagePath);
        } on GenerativeAIException catch (e) {
          final msg = e.message.toLowerCase();
          if (msg.contains('503') || msg.contains('high demand') || msg.contains('unavailable')) {
            if (attempt < 2) {
              await Future.delayed(Duration(milliseconds: 1500 * (attempt + 1)));
              continue;
            }
          }
          if (_isModelUnavailableOrBusy(msg)) {
            lastErrorMessage = e.message;
            break;
          }
          rethrow;
        } catch (e) {
          if (e is GeminiServiceException) rethrow;
          final errorStr = e.toString().toLowerCase();
          if (_isModelUnavailableOrBusy(errorStr)) {
            lastErrorMessage = e.toString();
            break;
          }
          throw GeminiServiceException(
            'Failed to decipher prescription: $e',
            code: 'PRESCRIPTION_PARSE_ERROR',
          );
        }
      }
    }

    throw GeminiServiceException(
      'Could not access Gemini model for prescription deciphering: $lastErrorMessage',
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
