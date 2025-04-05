import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Adresa IP a serverului backend - actualizată pentru localhost
  static const int _timeoutSeconds = 10; // Reducem timeout-ul pentru a detecta erorile mai rapid
  static const String _defaultIp = '192.168.1.132'; // IP-ul implicit - de înlocuit cu cel real
  
  // URL-ul API-ului
  String _baseUrl = 'http://127.0.0.1:3000/api';
  
  // Constructor care permite injectarea unei adrese personalizate (pentru testare)
  ApiService({String? baseUrl}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    
    // Încercăm să încărcăm IP-ul salvat
    _loadSavedIp();
  }
  
  // Încărcăm adresa IP salvată anterior
  Future<void> _loadSavedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('server_ip');
      if (savedIp != null && savedIp.isNotEmpty) {
        updateServerIp(savedIp);
        print('Am încărcat adresa IP salvată: $savedIp');
      } else {
        // Setăm adresa implicită dacă nu există una salvată
        updateServerIp(_defaultIp);
      }
    } catch (e) {
      print('Eroare la încărcarea adresei IP: $e');
    }
  }
  
  // Schimbă adresa IP a serverului și salvează preferința
  Future<void> updateServerIp(String newIp) async {
    _baseUrl = 'http://$newIp:3000/api';
    print('Adresa API actualizată: $_baseUrl');
    
    // Salvăm adresa pentru utilizări viitoare
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', newIp);
    } catch (e) {
      print('Eroare la salvarea adresei IP: $e');
    }
  }
  
  // Generează un mock summary în caz că serverul nu e disponibil
  Map<String, dynamic> _generateMockSummary(List<String> messages) {
    // Afișăm un mesaj clar că folosim date simulate
    print('Folosim sumarizare LOCALĂ pentru că serverul nu e disponibil');
    
    if (messages.isEmpty) {
      return {
        'summary': 'Nu există mesaje disponibile pentru sumarizare.',
        'detectedEvents': []
      };
    }
    
    // Creăm lista de participanți
    final Set<String> uniquePeople = {};
    for (final message in messages) {
      final parts = message.split(':');
      if (parts.length >= 1) {
        uniquePeople.add(parts[0].trim());
      }
    }
    
    // Extragem câteva mesaje pentru sumar
    final List<String> messageExamples = [];
    for (int i = 0; i < min(5, messages.length); i++) {
      final parts = messages[i].split(':');
      if (parts.length >= 2) {
        final name = parts[0].trim();
        final messageText = parts.sublist(1).join(':').trim();
        messageExamples.add('$name: "$messageText"');
      }
    }
    
    // Generăm sumar sub formă de buletine de știri
    String summary = '';
    
    // Dacă avem exemple de mesaje
    if (messageExamples.isNotEmpty) {
      summary = 'În această conversație:\n\n';
      for (final example in messageExamples) {
        summary += '• $example\n';
      }
      
      if (messages.length > messageExamples.length) {
        summary += '\n... și alte ${messages.length - messageExamples.length} mesaje.';
      }
    } else {
      // Caz de rezervă
      summary = 'În această conversație, ${uniquePeople.join(' și ')} au schimbat ${messages.length} mesaje.';
    }
    
    // Detectăm evenimente locale
    final List<Map<String, dynamic>> detectedEvents = [];
    
    // Căutăm mesaje cu "La mulți ani"
    final birthdayRegex = RegExp(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4}),\s+\d{1,2}:\d{2}\s+\-\s+([^:]+):\s+La\s+mulți\s+ani', caseSensitive: false);
    final birthdayMentionRegex = RegExp(r'zile?(\s+de)?\s+na[șs]tere', caseSensitive: false);
    
    // Prim pas: verificăm mențiuni directe de tipul "La mulți ani"
    for (final message in messages) {
      final match = birthdayRegex.firstMatch(message);
      if (match != null) {
        try {
          final day = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!) - 1; // JS months are 0-indexed
          final year = int.parse(match.group(3)!);
          final senderPerson = match.group(4)!.trim().replaceAll('You', 'Eu');
          
          // Determine the person receiving the birthday wishes
          final List<String> peopleInConversation = messages
            .where((msg) => msg.contains(':') && !msg.contains('Mesajele'))
            .map((msg) {
              final parts = msg.split('-');
              return parts.length > 1 ? parts[1].split(':')[0].trim() : '';
            })
            .where((name) => name.isNotEmpty && name != 'You' && name != senderPerson)
            .toSet()
            .toList();
          
          // Dacă avem doar o persoană în conversație, e simplu
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
          }
          // Altfel, căutăm în mesaje pentru a identifica persoana
          else {
            // Verificăm dacă există un mesaj care menționează ziua de naștere
            for (final otherMsg in messages) {
              if (otherMsg != message && birthdayMentionRegex.hasMatch(otherMsg)) {
                // Extragem numele persoanelor menționate în acest mesaj
                for (final person in peopleInConversation) {
                  if (otherMsg.contains(person)) {
                    final eventDate = DateTime(year, month, day, 0, 0);
                    
                    detectedEvents.add({
                      'title': 'Ziua de naștere a lui $person',
                      'dateTime': eventDate.toIso8601String(),
                      'location': '',
                      'eventType': 'Zi de naștere'
                    });
                    
                    print('Detectat ziua de naștere pentru $person pe ${eventDate.day}/${eventDate.month}/${eventDate.year}');
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
    
    // Căutăm și alte tipuri de evenimente (întâlniri, ședințe)
    final meetingRegex = RegExp(r'(?:întâlnire|ședință|meeting|zoom|webinar).*?(la|on|în|at)\s+(\d{1,2})[\/\.\-](\d{1,2})(?:[\/\.\-](\d{4}))?(?:\s+(?:la|at)\s+(\d{1,2})(?::(\d{1,2}))?)?', caseSensitive: false);
    
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
          
          // Extract location if mentioned
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
          print('Eroare la procesarea evenimentului de întâlnire: $e');
        }
      }
    }
    
    return {
      'summary': summary,
      'detectedEvents': detectedEvents
    };
  }
  
  // Metoda pentru a sumariza mesajele
  Future<Map<String, dynamic>> summarizeMessages(List<String> messages) async {
    // Încercarea 1: localhost folosind 127.0.0.1 (prioritate)
    String localIp = 'http://127.0.0.1:3000/api';
    print('Se încearcă API-ul pe: $localIp/summarize');
    
    try {
      // Încercăm localhost prima dată
      final response = await http.post(
        Uri.parse('$localIp/summarize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': messages,
          'language': 'ro', // Limba în care dorim sumarul
        }),
      ).timeout(Duration(seconds: 3)); // Timeout redus pentru localhost
      
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
    
    // Încercarea 2: folosim adresa IP salvată
    print('Se apelează API-ul de sumarizare la $_baseUrl/summarize');
    print('Număr de mesaje trimise: ${messages.length}');
    
    try {
      // Încercăm să apelăm API-ul cu IP-ul salvat
      final response = await http.post(
        Uri.parse('$_baseUrl/summarize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': messages,
          'language': 'ro', // Limba în care dorim sumarul
        }),
      ).timeout(Duration(seconds: _timeoutSeconds));
      
      if (response.statusCode == 200) {
        print('Sumarizare reușită de la API!');
        final data = jsonDecode(response.body);
        
        // Verificăm dacă sumarul este gol sau lipsește
        if (data['summary'] == null || data['summary'].toString().trim().isEmpty) {
          print('API a returnat un sumar gol, folosim sumarizare locală');
          return _generateMockSummary(messages);
        }
        
        // Convertim eventurile din JSON în obiecte dacă există
        if (data['detectedEvents'] != null && data['detectedEvents'] is List) {
          final List<dynamic> eventsList = data['detectedEvents'];
          final List<Map<String, dynamic>> formattedEvents = [];
          
          for (final event in eventsList) {
            if (event is Map<String, dynamic>) {
              formattedEvents.add(event);
            }
          }
          
          // Actualizăm data cu evenimentele formatate
          data['detectedEvents'] = formattedEvents;
        } else {
          // Asigurăm-ne că avem întotdeauna o listă de evenimente, chiar dacă e goală
          data['detectedEvents'] = [];
        }
        
        return data;
      } else {
        // Afișăm detalii despre eroare
        print('Eroare API (${response.statusCode}): ${response.body}');
        
        // Folosim sumarizare locală ca fallback
        return _generateMockSummary(messages);
      }
    } catch (e) {
      // În caz de eroare de conexiune sau timeout, folosim sumarizare locală
      print('Excepție la apelarea API-ului: $e');
      return _generateMockSummary(messages);
    }
  }
}

// Funcție utilitară min pentru a compara numere
int min(int a, int b) => a < b ? a : b; 