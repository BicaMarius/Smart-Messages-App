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
  runApp(const MyApp());
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

/// Model simplu pentru a reprezenta o platformă de social media
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

  /// Definim platformele social media
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

  /// Evenimente detectate pe platformă
  Map<String, List<EventDetails>> _platformEvents = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };

  /// Starea evenimentelor adăugate în calendar
  Map<String, Map<int, bool>> _eventAddedToCalendar = {
    'Instagram': {},
    'WhatsApp': {},
    'Messenger': {},
  };

  bool _isLoading = false;

  // =====================
  //  Avansat: fișiere, persoane, date, rezumat
  // =====================
  Map<String, List<String>> _uploadedFilePathsByPlatform = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };

  Map<String, List<String>> _availablePeopleByPlatform = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };

  Map<String, String?> _selectedPersonByPlatform = {
    'Instagram': null,
    'WhatsApp': null,
    'Messenger': null
  };

  Map<String, DateTime?> _selectedDateByPlatform = {
    'Instagram': null,
    'WhatsApp': null,
    'Messenger': null
  };

  Map<String, String?> _conversationSummaryByPlatform = {
    'Instagram': null,
    'WhatsApp': null,
    'Messenger': null
  };

  Map<String, Map<String, List<DateTime>>> _personDatesByPlatform = {
    'Instagram': {},
    'WhatsApp': {},
    'Messenger': {}
  };

  Map<String, Map<DateTime, List<String>>> _conversationMessagesByPlatform = {
    'Instagram': {},
    'WhatsApp': {},
    'Messenger': {}
  };

  bool _isSummarizing = false;

  // ======================
  //   ASK ME ANYTHING
  //   (UI minimal + logica)
  // ======================
  Map<String, TextEditingController> _askControllers = {
    'Instagram': TextEditingController(),
    'WhatsApp': TextEditingController(),
    'Messenger': TextEditingController()
  };

  /// Mic log de mesaje (opțional, afișăm doar ultimele 3).
  Map<String, List<String>> _askChatLogByPlatform = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };

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
    // Cerem permisiuni de calendar
    await _calendarService.requestPermissions();
    // Încărcăm fișiere salvate
    await _loadSavedFiles();
    // Eliminăm datele hardcodate pentru WhatsApp
    _fetchMessages();
  }

  /// ============================
  ///  Eliminăm datele hardcodate
  ///  pentru WhatsApp
  /// ============================
  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      //  -- Instagram & Messenger pot păstra date exemplu,
      //  -- WhatsApp rămâne gol (fără date hardcodate).
      _platformEvents = {
        'Instagram': [
          // Ex. date exemplu la Instagram
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
        'WhatsApp': [],
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

      _eventAddedToCalendar = {
        'Instagram': {
          for (int i = 0; i < _platformEvents['Instagram']!.length; i++) i: false
        },
        'WhatsApp': {},
        'Messenger': {
          for (int i = 0; i < _platformEvents['Messenger']!.length; i++) i: false
        },
      };
    } catch (e) {
      print('Error in _fetchMessages: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// =================================
  ///  Încărcăm fișiere salvate (logică deja existentă)
  /// =================================
  Future<void> _loadSavedFiles() async {
    // ... codul tău existent ...
    // Ai deja logica ce folosește SharedPreferences
    // pentru a încărca fișiere
  }

  /// ================
  ///   BUILD
  /// ================
  @override
  Widget build(BuildContext context) {
    // Obține culoarea platformei curente pentru a o folosi în întreaga interfață
    final Color platformColor = _platforms[_currentPageIndex].iconColor;
    
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _platforms[_currentPageIndex].icon,
              color: platformColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _platforms[_currentPageIndex].name,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
        selectedItemColor: platformColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
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

  Widget _buildPlatformPage(int platformIndex) {
    final platformName = _platforms[platformIndex].name;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildDashboardSection(
            'Advanced Summary',
            _buildAdvancedSummaryUI(platformName),
          ),
          _buildDashboardSection(
            'Ask Me',
            _buildAskMeUI(platformName),
          ),
          _buildDashboardSection(
            'Detected Events',
            _buildDetectedEventsSection(platformName),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// ===============================
  ///   "Dashboard Section" wrapper
  /// ===============================
  Widget _buildDashboardSection(String title, Widget child) {
    final platformColor = _platforms[_currentPageIndex].iconColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: platformColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: platformColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: platformColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: platformColor.withOpacity(0.9),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  /// ===============================
  ///   Advanced Summary UI
  /// ===============================
  Widget _buildAdvancedSummaryUI(String platformName) {
    final platformColor = _platforms[_currentPageIndex].iconColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Secțiunea de fișiere încărcate
        Row(
          children: [
            Icon(Icons.file_present, color: platformColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Conversation Files',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: platformColor),
              tooltip: 'Upload a file',
              onPressed: () => _openFileManager(platformName),
            ),
          ],
        ),
        
        // Lista de fișiere
        if (_uploadedFilePathsByPlatform[platformName]?.isEmpty == true)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Upload a conversation file to get started.',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: platformColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildUploadedFileList(platformName),
          ),
          
        const Divider(height: 24),
        
        // Secțiunea de selecție persoană și dată
        Row(
          children: [
            Icon(Icons.person_outline, color: platformColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Person & Date',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        
        // Selecție persoană
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
          child: _buildPersonDropdown(platformName),
        ),
        
        // Secțiunea de selectare a datei - doar dacă avem o persoană selectată
        if (_selectedPersonByPlatform[platformName] != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.calendar_today, size: 18, color: platformColor),
                  label: Text(
                    _selectedDateByPlatform[platformName] != null 
                      ? 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDateByPlatform[platformName]!)}'
                      : 'Select a date',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: platformColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showDatePicker(platformName),
                ),
              ),
            ],
          ),
          
        const SizedBox(height: 20),
        
        // Secțiunea de sumarizare - doar dacă avem persoană și dată selectate
        if (_selectedPersonByPlatform[platformName] != null && _selectedDateByPlatform[platformName] != null) ...[
          Row(
            children: [
              Icon(Icons.summarize, color: platformColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Conversation Summary',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (_conversationSummaryByPlatform[platformName] != null && !_isSummarizing)
                IconButton(
                  icon: Icon(Icons.refresh, color: platformColor),
                  tooltip: 'Refresh summary',
                  onPressed: () => _generateSummary(platformName),
                ),
            ],
          ),
          
          // Container pentru sumarizare
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: platformColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: platformColor.withOpacity(0.2)),
            ),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            child: _isSummarizing
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 30, 
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(platformColor),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Generating summary...',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _conversationSummaryByPlatform[platformName] != null
                    ? SingleChildScrollView(
                        child: Text(
                          _cleanupSummary(_conversationSummaryByPlatform[platformName]!),
                          style: GoogleFonts.poppins(height: 1.5),
                        ),
                      )
                    : Center(
                        child: Text(
                          'Summary will appear here',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
          ),
        ],
      ],
    );
  }

  // Funcție pentru a curăța textul sumarizării de evenimente
  String _cleanupSummary(String summary) {
    // Înlătură secțiunile cu EVENIMENTE_DETECTATE sau similare
    if (summary.contains('EVENIMENTE_DETECTATE') || summary.contains('EVENTS_DETECTED')) {
      final parts = summary.split(RegExp(r'EVENIMENTE_DETECTATE|EVENTS_DETECTED'));
      return parts[0].trim();
    }
    return summary;
  }

  // Funcție pentru afișarea selectorului de date
  void _showDatePicker(String platformName) {
    final platformColor = _platforms[_currentPageIndex].iconColor;
    final selectedPerson = _selectedPersonByPlatform[platformName];
    
    if (selectedPerson == null) return;
    
    final dates = _personDatesByPlatform[platformName]?[selectedPerson] ?? [];
    if (dates.isEmpty) return;
    
    // Sortează datele
    dates.sort();
    final initialDate = _selectedDateByPlatform[platformName] ?? dates.first;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Date',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: platformColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available dates for $selectedPerson',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: CalendarDatePicker(
                  initialDate: initialDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2026),
                  onDateChanged: (date) {
                    Navigator.pop(context);
                    setState(() {
                      _selectedDateByPlatform[platformName] = date;
                      _conversationSummaryByPlatform[platformName] = null;
                    });
                    // Generează automat rezumatul după selectarea datei
                    _generateSummary(platformName);
                  },
                  selectableDayPredicate: (day) {
                    return dates.any((date) => 
                      date.year == day.year && 
                      date.month == day.month && 
                      date.day == day.day
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Mici ajustări la lista de fișiere pentru un aspect mai elegant
  Widget _buildUploadedFileList(String platformName) {
    final fileList = _uploadedFilePathsByPlatform[platformName] ?? [];
    final platformColor = _platforms[_currentPageIndex].iconColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fileList.map((filePath) {
        final fileName = filePath.split('/').last;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file, 
                color: platformColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: GoogleFonts.poppins(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteFile(platformName, filePath),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.visibility_outlined, color: platformColor, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'View file details',
                onPressed: () => _processUploadedFile(platformName, filePath),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // Modificăm și această funcție pentru a actualiza automat sumarul când se schimbă persoana
  Widget _buildPersonDropdown(String platformName) {
    final platformColor = _platforms[_currentPageIndex].iconColor;
    final people = _availablePeopleByPlatform[platformName] ?? [];
    
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: platformColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: platformColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: platformColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: Icon(Icons.person, color: platformColor.withOpacity(0.7), size: 18),
      ),
      icon: Icon(Icons.arrow_drop_down, color: platformColor),
      hint: Text('Select a person', style: GoogleFonts.poppins(fontSize: 13)),
      value: _selectedPersonByPlatform[platformName],
      items: people.map((person) {
        return DropdownMenuItem<String>(
          value: person,
          child: Text(
            person,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPersonByPlatform[platformName] = value;
          _selectedDateByPlatform[platformName] = null;
          _conversationSummaryByPlatform[platformName] = null;
        });
      },
    );
  }

  /// =======================================
  ///   Secțiunea "Ask Me" - Minimal UI + logic
  /// =======================================
  Widget _buildAskMeUI(String platformName) {
    final platformColor = _platforms[_currentPageIndex].iconColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask me about this conversation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: platformColor.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _askControllers[platformName],
                  decoration: InputDecoration(
                    hintText: 'Type your question...',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  style: GoogleFonts.poppins(fontSize: 13),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _askQuestion(platformName, value.trim());
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final text = _askControllers[platformName]!.text.trim();
                if (text.isNotEmpty) {
                  _askQuestion(platformName, text);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: platformColor,
              ),
              child: const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Afișăm ultimele 3 mesaje din chat (dacă există)
        if (_askChatLogByPlatform[platformName]?.isNotEmpty == true)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: platformColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _askChatLogByPlatform[platformName]!
                  .take(3)
                  .toList()
                  .reversed
                  .map((msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          msg,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  /// Caută răspunsul pornind de la data selectată (dacă e setată) sau de la toată conversația cu persoana
  void _askQuestion(String platformName, String question) {
    // Golește input
    _askControllers[platformName]!.clear();

    final person = _selectedPersonByPlatform[platformName];
    if (person == null) {
      setState(() {
        _askChatLogByPlatform[platformName]!
            .insert(0, 'AI: Select a person first!');
      });
      return;
    }

    // Adăugăm întrebarea user-ului în chat
    setState(() {
      _askChatLogByPlatform[platformName]!.insert(0, 'You: $question');
    });

    final selectedDate = _selectedDateByPlatform[platformName];

    // Adunăm toate mesajele relevante
    List<String> relevantMessages = [];
    if (selectedDate != null) {
      // doar ziua selectată
      relevantMessages = _conversationMessagesByPlatform[platformName]?[selectedDate] ?? [];
    } else {
      // toate zilele cu persoana aleasă
      final dates = _personDatesByPlatform[platformName]?[person] ?? [];
      for (final date in dates) {
        final msgs = _conversationMessagesByPlatform[platformName]?[date] ?? [];
        relevantMessages.addAll(msgs);
      }
    }

    if (relevantMessages.isEmpty) {
      setState(() {
        _askChatLogByPlatform[platformName]!
            .insert(0, 'AI: No messages found for $person.'); 
      });
      return;
    }

    // Construim promptul
    final limitedMessages = relevantMessages.take(40).join('\n');
    final prompt = """
Ai următoarele mesaje între tine și $person:
$limitedMessages

Întrebare: $question
Răspunde concis în limba română. Dacă nu există suficiente informații, spune că nu ai destule date.
""";

    // Apel către API
    _apiService.askQuestionViaAI(prompt).then((answer) {
      if (answer.trim().isEmpty) {
        setState(() {
          _askChatLogByPlatform[platformName]!
              .insert(0, 'AI: Nu am destule informații pentru a răspunde.');
        });
      } else {
        setState(() {
          _askChatLogByPlatform[platformName]!.insert(0, 'AI: $answer');
        });
      }
    }).catchError((err) {
      print('Eroare la askQuestionViaAI: $err');
      setState(() {
        _askChatLogByPlatform[platformName]!
            .insert(0, 'AI: Eroare la căutarea răspunsului.');
      });
    });
  }

  /// =========================================
  ///  Evenimente detectate (UI)
  /// =========================================
  Widget _buildDetectedEventsSection(String platform) {
    final events = _platformEvents[platform] ?? [];

    if (events.isEmpty) {
      return Center(
        child: Text(
          'No events detected',
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            title: Text(
              event.title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime),
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (event.location.isNotEmpty)
                  Text(
                    'Locație: ${event.location}',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isAdded ? Icons.event_available : Icons.event,
                color: isAdded ? Colors.green : Colors.blue,
              ),
              onPressed: () => _toggleEventCalendar(platform, index, event),
            ),
          ),
        );
      },
    );
  }

  /// Calendar: Adaugă / Șterge eveniment
  Future<void> _toggleEventCalendar(String platform, int index, EventDetails event) async {
    if (_eventAddedToCalendar[platform]?[index] == true) {
      // Ștergem eveniment
      final success = await _calendarService.removeEventWithConfirmation(context, event);
      if (success) {
        setState(() {
          _eventAddedToCalendar[platform]![index] = false;
        });
      }
      return;
    }

    // Adăugăm eveniment
    final success = await _calendarService.addEventWithCalendarSelection(context, event);
    if (success) {
      setState(() {
        _eventAddedToCalendar[platform]![index] = true;
      });
    }
  }

  /// Generare rezumat la cerere
  Future<void> _generateSummary(String platform) async {
    final platformColor = _platforms[_currentPageIndex].iconColor;
    final person = _selectedPersonByPlatform[platform];
    final date = _selectedDateByPlatform[platform];
    if (person == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a person first'),
          backgroundColor: platformColor,
        ),
      );
      return;
    }
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a date for this conversation'),
          backgroundColor: platformColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isSummarizing = true;
      _conversationSummaryByPlatform[platform] = null;
    });

    try {
      final messages = _conversationMessagesByPlatform[platform]?[date] ?? [];
      if (messages.isEmpty) {
        throw Exception('No messages found for $person on selected date.');
      }

      final summaryData = await _apiService.summarizeMessages(messages);
      setState(() {
        _conversationSummaryByPlatform[platform] = summaryData['summary'];
      });

      // Prelucrăm evenimentele detectate
      final List<dynamic> eventsList = summaryData['detectedEvents'] ?? [];
      final List<EventDetails> detectedEvents = [];
      for (final e in eventsList) {
        if (e is Map) {
            try {
              detectedEvents.add(EventDetails(
              title: e['title'] ?? 'Untitled Event',
              dateTime: DateTime.parse(e['dateTime']),
              location: e['location'] ?? '',
            ));
          } catch (_) {}
        }
      }

      setState(() {
        _platformEvents[platform] = detectedEvents;
        _eventAddedToCalendar[platform] = {
          for (int i = 0; i < detectedEvents.length; i++) i: false
        };
      });
    } catch (error) {
      print('Error in _generateSummary: $error');
      setState(() {
        _conversationSummaryByPlatform[platform] =
            'Error generating summary: $error';
      });
    } finally {
      setState(() {
        _isSummarizing = false;
      });
    }
  }

  /// ================
  ///   Manager fișiere
  /// ================
  void _openFileManager(String platformName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$platformName Files', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                          _pickFile(platformName);
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
                const SizedBox(height: 16),
                if (_uploadedFilePathsByPlatform[platformName]?.isNotEmpty == true)
                  ..._uploadedFilePathsByPlatform[platformName]!.map((path) => ListTile(
                        leading: Icon(Icons.insert_drive_file, color: _platforms[_currentPageIndex].iconColor),
                        title: Text(path.split('/').last, style: GoogleFonts.poppins()),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteFile(platformName, path);
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _processUploadedFile(platformName, path);
                        },
                      )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFile(String platformName) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _uploadedFilePathsByPlatform[platformName]!.add(file.path!);
        });
        // Salvezi preferințe, parsezi fișierul...
        // Apel la parseFile
        await _parseFile(file.path!, platformName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File ${file.name} uploaded for $platformName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _processUploadedFile(String platform, String path) {
    // Apelează parseFile, reîmprospătezi UI etc.
    _parseFile(path, platform).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File opened: ${path.split('/').last}'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _deleteFile(String platform, String path) async {
    setState(() {
      _uploadedFilePathsByPlatform[platform]?.remove(path);
      // Ștergem persoana + datele dacă nu mai există fișiere cu aceeași conversație
    });
    // Salvezi preferințe actualizate, reîmprospătezi ecranul
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File deleted: ${path.split('/').last}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _parseFile(String path, String platform) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      String content = await file.readAsString();
      
      // Extrage numele fișierului
      String fileName = path.split('/').last;
      
      // Verificăm dacă este o conversație WhatsApp
      if (platform == 'WhatsApp' && (fileName.contains('WhatsApp') || content.contains('Mesajele și apelurile sunt criptate integral'))) {
        await _parseWhatsAppConversation(content, platform, fileName);
      } 
      // Pentru Instagram
      else if (platform == 'Instagram') {
        // Implementează parsarea specifică pentru Instagram
        // (Deocamdată folosim un nume generic)
        String personName = 'Instagram Conversation';
        if (fileName.contains('cu ')) {
          personName = fileName.split('cu ').last.split('.').first.trim();
        }
        
        await _parseGenericConversation(content, platform, personName);
      } 
      // Pentru Messenger
      else if (platform == 'Messenger') {
        // Implementează parsarea specifică pentru Messenger
        // (Deocamdată folosim un nume generic)
        String personName = 'Messenger Conversation';
        if (fileName.contains('cu ')) {
          personName = fileName.split('cu ').last.split('.').first.trim();
        }
        
        await _parseGenericConversation(content, platform, personName);
      }
      // Format necunoscut - încercăm o parsare generică
      else {
        String personName = 'Unknown Conversation';
        if (fileName.contains('cu ')) {
          personName = fileName.split('cu ').last.split('.').first.trim();
        }
        
        await _parseGenericConversation(content, platform, personName);
      }
      
      // Notificare că s-a procesat fișierul
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processed file: $fileName'),
          backgroundColor: _platforms[_currentPageIndex].iconColor,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print('Error parsing file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing file: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _parseWhatsAppConversation(String content, String platform, String fileName) async {
    // Extragem numele conversației din fișier
    String conversationName = 'WhatsApp Conversation';
    if (fileName.contains('cu ')) {
      conversationName = fileName.split('cu ').last.split('.').first.trim();
    }
    
    // Pregătim datele pentru procesare
    List<String> lines = content.split('\n');
    Map<DateTime, List<String>> messagesByDate = {};
    
    // Regex pentru a detecta liniile de mesaje WhatsApp format românesc
    // Format: DD.MM.YYYY, h:mm a.m./p.m. - Sender: Message
    final whatsappPattern = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4}),\s+(\d{1,2}):(\d{2})\s+([ap])\.m\.\s+-\s+(.+?):\s+(.+)');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Ignoră mesajele de sistem și fișierele atașate
      if (line.contains("Mesajele și apelurile sunt criptate integral") ||
          line.contains("locație în timp real") ||
          line.contains("fișier atașat")) {
        continue;
      }
      
      var match = whatsappPattern.firstMatch(line);
      if (match != null) {
        // Extrage componente dată
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        
        // Creăm data fără componenta de timp (doar zi)
        DateTime messageDate = DateTime(year, month, day);
        
        // Pregătim mesajul pentru stocare
        String sender = match.group(7)?.trim() ?? '';
        String message = match.group(8)?.trim() ?? '';
        String fullMessage = "$sender: $message";
        
        // Adăugăm mesajul la data corespunzătoare
        if (!messagesByDate.containsKey(messageDate)) {
          messagesByDate[messageDate] = [];
        }
        messagesByDate[messageDate]!.add(fullMessage);
      }
    }
    
    // Actualizăm starea cu datele extrase
    setState(() {
      // Adăugăm persoana în lista de persoane disponibile
      if (!_availablePeopleByPlatform[platform]!.contains(conversationName)) {
        _availablePeopleByPlatform[platform]!.add(conversationName);
      }
      
      // Inițializăm lista de date pentru conversația curentă
      if (!_personDatesByPlatform[platform]!.containsKey(conversationName)) {
        _personDatesByPlatform[platform]![conversationName] = [];
      }
      
      // Adăugăm datele extrase
      List<DateTime> availableDates = messagesByDate.keys.toList()..sort();
      for (DateTime date in availableDates) {
        if (!_personDatesByPlatform[platform]![conversationName]!.contains(date)) {
          _personDatesByPlatform[platform]![conversationName]!.add(date);
        }
      }
      
      // Adăugăm mesajele pentru fiecare dată
      for (var entry in messagesByDate.entries) {
        _conversationMessagesByPlatform[platform]![entry.key] = entry.value;
      }
    });
  }
  
  Future<void> _parseGenericConversation(String content, String platform, String conversationName) async {
    // Implementare temporară pentru alte formate - împărțim conținutul după linii
    List<String> lines = content.split('\n');
    
    // Extragem data curentă pentru a asocia mesajele
    final now = DateTime.now();
    DateTime messageDate = DateTime(now.year, now.month, now.day);
    
    // Filtrăm liniile goale
    lines = lines.where((line) => line.trim().isNotEmpty).toList();
    
    // Verificăm dacă există conținut valid
    if (lines.isEmpty) {
      throw Exception('No valid content found in the file');
    }
    
    // Actualizăm starea cu datele extrase
    setState(() {
      // Adăugăm persoana în lista de persoane disponibile
      if (!_availablePeopleByPlatform[platform]!.contains(conversationName)) {
        _availablePeopleByPlatform[platform]!.add(conversationName);
      }
      
      // Inițializăm lista de date pentru conversația curentă
      if (!_personDatesByPlatform[platform]!.containsKey(conversationName)) {
        _personDatesByPlatform[platform]![conversationName] = [];
      }
      
      // Adăugăm data curentă în lista de date disponibile
      if (!_personDatesByPlatform[platform]![conversationName]!.contains(messageDate)) {
        _personDatesByPlatform[platform]![conversationName]!.add(messageDate);
      }
      
      // Pregătim mesajele pentru stocare
      List<String> messages = [];
      for (String line in lines) {
        if (line.contains(':')) {
          messages.add(line);
        } else {
          messages.add("Unknown: $line");
        }
      }
      
      // Adăugăm mesajele pentru data curentă
      _conversationMessagesByPlatform[platform]![messageDate] = messages;
    });
  }
}
