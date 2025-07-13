import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _keyFiles = 'saved_files';
  static const String _keyConversations = 'saved_conversations';

  Future<void> saveFiles(String platform, List<String> files) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> savedFiles = _loadSavedData(prefs, _keyFiles);
    savedFiles[platform] = files;
    await prefs.setString(_keyFiles, jsonEncode(savedFiles));
  }

  Future<List<String>> loadFiles(String platform) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> savedFiles = _loadSavedData(prefs, _keyFiles);
    return List<String>.from(savedFiles[platform] ?? []);
  }

  Future<void> saveConversations(String platform, Map<String, dynamic> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> savedConversations = _loadSavedData(prefs, _keyConversations);
    
    // Convert DateTime objects to ISO strings
    final Map<String, dynamic> serializedConversations = {
      'people': conversations['people'],
      'dates': _serializeDates(conversations['dates']),
      'messages': _serializeMessages(conversations['messages']),
    };
    
    savedConversations[platform] = serializedConversations;
    await prefs.setString(_keyConversations, jsonEncode(savedConversations));
  }

  Future<Map<String, dynamic>> loadConversations(String platform) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> savedConversations = _loadSavedData(prefs, _keyConversations);
    final Map<String, dynamic> platformConversations = Map<String, dynamic>.from(savedConversations[platform] ?? {});
    
    // Convert ISO strings back to DateTime objects
    return {
      'people': List<String>.from(platformConversations['people'] ?? []),
      'dates': _deserializeDates(platformConversations['dates']),
      'messages': _deserializeMessages(platformConversations['messages']),
    };
  }

  Map<String, dynamic> _serializeDates(Map<String, List<DateTime>>? dates) {
    if (dates == null) return {};
    return dates.map((key, value) => MapEntry(
      key,
      value.map((date) => date.toIso8601String()).toList(),
    ));
  }

  Map<String, List<DateTime>> _deserializeDates(Map<String, dynamic>? dates) {
    if (dates == null) return {};
    return dates.map((key, value) => MapEntry(
      key,
      List<String>.from(value).map((dateStr) => DateTime.parse(dateStr)).toList(),
    ));
  }

  Map<String, dynamic> _serializeMessages(
      Map<String, Map<DateTime, List<String>>>? messages) {
    if (messages == null) return {};
    return messages.map((person, dateMap) => MapEntry(
          person,
          dateMap.map((date, msgs) =>
              MapEntry(date.toIso8601String(), msgs)),
        ));
  }

  Map<String, Map<DateTime, List<String>>> _deserializeMessages(
      Map<String, dynamic>? messages) {
    if (messages == null) return {};
    return messages.map((person, dateMap) => MapEntry(
          person,
          (dateMap as Map<String, dynamic>).map((dateStr, msgs) => MapEntry(
                DateTime.parse(dateStr),
                List<String>.from(msgs),
              )),
        ));
  }

  Future<void> clearPlatformData(String platform) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear files
    final Map<String, dynamic> savedFiles = _loadSavedData(prefs, _keyFiles);
    savedFiles.remove(platform);
    await prefs.setString(_keyFiles, jsonEncode(savedFiles));
    
    // Clear conversations
    final Map<String, dynamic> savedConversations = _loadSavedData(prefs, _keyConversations);
    savedConversations.remove(platform);
    await prefs.setString(_keyConversations, jsonEncode(savedConversations));
  }

  Map<String, dynamic> _loadSavedData(SharedPreferences prefs, String key) {
    final String? data = prefs.getString(key);
    if (data == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }
}

final storageService = StorageService(); 