import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/logger_service.dart';

class ApiService {
  // ================== CONFIG ==================
  static const int _timeoutSeconds = 25;
  static const String _baseUrl = 'https://smart-messages-app.onrender.com/api';
  // ============================================

  // ================= PUBLIC ====================
  Future<Map<String, dynamic>> summarizeMessages(List<String> messages) async {
    final url = '$_baseUrl/summarize';
    LoggerService.info('POST $url  |  messages: ${messages.length}');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'messages': messages}),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      LoggerService.debug('Status: ${response.statusCode}');
      LoggerService.debug('Body  : ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // transformăm evenimentele doar dacă există
        final List<Map<String, dynamic>> events = [];
        if (data['events'] != null) {
          for (final e in data['events']) {
            if (e['title'] != null && e['dateTime'] != null) {
              events.add({
                'title': e['title'],
                'dateTime': e['dateTime'],
                'location': e['location'] ?? '',
                'eventType': e['eventType'] ?? 'Eveniment',
              });
            }
          }
        }

        return {
          'summary': data['summary'] ?? 'Nu s-a putut genera rezumatul.',
          'detectedEvents': events,
        };
      }

      LoggerService.error(
        'API error: ${response.statusCode} – ${response.body}',
      );
      return _generateMockSummary(messages);
    } on TimeoutException {
      LoggerService.error('Timeout după $_timeoutSeconds secunde');
      return _generateMockSummary(messages);
    } catch (e) {
      LoggerService.error('Excepție la apelarea API-ului: $e');
      return _generateMockSummary(messages);
    }
  }

  Future<String> askQuestion(List<String> messages, String question) async {
    final url = '$_baseUrl/ask';
    LoggerService.info('POST $url  |  q: "$question"');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'messages': messages, 'question': question}),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Nu s-a putut genera răspunsul.';
      }

      LoggerService.error(
        'API error: ${response.statusCode} – ${response.body}',
      );
      return 'Nu s-a putut genera răspunsul.';
    } catch (e) {
      LoggerService.error('Excepție la apelarea API-ului: $e');
      return 'Nu s-a putut genera răspunsul.';
    }
  }
  // ============================================

  // =============== FALLBACK LOCAL ==============
  Map<String, dynamic> _generateMockSummary(List<String> messages) {
    LoggerService.info('[MOCK] Server indisponibil – generăm rezumat local');

    if (messages.isEmpty) {
      return {
        'summary': 'Nu există mesaje disponibile pentru sumarizare.',
        'detectedEvents': [],
      };
    }

    // extragem participanții
    final uniquePeople = <String>{};
    for (final m in messages) {
      final parts = m.split(':');
      if (parts.isNotEmpty) uniquePeople.add(parts.first.trim());
    }

    // exemple de mesaje
    final examples = <String>[];
    for (var i = 0; i < _min(5, messages.length); i++) {
      final parts = messages[i].split(':');
      if (parts.length >= 2) {
        examples.add(
          '${parts.first.trim()}: "${parts.sublist(1).join(':').trim()}"',
        );
      }
    }

    var summary =
        'În această conversație, ${uniquePeople.join(' și ')} '
        'au schimbat ${messages.length} mesaje.\n\n';
    if (examples.isNotEmpty) {
      summary += examples.map((e) => '• $e').join('\n');
      if (messages.length > examples.length) {
        summary += '\n... și alte ${messages.length - examples.length} mesaje.';
      }
    }

    return {'summary': summary, 'detectedEvents': []};
  }

  // ============================================
}

int _min(int a, int b) => a < b ? a : b;
