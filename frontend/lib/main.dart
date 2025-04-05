import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/message_processor.dart';
import 'package:frontend/services/calendar_service.dart';
import 'package:frontend/models/message_summary.dart';
import 'package:frontend/screens/advanced_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class SocialMediaPlatform {
  final String name;
  final IconData icon;
  final Color iconColor;
  
  SocialMediaPlatform({
    required this.name,
    required this.icon,
    required this.iconColor,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final MessageProcessor _messageProcessor = MessageProcessor();
  final CalendarService _calendarService = CalendarService();
  
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPageIndex = 0;
  
  // Define social media platforms
  final List<SocialMediaPlatform> _platforms = [
    SocialMediaPlatform(
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      iconColor: Colors.pinkAccent,
    ),
    SocialMediaPlatform(
      name: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      iconColor: Colors.green,
    ),
    SocialMediaPlatform(
      name: 'Messenger',
      icon: FontAwesomeIcons.facebookMessenger,
      iconColor: Colors.blue,
    ),
  ];
  
  List<MessageSummary> _unreadSummaries = [];
  
  // Map to store platform-specific detected events
  Map<String, List<EventDetails>> _platformEvents = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };
  
  // Track which events have been added to calendar
  Map<String, Map<int, bool>> _eventAddedToCalendar = {
    'Instagram': {},
    'WhatsApp': {},
    'Messenger': {},
  };
  
  bool _isLoading = false;
  
  // Advanced Summary variables
  List<String> _uploadedFilePaths = [];
  List<String> _availablePeople = []; // Removed sample data
  String? _selectedPerson;
  DateTime? _selectedDate;
  String? _conversationSummary;
  bool _isSummarizing = false;
  Map<String, List<DateTime>> _personDates = {};

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Request calendar permissions early
    await _calendarService.requestPermissions();
    
    // Load saved files
    await _loadSavedFiles();
    
    // Fetch messages
    _fetchMessages();
  }
  
  Future<void> _loadSavedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFiles = prefs.getStringList('uploadedFiles') ?? [];
      final savedPeople = prefs.getStringList('availablePeople') ?? [];
      
      if (savedFiles.isNotEmpty) {
        setState(() {
          _uploadedFilePaths = savedFiles;
          if (savedPeople.isNotEmpty) {
            _availablePeople = savedPeople;
          }
        });
      }
      
      // Încărcăm și datele de conversație
      await _loadConversationData();
    } catch (e) {
      print('Error loading saved files: $e');
    }
  }
  
  Future<void> _saveFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('uploadedFiles', _uploadedFilePaths);
      await prefs.setStringList('availablePeople', _availablePeople);
    } catch (e) {
      print('Error saving files: $e');
    }
  }
  
  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Using mock data instead of API call
      setState(() {
        _unreadSummaries = [
          MessageSummary(summary: 'Alice Johnson: "Hey, are you free to meet tomorrow at 3pm?"'),
          MessageSummary(summary: 'Bob Smith: "The meeting is set on Friday at 10am."'),
        ];
        
        // Clear WhatsApp events as requested, but keep Instagram and Messenger mock events
        _platformEvents = {
          'Instagram': [
            EventDetails(
              title: 'Photo Shoot',
              dateTime: DateTime.now().add(const Duration(days: 3, hours: 14)),
              location: 'Downtown Studio',
            ),
            EventDetails(
              title: 'Instagram Live',
              dateTime: DateTime.now().add(const Duration(days: 5, hours: 18)),
              location: 'online',
            ),
          ],
          'WhatsApp': [], // No hardcoded events for WhatsApp as requested
          'Messenger': [
            EventDetails(
              title: 'Team Chat',
              dateTime: DateTime.now().add(const Duration(days: 1, hours: 9)),
              location: 'online',
            ),
            EventDetails(
              title: 'Family Group Call',
              dateTime: DateTime.now().add(const Duration(days: 4, hours: 20)),
              location: 'online',
            ),
          ],
        };
        
        // Initialize all events as not added to calendar
        _eventAddedToCalendar = {
          'Instagram': {
            for (int i = 0; i < _platformEvents['Instagram']!.length; i++) i: false
          },
          'WhatsApp': {},
          'Messenger': {
            for (int i = 0; i < _platformEvents['Messenger']!.length; i++) i: false
          },
        };
      });
    } catch (e) {
      print('Error: $e');
      // Fallback data in case something goes wrong
      setState(() {
        _unreadSummaries = [
          MessageSummary(summary: 'Alice Johnson: "Hey, are you free to meet tomorrow at 3pm?"'),
          MessageSummary(summary: 'Bob Smith: "The meeting is set on Friday at 10am."'),
        ];
        
        // Clear WhatsApp events, keep mock data for others
        _platformEvents = {
          'Instagram': [
            EventDetails(
              title: 'Photo Shoot',
              dateTime: DateTime.now().add(const Duration(days: 3, hours: 14)),
              location: 'Downtown Studio',
            ),
          ],
          'WhatsApp': [], // No hardcoded events
          'Messenger': [
            EventDetails(
              title: 'Team Chat',
              dateTime: DateTime.now().add(const Duration(days: 1, hours: 9)),
              location: 'online',
            ),
          ],
        };
        
        // Initialize all events as not added to calendar
        _eventAddedToCalendar = {
          'Instagram': {
            for (int i = 0; i < _platformEvents['Instagram']!.length; i++) i: false
          },
          'WhatsApp': {},
          'Messenger': {
            for (int i = 0; i < _platformEvents['Messenger']!.length; i++) i: false
          },
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleEventCalendar(String platform, int index, EventDetails event) async {
    // If event is already added to calendar, remove it
    if (_eventAddedToCalendar[platform]?[index] == true) {
      // Folosim noua metodă pentru a șterge efectiv evenimentul din calendar
      final success = await _calendarService.removeEventWithConfirmation(context, event);
      
      if (success) {
        setState(() {
          _eventAddedToCalendar[platform]![index] = false;
        });
      } else {
        // Dacă ștergerea a eșuat, afișăm un mesaj și nu schimbăm starea
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eroare la ștergerea evenimentului din calendar'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // First ensure we have calendar permissions
    final hasPermissions = await _calendarService.requestPermissions();
    
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendar permissions are required to add events'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final success = await _calendarService.addEventWithCalendarSelection(context, event);
    
    if (success) {
      setState(() {
        _eventAddedToCalendar[platform]![index] = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event added to calendar'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Advanced Summary methods
  Future<void> _openFileManager() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Uploaded Files',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickFile();
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Add new file'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_uploadedFilePaths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recent files:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  ..._uploadedFilePaths.map((path) => ListTile(
                    leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                    title: Text(path.split('/').last, style: GoogleFonts.poppins()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteFile(path);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Load the selected file
                      _processUploadedFile(path);
                    },
                  )).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      // Folosim file_picker pentru a selecta fișierul
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          // Adăugăm calea fișierului la lista de fișiere încărcate
          _uploadedFilePaths.add(file.path!);
        });
        
        // Salvăm fișierele încărcate
        await _saveFiles();
        
        // Analizăm fișierul pentru a obține date reale
        await _parseFile(file.path!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fișierul ${file.name} a fost încărcat cu succes'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Eroare la selectarea fișierului: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la încărcarea fișierului: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _processUploadedFile(String path) {
    // Analizăm fișierul selectat pentru a extrage conversațiile
    _parseFile(path).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fișier încărcat cu succes: ${path.split('/').last}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la procesarea fișierului: $error'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
  
  Future<void> _selectPerson(String? person) async {
    if (person == null) return;
    
    setState(() {
      _selectedPerson = person;
      _selectedDate = null;
      _conversationSummary = null;
      
      // Filter available dates for the selected person
      if (_personDates.containsKey(person)) {
        print('Found ${_personDates[person]!.length} dates for $person');
      } else {
        print('No dates found for $person');
      }
    });
  }
  
  Future<void> _selectDate() async {
    if (_selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a person first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final availableDates = _personDates[_selectedPerson!] ?? [];
    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No dates available for this person'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Date for $_selectedPerson',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: CalendarDatePicker(
              initialDate: availableDates.first,
              firstDate: availableDates.last,
              lastDate: availableDates.first,
              selectableDayPredicate: (DateTime day) {
                // Only allow dates that have conversations for the selected person
                return _personDates[_selectedPerson!]?.any((date) =>
                  date.year == day.year &&
                  date.month == day.month &&
                  date.day == day.day
                ) ?? false;
              },
              onDateChanged: (DateTime date) {
                Navigator.pop(context);
                setState(() {
                  _selectedDate = date;
                  _generateSummary();
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }
  
  void _generateLocalSummary(List<String> messagesForDate, List<String> apiMessages) {
    final List<String> cleanMessages = [];
    
    for (final message in messagesForDate) {
      final nameMatch = RegExp(r' - ([^:]+):').firstMatch(message);
      final contentMatch = RegExp(r': (.+)$').firstMatch(message);
      
      if (nameMatch != null && contentMatch != null) {
        final name = nameMatch.group(1)!.trim();
        final content = contentMatch.group(1)!.trim();
        
        // Skip system messages and calls
        if (!name.contains('Mesajele') && 
            !name.contains('criptat') && 
            !content.contains('fișier atașat') && 
            !content.contains('Apel pierdut') &&
            !content.contains('Apel neprimit')) {
          cleanMessages.add('$name: $content');
        }
      }
    }
    
    setState(() {
      _isSummarizing = false;
      if (cleanMessages.isNotEmpty) {
        _conversationSummary = 'Nu s-a putut genera un rezumat detaliat. Vă rugăm verificați conexiunea la server și încercați din nou.';
      } else {
        _conversationSummary = 'Nu există mesaje disponibile pentru sumarizare.';
      }
    });
  }

  Future<void> _generateSummary() async {
    if (_selectedPerson == null || _selectedDate == null) return;
    
    setState(() {
      _isSummarizing = true;
      _conversationSummary = null;
    });
    
    try {
      if (_uploadedFilePaths.isEmpty) {
        throw Exception('Nu există fișiere încărcate');
      }
      
      final selectedDateObj = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final messagesForDate = _conversationMessages[selectedDateObj];
      
      if (messagesForDate == null || messagesForDate.isEmpty) {
        throw Exception('Nu există mesaje pentru data selectată');
      }
      
      // Prepare messages for the API
      final List<String> apiMessages = [];
      
      for (final message in messagesForDate) {
        final nameMessageMatch = RegExp(r' - ([^:]+): (.+)$').firstMatch(message);
        if (nameMessageMatch != null && nameMessageMatch.groupCount >= 2) {
          final name = nameMessageMatch.group(1)!.trim();
          final messageText = nameMessageMatch.group(2)!.trim();
          
          // Skip system messages and calls
          if (!name.contains('Mesajele') && 
              !name.contains('criptat') && 
              !messageText.contains('Apel pierdut') &&
              !messageText.contains('Apel neprimit') &&
              !messageText.contains('fișier atașat')) {
            apiMessages.add(message); // Trimitem mesajul complet, inclusiv data
          }
        }
      }
      
      if (apiMessages.isEmpty) {
        throw Exception('Nu am putut extrage mesaje valide din conversație');
      }
      
      // Call the API for summarization
      try {
        print('Trimit ${apiMessages.length} mesaje către API pentru sumarizare și detecția evenimentelor');
        final apiResult = await _apiService.summarizeMessages(apiMessages);
        
        // Procesăm evenimentele detectate
        List<EventDetails> detectedEvents = [];
        if (apiResult['detectedEvents'] != null && apiResult['detectedEvents'] is List) {
          final List<dynamic> eventsList = apiResult['detectedEvents'];
          print('API a returnat ${eventsList.length} evenimente detectate');
          
          for (final event in eventsList) {
            if (event is Map<String, dynamic>) {
              try {
                final eventTitle = event['title'] ?? 'Eveniment nedefinit';
                final eventDateTime = DateTime.parse(event['dateTime']);
                final eventLocation = event['location'] ?? '';
                final eventType = event['eventType'] ?? '';
                
                print('Procesez eveniment: $eventTitle, data: ${eventDateTime.toString()}, tip: $eventType');
                
                detectedEvents.add(EventDetails(
                  title: eventTitle,
                  dateTime: eventDateTime,
                  location: eventLocation,
                ));
              } catch (e) {
                print('Eroare la parsarea evenimentului: $e');
              }
            }
          }
          
          // Actualizăm evenimentele WhatsApp cu cele detectate
          print('Am procesat ${detectedEvents.length} evenimente pentru afișare');
          setState(() {
            _platformEvents['WhatsApp'] = detectedEvents;
            
            // Actualizăm statusul de adăugare în calendar
            _eventAddedToCalendar['WhatsApp'] = {
              for (int i = 0; i < detectedEvents.length; i++) i: false
            };
          });
        } else {
          print('API-ul nu a returnat evenimente sau lista este null');
        }
        
        setState(() {
          _isSummarizing = false;
          _conversationSummary = apiResult['summary'];
        });
      } catch (apiError) {
        print('Eroare la apelarea API-ului: $apiError');
        _generateLocalSummary(messagesForDate, apiMessages);
      }
    } catch (e) {
      print('Eroare la generarea sumarului: $e');
      
      final selectedDateObj = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final messagesForDate = _conversationMessages[selectedDateObj];
      
      if (messagesForDate != null && messagesForDate.isNotEmpty) {
        _generateLocalSummary(messagesForDate, []);
      } else {
        setState(() {
          _isSummarizing = false;
          _conversationSummary = 'Nu există mesaje disponibile pentru sumarizare.';
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la generarea sumarului: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _parseFile(String path) async {
    try {
      // Citim conținutul fișierului
      final file = File(path);
      if (!await file.exists()) {
        print('Fișierul nu există: $path');
        return;
      }
      
      // Extragem numele din calea fișierului
      final fileName = path.split('/').last.split('\\').last;
      print('Nume fișier: $fileName');
      
      // Încercăm să extragem numele conversației din titlul fișierului
      String conversationName = '';
      final conversationMatch = RegExp(r'Conversație WhatsApp cu ([^.]+)').firstMatch(fileName);
      if (conversationMatch != null && conversationMatch.groupCount >= 1) {
        conversationName = conversationMatch.group(1)!.trim();
        print('Nume conversație identificat: $conversationName');
      } else {
        // Dacă nu găsim în format standard, încercăm alt format sau folosim numele fișierului
        conversationName = fileName.replaceAll(RegExp(r'\.(txt|json|csv)$'), '');
        print('Folosim nume fișier ca nume conversație: $conversationName');
      }
      
      // Skip if the conversation name is "Bica Marius"
      if (conversationName.trim() == "Bica Marius") {
        print('Skipping Bica Marius conversation');
        return;
      }
      
      // Citim toate liniile fișierului
      final lines = await file.readAsLines();
      print('Am citit ${lines.length} linii din fișier');
      
      // Pentru WhatsApp, căutăm linii în format "DD.MM.YYYY, HH:MM - nume: mesaj"
      final Set<DateTime> extractedDates = {};
      final Map<DateTime, List<String>> dateMessages = {};
      
      DateTime currentDate = DateTime.now();
      
      for (final line in lines) {
        // Verificăm dacă linia conține o dată (formatul WhatsApp "DD.MM.YYYY, HH:MM")
        final dateMatch = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4}),').firstMatch(line);
        if (dateMatch != null && dateMatch.groupCount >= 3) {
          try {
            int day = int.parse(dateMatch.group(1)!);
            int month = int.parse(dateMatch.group(2)!);
            int year = int.parse(dateMatch.group(3)!);
            
            // Creăm data fără componenta de timp
            currentDate = DateTime(year, month, day);
            
            // Adăugăm data la setul de date extrase
            extractedDates.add(currentDate);
            
            // Inițializăm lista de mesaje pentru această dată dacă nu există deja
            dateMessages.putIfAbsent(currentDate, () => []);
            
            // Adăugăm mesajul la lista de mesaje pentru această dată
            dateMessages[currentDate]!.add(line);
          } catch (e) {
            print('Eroare la parsarea datei: $e');
          }
        } else if (currentDate != null) {
          // Dacă nu am găsit o dată nouă, adăugăm linia la mesajele datei curente
          // (pentru mesaje multi-linie)
          if (dateMessages.containsKey(currentDate)) {
            dateMessages[currentDate]!.add(line);
          }
        }
      }
      
      // Actualizăm starea cu datele extrase
      setState(() {
        // Adăugăm numele conversației la lista existentă (nu înlocuim)
        if (!_availablePeople.contains(conversationName)) {
          _availablePeople.add(conversationName);
        }
        
        print('Conversații disponibile: $_availablePeople');
        
        // Actualizăm datele pentru persoana curentă 
        // (nu ștergem datele pentru celelalte persoane)
        
        // Adăugăm datele extrase pentru conversație
        _personDates[conversationName] = extractedDates.toList();
        // Sortăm datele în ordine descrescătoare (cele mai recente primele)
        _personDates[conversationName]!.sort((a, b) => b.compareTo(a));
        
        print('$conversationName are ${_personDates[conversationName]!.length} date');
        for (final date in _personDates[conversationName]!) {
          print('  - ${date.day}.${date.month}.${date.year} (${dateMessages[date]?.length ?? 0} mesaje)');
        }
        
        // Salvăm și mesajele pentru fiecare dată 
        // Adăugăm la dicționarul existent, nu înlocuim totul
        for (final date in dateMessages.keys) {
          _conversationMessages[date] = dateMessages[date]!;
        }
        
        // Resetăm selecțiile, dar nu ștergem datele
        _selectedPerson = null;
        _selectedDate = null;
        _conversationSummary = null;
      });
      
      // Salvăm prefențele actualizate
      await _saveFiles();
      
      // Stocăm și datele de conversație într-un format serializabil
      await _saveConversationData();
      
      print('Fișierul a fost analizat cu succes');
      print('Conversație identificată: $conversationName cu ${extractedDates.length} date diferite');
    } catch (e) {
      print('Eroare la analiza fișierului: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la analiza fișierului: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Adăugăm o variabilă nouă pentru stocarea mesajelor pentru fiecare dată
  Map<DateTime, List<String>> _conversationMessages = {};

  Future<void> _saveConversationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertim datele într-un format care poate fi serializat
      final Map<String, List<String>> serializedData = {};
      
      for (final person in _personDates.keys) {
        serializedData[person] = _personDates[person]!
            .map((date) => '${date.year}-${date.month}-${date.day}')
            .toList();
      }
      
      // Salvăm datele serializate ca JSON
      await prefs.setString('conversationData', jsonEncode(serializedData));
    } catch (e) {
      print('Eroare la salvarea datelor de conversație: $e');
    }
  }
  
  Future<void> _loadConversationData() async {
    try {
      // Here we would load real conversation data from files
      // For now, using simple mock data for WhatsApp only
      
      // Reset person dates for WhatsApp only
      if (_uploadedFilePaths.isNotEmpty && _currentPageIndex == 1) { // 1 is WhatsApp index
        final mockPeople = ['Rareș', 'Andrei', 'Maria', 'Iulia', 'Victor'];
        
        setState(() {
          _availablePeople = mockPeople;
        
          // Create dates for each person
          _personDates = {
            for (final person in mockPeople)
              person: List.generate(
                5,
                (index) => DateTime.now().subtract(Duration(days: index * 3 + _random.nextInt(5))),
              )..sort((a, b) => b.compareTo(a)),  // Sort dates in descending order
          };
        });
      } else {
        // For other platforms, clear the data for now
        if (_currentPageIndex != 1) { // Not WhatsApp
          setState(() {
            _availablePeople = [];
            _personDates = {};
            _selectedPerson = null;
            _selectedDate = null;
            _conversationSummary = null;
          });
        }
      }
    } catch (e) {
      print('Error loading conversation data: $e');
    }
  }

  void _nextPage() {
    if (_currentPageIndex < _platforms.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: _previousPage,
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _platforms[_currentPageIndex].icon,
                  color: _platforms[_currentPageIndex].iconColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Smart message ${_platforms[_currentPageIndex].name}',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
            onPressed: _nextPage,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _platforms.length,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildPlatformPage(index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  Widget _buildPlatformPage(int platformIndex) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(FontAwesomeIcons.clock, size: 32),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time spent today: 1h 30min',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Conversation today: 2',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildDashboardSection(
              'Unread Messages',
              Column(
                children: _unreadSummaries.isEmpty
                    ? [const Text('No unread messages')]
                    : _unreadSummaries.map((summary) => messageRow(
                        summary.summary, 
                        summary.eventDetails != null 
                            ? Colors.orange 
                            : Colors.red,
                      )).toList(),
              ),
            ),
            _buildDashboardSection(
              'Advanced Summary',
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Summary of conversations from selected date',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: () {
                          _openFileManager();
                        },
                      ),
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.calendar, color: Colors.black54),
                        onPressed: () {
                          if (_uploadedFilePaths.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please upload files first'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _selectDate();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            isDense: true,
                          ),
                          hint: Text(
                            'Select a person',
                            style: GoogleFonts.poppins(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: _selectedPerson,
                          items: _availablePeople.map((person) => DropdownMenuItem<String>(
                            value: person,
                            child: Text(
                              person, 
                              style: GoogleFonts.poppins(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: _selectPerson,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                _selectedDate == null 
                                  ? 'Date' 
                                  : '${_selectedDate!.day}/${_selectedDate!.month}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Conversation Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_conversationSummary != null && !_isSummarizing)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20, color: Colors.blue),
                          onPressed: _generateSummary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200, // Fixed height
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _isSummarizing
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _conversationSummary != null
                        ? SingleChildScrollView(
                            child: Text(
                              _conversationSummary!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _uploadedFilePaths.isEmpty
                                ? 'Upload files first to see conversations'
                                : _selectedPerson == null
                                  ? 'Select a person to see conversation dates'
                                  : _selectedDate == null
                                    ? 'Select a date to see the conversation summary'
                                    : 'No conversation found for the selected date',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            _buildDashboardSection(
              'Detected Events',
              _buildDetectedEventsSection(_platforms[platformIndex].name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(String title, Widget child, {bool showTopBorder = true}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTopBorder)
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: _platforms[_currentPageIndex].iconColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardSection(
            'Summary',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _unreadSummaries.isEmpty
                  ? [const Text('No unread messages')]
                  : List.generate(
                      _unreadSummaries.length,
                      (index) => _buildSummaryRow(_unreadSummaries[index].summary),
                    ),
            ),
          ),
          // Smart Events Section - use the new event panel builder
          _buildDashboardSection(
            'Smart Events',
            _buildEventsPanel(_currentPageIndex),
            showTopBorder: false,
          ),
          _buildAdvancedSummaryButton(),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String summaryText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summaryText,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedSummaryButton() {
    return GestureDetector(
      onTap: () => _navigateToAdvancedSummary(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.insights, color: Colors.blue),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Summary',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get a detailed analysis of your conversations',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }
  
  void _navigateToAdvancedSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedSummaryScreen(),
      ),
    ).then((_) {
      // When returning from the screen, reload data
      _fetchMessages();
      _loadConversationData();
    });
  }

  String _formatEventDetails(EventDetails event) {
    String formattedTime = '';
    if (event.dateTime.hour < 10) {
      formattedTime = '0${event.dateTime.hour}';
    } else {
      formattedTime = '${event.dateTime.hour}';
    }
    
    if (event.dateTime.minute > 0) {
      if (event.dateTime.minute < 10) {
        formattedTime += ':0${event.dateTime.minute}';
      } else {
        formattedTime += ':${event.dateTime.minute}';
      }
    } else {
      formattedTime += ':00';
    }
    
    final String dateStr = '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year}';
    
    if (event.title.toLowerCase().contains('meeting')) {
      return 'Meeting, ora $formattedTime, ${event.location}';
    } else if (event.title.toLowerCase().contains('zoom')) {
      return 'Sedinta Zoom, ora $formattedTime, ${event.location}';
    } else {
      return '${event.title}, ora $formattedTime, ${event.location}';
    }
  }

  Widget buildCard(BuildContext context, {String? title, required Widget child, double? minHeight}) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 120),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }

  Widget messageRow(String message, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.info, color: indicatorColor, size: 16),
        ],
      ),
    );
  }

  Widget eventRow(String text, bool isAdded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isAdded ? Colors.blue : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.add,
              size: 24,
              color: isAdded ? Colors.white : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(String path) async {
    // Identificăm numele conversației din calea fișierului
    final fileName = path.split('/').last.split('\\').last;
    String conversationName = '';
    
    final conversationMatch = RegExp(r'Conversație WhatsApp cu ([^.]+)').firstMatch(fileName);
    if (conversationMatch != null && conversationMatch.groupCount >= 1) {
      conversationName = conversationMatch.group(1)!.trim();
    } else {
      conversationName = fileName.replaceAll(RegExp(r'\.(txt|json|csv)$'), '');
    }
    
    print('Ștergere conversație: $conversationName');
    
    // Ștergem fișierul din lista de fișiere încărcate
    setState(() {
      _uploadedFilePaths.remove(path);
      
      // Verificăm dacă mai există alte fișiere cu același nume de conversație
      bool keepConversation = false;
      for (final remainingPath in _uploadedFilePaths) {
        final remainingFileName = remainingPath.split('/').last.split('\\').last;
        if (remainingFileName.contains(conversationName)) {
          keepConversation = true;
          break;
        }
      }
      
      // Dacă nu mai există alte fișiere cu același nume, ștergem conversația
      if (!keepConversation) {
        // Ștergem persoana din lista de persoane disponibile
        _availablePeople.remove(conversationName);
        
        // Ștergem datele asociate cu persoana
        _personDates.remove(conversationName);
        
        // Resetăm selecția dacă era selectată această persoană
        if (_selectedPerson == conversationName) {
          _selectedPerson = null;
          _selectedDate = null;
          _conversationSummary = null;
        }
      }
    });
    
    // Salvăm lista actualizată de fișiere și persoane
    await _saveFiles();
    await _saveConversationData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fișierul a fost șters cu succes'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _processSelectedConversation() async {
    if (_selectedPerson == null || _selectedDate == null) {
      return;
    }
    
    // Check if we're on WhatsApp tab, otherwise don't proceed
    if (_currentPageIndex != 1) { // 1 is WhatsApp index
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advanced summary is only available for WhatsApp conversations'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() {
      _isSummarizing = true;
      _conversationSummary = null;
    });

    try {
      // In a real app, you would load actual messages for the selected person and date
      // For demo purposes, we'll just generate some mock messages
      final List<String> mockMessages = _generateMockMessages(_selectedPerson!, _selectedDate!);
      
      // Call the API to get a summary
      final apiResult = await _apiService.summarizeMessages(mockMessages);
      
      String summary = apiResult['summary'] ?? 'No summary available.';
      
      // Process detected events if available
      List<EventDetails> detectedEvents = [];
      if (apiResult['detectedEvents'] != null && apiResult['detectedEvents'] is List) {
        final List<dynamic> eventsList = apiResult['detectedEvents'];
        
        for (final event in eventsList) {
          if (event is Map<String, dynamic>) {
            try {
              detectedEvents.add(EventDetails(
                title: event['title'] ?? 'Unnamed Event',
                dateTime: DateTime.parse(event['dateTime']),
                location: event['location'] ?? '',
              ));
            } catch (e) {
              print('Error parsing event: $e');
            }
          }
        }
      }
      
      // Update state with the new summary and events
      setState(() {
        _conversationSummary = summary;
        
        // Update WhatsApp events with detected events
        _platformEvents['WhatsApp'] = detectedEvents;
        
        // Initialize calendar status for new events
        _eventAddedToCalendar['WhatsApp'] = {
          for (int i = 0; i < detectedEvents.length; i++) i: false
        };
      });
    } catch (e) {
      print('Error processing conversation: $e');
      setState(() {
        _conversationSummary = 'Error generating summary: $e';
      });
    } finally {
      setState(() {
        _isSummarizing = false;
      });
    }
  }
  
  // Generate mock messages for testing purposes
  List<String> _generateMockMessages(String person, DateTime date) {
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    final List<String> messages = [];
    
    // Different mock conversations based on the person
    if (person == 'Rareș') {
      messages.addAll([
        '19/03/2023, 10:15 - Rareș: Salut! Cum ești?',
        '19/03/2023, 10:18 - You: Bine, mulțumesc! Tu?',
        '19/03/2023, 10:20 - Rareș: Foarte bine. Auzi, voiam să te întreb dacă ești liber pe 25 Martie.',
        '19/03/2023, 10:22 - You: Pe 25? Da, cred că sunt liber. De ce?',
        '19/03/2023, 10:25 - Rareș: Îmi sărbătoresc ziua de naștere la restaurantul Pietris, la ora 19:00. Mi-ar plăcea să vii și tu!',
        '19/03/2023, 10:26 - You: Cu mare plăcere! Mulțumesc pentru invitație.',
        '19/03/2023, 10:28 - Rareș: Super! O să mai vină și Andrei, Maria și câțiva colegi de la birou.',
        '19/03/2023, 10:30 - You: Perfect! Ne vedem atunci. Să-ți aduc vreun cadou special?',
        '19/03/2023, 10:32 - Rareș: Nu e nevoie de cadouri, doar prezența ta contează. 😊',
      ]);
    } else if (person == 'Maria') {
      messages.addAll([
        '22/03/2023, 09:05 - Maria: Bună dimineața! Ești disponibil pentru o ședință Zoom mâine la 14:30?',
        '22/03/2023, 09:10 - You: Bună! Da, sunt disponibil atunci.',
        '22/03/2023, 09:12 - Maria: Excelent! Voi trimite link-ul de Zoom înainte de ședință.',
        '22/03/2023, 09:15 - Maria: Am de discutat despre proiectul nou.',
        '22/03/2023, 09:18 - You: Perfect, aștept cu interes!',
        '22/03/2023, 14:20 - Maria: Link-ul pentru ședința de la 14:30: https://zoom.us/j/123456789',
      ]);
    } else if (person == 'Andrei') {
      messages.addAll([
        '18/03/2023, 16:00 - Andrei: Hey, vrei să mergem la film sâmbătă?',
        '18/03/2023, 16:05 - You: Sună bine! Ce film ai vrea să vedem?',
        '18/03/2023, 16:08 - Andrei: Se dă noul film Avatar la Cinema City din mall, începe la 18:30.',
        '18/03/2023, 16:10 - You: Perfect! Ne întâlnim acolo la 18:00?',
        '18/03/2023, 16:12 - Andrei: Da, ne vedem la intrare. Iau eu biletele online.',
        '18/03/2023, 16:15 - You: Super, mulțumesc! Ne vedem sâmbătă.',
      ]);
    } else if (person == 'Victor') {
      messages.addAll([
        '21/03/2023, 11:00 - Victor: Salut! Am programat întâlnirea cu clientul pentru joi la ora 10:00 la biroul nostru.',
        '21/03/2023, 11:05 - You: Ok, voi fi acolo. Mulțumesc pentru informare!',
        '21/03/2023, 11:08 - Victor: Te rog să pregătești prezentarea pentru proiectul XYZ.',
        '21/03/2023, 11:10 - You: Am înțeles, o voi avea gata până atunci.',
        '21/03/2023, 11:15 - Victor: Excelent! Și adu și rapoartele financiare, te rog.',
      ]);
    } else if (person == 'Iulia') {
      messages.addAll([
        '20/03/2023, 15:30 - Iulia: Bună! Echipa organizează o ieșire pentru drumeție duminică în Pădurea Băneasa.',
        '20/03/2023, 15:35 - You: Sună interesant! La ce oră?',
        '20/03/2023, 15:38 - Iulia: Ne întâlnim la intrarea în pădure la ora 09:00. Vom face un traseu de aproximativ 3 ore.',
        '20/03/2023, 15:40 - You: Perfect! Vin și eu. Trebuie să aduc ceva?',
        '20/03/2023, 15:43 - Iulia: Doar apă, ceva de ronțăit și încălțăminte comodă. Ne ocupăm noi de restul.',
        '20/03/2023, 15:45 - You: Super, abia aștept!',
      ]);
    } else {
      // Generic conversation for any other person
      messages.addAll([
        '$dateStr, 12:00 - $person: Salut! Ce mai faci?',
        '$dateStr, 12:05 - You: Bine, mulțumesc! Tu?',
        '$dateStr, 12:08 - $person: Foarte bine! Voiam să te întreb dacă ai timp săptămâna viitoare să ne vedem.',
        '$dateStr, 12:10 - You: Sigur! Când ți-ar conveni?',
        '$dateStr, 12:15 - $person: Ce zici de marți la 17:00, la cafeneaua din centru?',
        '$dateStr, 12:18 - You: Perfect pentru mine! Ne vedem atunci.',
      ]);
    }
    
    return messages;
  }

  Widget _buildEventsPanel(int index) {
    final platform = _platforms[index].name;
    final platformColor = _platforms[index].iconColor;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_platforms[index].icon, color: platformColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Detected Events',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _buildDetectedEventsSection(platform),
        ],
      ),
    );
  }
  
  Widget _buildDetectedEventsSection(String platform) {
    final events = _platformEvents[platform] ?? [];
    
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No events detected',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isAdded = _eventAddedToCalendar[platform]?[index] ?? false;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isAdded ? Colors.green.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(event.dateTime),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(event.dateTime),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isAdded ? Icons.event_available : Icons.calendar_month_outlined,
                color: isAdded ? Colors.green : Colors.blue,
              ),
              onPressed: () => _toggleEventCalendar(platform, index, event),
            ),
          ),
        );
      },
    );
  }
}
