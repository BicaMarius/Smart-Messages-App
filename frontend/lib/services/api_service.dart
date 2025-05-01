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
  static const String _defaultIp = '192.168.40.153'; // Hotspot Honor70

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
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('server_ip');
      if (savedIp != null && savedIp.isNotEmpty) {
        updateServerIp(savedIp);
        LoggerService.info('Am încărcat adresa IP salvată: $savedIp');
      } else {
        // Dacă nu există IP salvat, folosim IP-ul implicit
        updateServerIp(_defaultIp);
      }
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

    // Detectăm evenimente local
    final List<Map<String, dynamic>> detectedEvents = [];

    // Regexp pentru "La mulți ani"
    final birthdayRegex = RegExp(
      r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4}),\s+\d{1,2}:\d{2}\s+\-\s+([^:]+):\s+La\s+mulți\s+ani',
      caseSensitive: false,
    );
    final birthdayMentionRegex = RegExp(r'zile?(\s+de)?\s+na[șs]tere', caseSensitive: false);

    // Căutăm evenimente de tip "La mulți ani"
    for (final message in messages) {
      final match = birthdayRegex.firstMatch(message);
      if (match != null) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!) - 1;
          final year = int.parse(match.group(3)!);
          final senderPerson = match.group(4)!.trim().replaceAll('You', 'Eu');

          // Găsim alți participanți
          final List<String> peopleInConversation = messages
              .where((msg) => msg.contains(':') && !msg.contains('Mesajele'))
              .map((msg) {
                final parts = msg.split('-');
                return parts.length > 1 ? parts[1].split(':')[0].trim() : '';
              })
              .where((name) => name.isNotEmpty && name != 'You' && name != senderPerson)
              .toSet()
              .toList();

          if (peopleInConversation.length == 1) {
            final recipientPerson = peopleInConversation.first;
            final eventDate = DateTime(year, month, day, 0, 0);
            detectedEvents.add({
              'title': 'Ziua de naștere a lui $recipientPerson',
              'dateTime': eventDate.toIso8601String(),
              'location': '',
              'eventType': 'Zi de naștere'
            });
            LoggerService.info('Detectat ziua de naștere pentru $recipientPerson pe ${eventDate.day}/${eventDate.month}/${eventDate.year}');
          } else {
            // Căutăm mențiuni
            for (final otherMsg in messages) {
              if (otherMsg != message && birthdayMentionRegex.hasMatch(otherMsg)) {
                for (final person in peopleInConversation) {
                  if (otherMsg.contains(person)) {
                    final eventDate = DateTime(year, month, day, 0, 0);
                    detectedEvents.add({
                      'title': 'Ziua de naștere a lui $person',
                      'dateTime': eventDate.toIso8601String(),
                      'location': '',
                      'eventType': 'Zi de naștere'
                    });
                    LoggerService.info('Detectat ziua de naștere pentru $person la ${eventDate.day}/${eventDate.month}/${eventDate.year}');
                    break;
                  }
                }
              }
            }
          }
        } catch (e) {
          LoggerService.error('Eroare la procesarea evenimentului local: $e');
        }
      }
    }

    // Căutăm evenimente de tip întâlnire/ședință/zoom
    final meetingRegex = RegExp(
      r'(?:întâlnire|ședință|meeting|zoom|webinar).*?(la|on|în|at)\s+(\d{1,2})[\/\.\-](\d{1,2})(?:[\/\.\-](\d{4}))?(?:\s+(?:la|at)\s+(\d{1,2})(?::(\d{1,2}))?)?',
      caseSensitive: false,
    );
    for (final message in messages) {
      final match = meetingRegex.firstMatch(message);
      if (match != null) {
        try {
          final day = int.parse(match.group(2)!);
          final month = int.parse(match.group(3)!) - 1;
          final yearStr = match.group(4);
          final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;
          int hour = 12, minute = 0;
          if (match.group(5) != null) {
            hour = int.parse(match.group(5)!);
            if (match.group(6) != null) {
              minute = int.parse(match.group(6)!);
            }
          }
          final eventDate = DateTime(year, month, day, hour, minute);

          // Extragem locația
          String location = '';
          final locationMatch = RegExp(r'(?:la|în|at)\s+([^.,]+)', caseSensitive: false).firstMatch(message);
          if (locationMatch != null) {
            location = locationMatch.group(1)!.trim();
          }

          detectedEvents.add({
            'title': message.contains('zoom') || message.contains('Zoom') ? 'Ședință Zoom' : 'Întâlnire',
            'dateTime': eventDate.toIso8601String(),
            'location': location,
            'eventType': message.contains('zoom') || message.contains('Zoom') ? 'Ședință online' : 'Întâlnire'
          });
        } catch (e) {
          LoggerService.error('Eroare la procesarea întâlnirii: $e');
        }
      }
    }

    return {
      'summary': summary,
      'detectedEvents': detectedEvents
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
          return {
            'summary': data['summary'] ?? 'Nu s-a putut genera rezumatul.',
            'detectedEvents': data['events'] ?? []
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
        
        // Debug output
        if (data['events'] != null) {
          LoggerService.info('API a returnat ${data['events'].length} evenimente');
          for (var event in data['events']) {
            LoggerService.info('Event: ${event['title']} on ${event['dateTime']}');
          }
        } else {
          LoggerService.info('API nu a returnat evenimente');
        }

        return {
          'summary': data['summary'] ?? 'Nu s-a putut genera rezumatul.',
          'detectedEvents': data['events'] ?? []
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
  //   askQuestionViaAI (NOU)
  // =============================
  Future<String> askQuestionViaAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          // Aici trebuie să pui cheia ta reală
          'Authorization': 'Bearer <API_KEY_TAU>'
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-r1-distill-qwen-32b:free",
          "messages": [
            {
              "role": "system",
              "content": "Ești un asistent inteligent care răspunde la întrebări pe baza unor mesaje. Dacă nu ai destule informații, spune clar acest lucru. Răspunde în română."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.7,
          "max_tokens": 800
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final aiResponse = data['choices'][0]['message']['content'] ?? '';
          return aiResponse;
        } else {
          return '';
        }
      } else {
        LoggerService.error('askQuestionViaAI Error: ${response.statusCode}, ${response.body}');
        return '';
      }
    } catch (e) {
      LoggerService.error('Exception in askQuestionViaAI: $e');
      return '';
    }
  }
}

// Funcție de utilitate pentru a compara două numere
int _min(int a, int b) => a < b ? a : b;
