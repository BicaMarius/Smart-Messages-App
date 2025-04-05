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
      return {'summary': 'Nu există mesaje disponibile pentru sumarizare.'};
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
    
    return {'summary': summary};
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