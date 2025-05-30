import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/logger_service.dart';

class ApiService {
  static const int _timeoutSeconds = 10;
  static const int _discoveryPort = 3000;
  
  String _baseUrl = 'http://127.0.0.1:3000/api';
  String? _currentServerIp;
  Timer? _discoveryTimer;
  bool _isDiscovering = false;

  ApiService({String? baseUrl}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    _initializeServerDiscovery();
  }

  Future<void> _initializeServerDiscovery() async {
    await _loadSavedIp();
    _startServerDiscovery();
  }

  void _startServerDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDiscovering) {
        _discoverServer();
      }
    });
    _discoverServer();
  }

  Future<void> _discoverServer() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    
    LoggerService.debug('Începem descoperirea serverului...');
    
    // Încercăm mai întâi ultimul IP salvat
    if (_currentServerIp != null) {
      if (await _testServerConnection(_currentServerIp!)) {
        _isDiscovering = false;
        return;
      }
    }

    // Încercăm localhost
    if (await _testServerConnection('127.0.0.1')) {
      _isDiscovering = false;
      return;
    }

    // Încercăm să găsim serverul folosind mDNS
    try {
      final response = await http.get(
        Uri.parse('http://localhost:$_discoveryPort/api/server-info'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 1));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['interfaces'] != null && data['interfaces'].isNotEmpty) {
          for (var iface in data['interfaces']) {
            if (iface['ip'] != null) {
              _currentServerIp = iface['ip'];
              _baseUrl = 'http://${iface['ip']}:${data['port']}/api';
              LoggerService.info('Server găsit la: ${iface['ip']} (${iface['interface']})');
              await _saveServerIp(_currentServerIp!);
              _isDiscovering = false;
              return;
            }
          }
        }
      }
    } catch (e) {
      LoggerService.debug('Nu s-a putut găsi serverul prin mDNS: $e');
    }

    LoggerService.error('Nu s-a putut găsi serverul în rețea');
    _isDiscovering = false;
  }

  Future<bool> _testServerConnection(String ip) async {
    try {
      final url = 'http://$ip:$_discoveryPort/api/server-info';
      LoggerService.debug('Testăm conexiunea la: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 1));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['interfaces'] != null && data['interfaces'].isNotEmpty) {
          for (var iface in data['interfaces']) {
            if (iface['ip'] != null) {
              _currentServerIp = iface['ip'];
              _baseUrl = 'http://${iface['ip']}:${data['port']}/api';
              
              LoggerService.info('Server găsit la: ${iface['ip']} (${iface['interface']})');
              await _saveServerIp(_currentServerIp!);
              return true;
            }
          }
        }
      }
    } catch (e) {
      // Ignorăm erorile de timeout sau conexiune
    }
    return false;
  }

  Future<void> _loadSavedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('server_ip');
      
      if (savedIp != null) {
        _currentServerIp = savedIp;
        _baseUrl = 'http://$savedIp:$_discoveryPort/api';
        LoggerService.debug('IP încărcat din SharedPreferences: $savedIp');
      }
    } catch (e) {
      LoggerService.error('Eroare la încărcarea IP-ului salvat: $e');
    }
  }

  Future<void> _saveServerIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);
      LoggerService.debug('IP salvat în SharedPreferences: $ip');
    } catch (e) {
      LoggerService.error('Eroare la salvarea IP-ului: $e');
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
    final localIp = _currentServerIp ?? _baseUrl.split(':')[1].split('/')[0]; // Adresa IP a serverului local
    
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
      final askUrl = 'http://$_currentServerIp:3000/api/ask';
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
