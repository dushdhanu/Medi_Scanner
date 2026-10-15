import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine_analysis_result.dart';

class HistoryService {
  static const String _historyKey = 'scanned_medicine_history';
  static const int _maxHistoryItems = 30;

  /// Retrieve all saved scan results
  static Future<List<MedicineAnalysisResult>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      final results = <MedicineAnalysisResult>[];
      for (final item in list) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          results.add(MedicineAnalysisResult.fromJson(decoded));
        } catch (_) {
          // Skip malformed records
        }
      }
      // Sort newest first
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Save a newly analyzed medicine result to history
  static Future<void> saveResult(MedicineAnalysisResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];

      // Avoid exact duplicate IDs
      list.removeWhere((item) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          return decoded['id'] == result.id;
        } catch (_) {
          return false;
        }
      });

      // Insert at beginning
      list.insert(0, result.toJsonString());

      // Limit size
      if (list.length > _maxHistoryItems) {
        list.removeRange(_maxHistoryItems, list.length);
      }

      await prefs.setStringList(_historyKey, list);
    } catch (_) {
      // Storage error ignored gracefully
    }
  }

  /// Remove a single item from history by ID
  static Future<void> deleteResult(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      list.removeWhere((item) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          return decoded['id'] == id;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_historyKey, list);
    } catch (_) {}
  }

  /// Clear all saved scans
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
  }
}
