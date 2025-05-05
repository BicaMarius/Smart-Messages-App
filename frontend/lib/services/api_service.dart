import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/logger_service.dart';

class ApiService {
  // Adresa IP a serverului backend - implicită, modificabilă ulterior
  static const int _timeoutSeconds = 10; 
  // static const String _defaultIp = '192.168.1.132'; // Wifi Bucuresti
  // static const String _defaultIp = '192.168.0.199'; // Wifi Balș
  static const String _defaultIp = '192.168.135.108'; // Hotspot Honor70

  // URL-ul de bază pentru apelarea backend-ului
  String _baseUrl = 'http://127.0.0.1:3000/api';

  // Constructor care permite setarea unui baseUrl personalizat
  ApiService({String? baseUrl}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    _loadSavedIp();
  }

  // =======================
  //   Gestionare IP salvat
  // =======================
  Future<void> _loadSavedIp() async {
    try {
      // Forțăm folosirea IP-ului implicit
      LoggerService.debug('Folosim IP-ul implicit: $_defaultIp');
      _baseUrl = 'http://$_defaultIp:3000/api';
      LoggerService.info('Adresa API actualizată: $_baseUrl');
      
      // Salvăm IP-ul implicit pentru sesiuni viitoare
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', _defaultIp);
      LoggerService.debug('IP salvat în SharedPreferences: $_defaultIp');
    } catch (e) {
      LoggerService.error('Eroare la încărcarea adresei IP: $e');
    }
  }

  Future<void> updateServerIp(String newIp) async {
    _baseUrl = 'http://$newIp:3000/api';
    LoggerService.info('Adresa API actualizată: $_baseUrl');

    // Salvăm adresa pentru sesiuni viitoare
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', newIp);
      LoggerService.debug('IP salvat în SharedPreferences: $newIp');
    } catch (e) {
      LoggerService.error('Eroare la salvarea adresei IP: $e');
    }
  }

  // ===================================
  //   Fallback local: _generateMockSummary
  // ===================================
  Map<String, dynamic> _generateMockSummary(List<String> messages) {
    LoggerService.info('Folosim sumarizare LOCALĂ pentru că serverul nu e disponibil');

    if (messages.isEmpty) {
      return {
        'summary': 'Nu există mesaje disponibile pentru sumarizare.',
        'detectedEvents': []
      };
    }

    // Extragem participanți
    final Set<String> uniquePeople = {};
    for (final message in messages) {
      final parts = message.split(':');
      if (parts.isNotEmpty) {
        uniquePeople.add(parts[0].trim());
      }
    }

    // Extragem câteva exemple de mesaje
    final List<String> messageExamples = [];
    for (int i = 0; i < _min(5, messages.length); i++) {
      final parts = messages[i].split(':');
      if (parts.length >= 2) {
        final name = parts[0].trim();
        final messageText = parts.sublist(1).join(':').trim();
        messageExamples.add('$name: "$messageText"');
      }
    }

    String summary = '';
    if (messageExamples.isNotEmpty) {
      summary = 'În această conversație:\n\n';
      for (final example in messageExamples) {
        summary += '• $example\n';
      }
      if (messages.length > messageExamples.length) {
        summary += '\n... și alte ${messages.length - messageExamples.length} mesaje.';
      }
    } else {
      summary = 'În această conversație, ${uniquePeople.join(' și ')} au schimbat ${messages.length} mesaje.';
    }

    return {
      'summary': summary,
      'detectedEvents': []
    };
  }

  // =============================
  //   summarizeMessages
  // =============================
  Future<Map<String, dynamic>> summarizeMessages(List<String> messages) async {
    final localIp = _defaultIp; // Adresa IP a serverului local
    
    try {
      // Mai întâi încercăm pe localhost
      LoggerService.debug('Se încearcă API-ul pe: http://127.0.0.1:3000/api/summarize');
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:3000/api/summarize'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'messages': messages}),
        ).timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          LoggerService.info('Sumarizare reușită de la API!');
          
          // Parse events from the response
          final List<Map<String, dynamic>> events = [];
          if (data['events'] != null) {
            for (var event in data['events']) {
              if (event['title'] != null && event['dateTime'] != null) {
                events.add({
                  'title': event['title'],
                  'dateTime': event['dateTime'],
                  'location': event['location'] ?? '',
                  'eventType': event['eventType'] ?? 'Eveniment'
                });
              }
            }
          }

          return {
            'summary': data['summary'] ?? 'Nu s-a putut genera rezumatul.',
            'detectedEvents': events
          };
        }
      } catch (e) {
        LoggerService.info('Localhost indisponibil: $e');
      }

      // Apoi încercăm pe IP-ul local
      LoggerService.debug('Se apelează API-ul de sumarizare la http://$localIp:3000/api/summarize');
      LoggerService.info('Număr de mesaje trimise: ${messages.length}');

      final response = await http.post(
        Uri.parse('http://$localIp:3000/api/summarize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': messages}),
      ).timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('Sumarizare reușită de la API!');
        
        // Parse events from the response
        final List<Map<String, dynamic>> events = [];
        if (data['events'] != null) {
          for (var event in data['events']) {
            if (event['title'] != null && event['dateTime'] != null) {
              events.add({
                'title': event['title'],
                'dateTime': event['dateTime'],
                'location': event['location'] ?? '',
                'eventType': event['eventType'] ?? 'Eveniment'
              });
            }
          }
        }

        return {
          'summary': data['summary'] ?? 'Nu s-a putut genera rezumatul.',
          'detectedEvents': events
        };
      } else {
        LoggerService.error('Eroare la API: ${response.statusCode}, ${response.body}');
        return _generateMockSummary(messages);
      }
    } catch (e) {
      LoggerService.error('Excepție la apelarea API-ului: $e');
      return _generateMockSummary(messages);
    }
  }

  // =============================
  //   askQuestion
  // =============================
  Future<String> askQuestion(List<String> messages, String question) async {
    try {
      // Folosim direct IP-ul implicit pentru ask
      final askUrl = 'http://$_defaultIp:3000/api/ask';
      LoggerService.debug('Se apelează API-ul la $askUrl');

      final response = await http.post(
        Uri.parse(askUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': messages,
          'question': question
        }),
      ).timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Nu s-a putut genera răspunsul.';
      } else {
        LoggerService.error('Eroare la API: ${response.statusCode}, ${response.body}');
        return 'Nu s-a putut genera răspunsul.';
      }
    } catch (e) {
      LoggerService.error('Excepție la apelarea API-ului: $e');
      return 'Nu s-a putut genera răspunsul.';
    }
  }
}

// Funcție de utilitate pentru a compara două numere
int _min(int a, int b) => a < b ? a : b;
