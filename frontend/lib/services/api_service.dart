import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Adresa IP a serverului backend - implicită, modificabilă ulterior
  static const int _timeoutSeconds = 10; 
  static const String _defaultIp = '192.168.1.132'; // sau IP real

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
        print('Am încărcat adresa IP salvată: $savedIp');
      } else {
        // Dacă nu există IP salvat, folosim IP-ul implicit
        updateServerIp(_defaultIp);
      }
    } catch (e) {
      print('Eroare la încărcarea adresei IP: $e');
    }
  }

  Future<void> updateServerIp(String newIp) async {
    _baseUrl = 'http://$newIp:3000/api';
    print('Adresa API actualizată: $_baseUrl');

    // Salvăm adresa pentru sesiuni viitoare
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', newIp);
    } catch (e) {
      print('Eroare la salvarea adresei IP: $e');
    }
  }

  // ===================================
  //   Fallback local: _generateMockSummary
  // ===================================
  Map<String, dynamic> _generateMockSummary(List<String> messages) {
    print('Folosim sumarizare LOCALĂ pentru că serverul nu e disponibil');

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
            print('Detectat ziua de naștere pentru $recipientPerson pe ${eventDate.day}/${eventDate.month}/${eventDate.year}');
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
                    print('Detectat ziua de naștere pentru $person la ${eventDate.day}/${eventDate.month}/${eventDate.year}');
                    break;
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Eroare la procesarea evenimentului local: $e');
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
          print('Eroare la procesarea întâlnirii: $e');
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
    // 1) Încercăm localhost
    final localIp = 'http://127.0.0.1:3000/api';
    print('Se încearcă API-ul pe: $localIp/summarize');

    try {
      final response = await http
          .post(
            Uri.parse('$localIp/summarize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': messages,
              'language': 'ro',
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        print('Sumarizare reușită de la localhost!');
        final data = jsonDecode(response.body);
        if (data['summary'] == null || data['summary'].toString().trim().isEmpty) {
          print('API localhost a returnat un sumar gol, încercăm IP salvat');
        } else {
          return data;
        }
      }
    } catch (e) {
      print('Localhost indisponibil: $e');
      // Continuăm cu IP-ul salvat
    }

    // 2) Încercăm IP-ul salvat
    print('Se apelează API-ul de sumarizare la $_baseUrl/summarize');
    print('Număr de mesaje trimise: ${messages.length}');

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/summarize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': messages,
              'language': 'ro',
            }),
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        print('Sumarizare reușită de la API!');
        final data = jsonDecode(response.body);

        if (data['summary'] == null || data['summary'].toString().trim().isEmpty) {
          print('API a returnat un sumar gol, folosim sumarizare locală');
          return _generateMockSummary(messages);
        }

        // Convertim eventurile în listă de map
        if (data['detectedEvents'] != null && data['detectedEvents'] is List) {
          final List<dynamic> eventsList = data['detectedEvents'];
          final List<Map<String, dynamic>> formattedEvents = [];
          for (final event in eventsList) {
            if (event is Map<String, dynamic>) {
              formattedEvents.add(event);
            }
          }
          data['detectedEvents'] = formattedEvents;
        } else {
          data['detectedEvents'] = [];
        }

        return data;
      } else {
        print('Eroare API (${response.statusCode}): ${response.body}');
        return _generateMockSummary(messages);
      }
    } catch (e) {
      print('Excepție la apelarea API-ului: $e');
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
        print('askQuestionViaAI Error: ${response.statusCode}, ${response.body}');
        return '';
      }
    } catch (e) {
      print('Exception in askQuestionViaAI: $e');
      return '';
    }
  }
}

// Funcție de utilitate pentru a compara două numere
int _min(int a, int b) => a < b ? a : b;
