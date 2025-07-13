import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/calendar_service.dart';
import 'package:frontend/services/logger_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:frontend/features/home/domain/models/social_media_platform.dart';
import 'package:frontend/features/home/domain/models/event_details.dart';
import 'package:frontend/features/home/presentation/widgets/home_widgets/advanced_summary_ui.dart';
import 'package:frontend/features/home/presentation/widgets/home_widgets/ask_me_ui.dart';
import 'package:frontend/features/home/presentation/widgets/home_widgets/detected_events_ui.dart';
import 'package:frontend/features/home/presentation/widgets/home_widgets/dashboard_section.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final Color platformColor;

  const HomePage({
    super.key,
    required this.platformColor,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final CalendarService _calendarService = CalendarService();

  late PageController _pageController;
  int _currentPageIndex = 0;

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

  // =====================
  //  Avansat: fișiere, persoane, date, rezumat
  // =====================
  final Map<String, List<String>> _uploadedFilePathsByPlatform = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };

  final Map<String, List<String>> _availablePeopleByPlatform = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };

  final Map<String, String?> _selectedPersonByPlatform = {
    'Instagram': null,
    'WhatsApp': null,
    'Messenger': null
  };

  final Map<String, DateTime?> _selectedDateByPlatform = {
    'Instagram': null,
    'WhatsApp': null,
    'Messenger': null
  };

  final Map<String, String?> _conversationSummaryByPlatform = {
    'Instagram': null,
    'WhatsApp': null,
    'Messenger': null
  };

  final Map<String, Map<String, List<DateTime>>> _personDatesByPlatform = {
    'Instagram': {},
    'WhatsApp': {},
    'Messenger': {}
  };

  final Map<String, Map<String, Map<DateTime, List<String>>>>
      _conversationMessagesByPlatform = {
    'Instagram': {},
    'WhatsApp': {},
    'Messenger': {}
  };

  bool _isSummarizing = false;

  // ======================
  //   ASK ME ANYTHING
  // ======================
  final Map<String, TextEditingController> _askControllers = {
    'Instagram': TextEditingController(),
    'WhatsApp': TextEditingController(),
    'Messenger': TextEditingController()
  };

  final Map<String, List<String>> _askChatLogByPlatform = {
    'Instagram': [],
    'WhatsApp': [],
    'Messenger': []
  };

  /// Limit of messages sent to AI when asking about all conversations.
  /// Set to null for unlimited.
  int? _askMessageLimit;

  final Map<String, DateTime?> _trimmedUntilByPlatform = {
    'Instagram': null,
    'WhatsApp': null,
    'Messenger': null,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeApp();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _askControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _calendarService.requestPermissions();
    await _loadSavedData();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
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
      LoggerService.error('Error in _fetchMessages: $e');
    }
  }

  Future<void> _loadSavedData() async {
    for (final platform in ['Instagram', 'WhatsApp', 'Messenger']) {
      // Load saved files
      final savedFiles = await storageService.loadFiles(platform);
      setState(() {
        _uploadedFilePathsByPlatform[platform] = savedFiles;
      });

      // Load saved conversations
      final savedConversations = await storageService.loadConversations(platform);
      if (savedConversations.isNotEmpty) {
        setState(() {
          _availablePeopleByPlatform[platform] = List<String>.from(savedConversations['people'] ?? []);
          _personDatesByPlatform[platform] = Map<String, List<DateTime>>.from(savedConversations['dates'] ?? {});
          _conversationMessagesByPlatform[platform] =
              Map<String, Map<DateTime, List<String>>>.from(
                  savedConversations['messages'] ?? {});
        });
      }
    }
  }

  Future<void> _savePlatformData(String platform) async {
    // Save files
    await storageService.saveFiles(platform, _uploadedFilePathsByPlatform[platform] ?? []);

    // Save conversations
    final conversations = {
      'people': _availablePeopleByPlatform[platform],
      'dates': _personDatesByPlatform[platform],
      'messages': _conversationMessagesByPlatform[platform],
    };
    await storageService.saveConversations(platform, conversations);
  }

  Future<void> _deleteFile(String platform, String path) async {
    setState(() {
      _uploadedFilePathsByPlatform[platform]?.remove(path);
      
      // Remove associated conversations
      final fileName = path.split('/').last;
      final personName = fileName.contains('cu ') 
        ? fileName.split('cu ').last.split('.').first.trim()
        : null;
      
      if (personName != null) {
        final dates = _personDatesByPlatform[platform]?[personName] ?? [];
        for (final date in dates) {
          _conversationMessagesByPlatform[platform]?[personName]?.remove(date);
        }
        _conversationMessagesByPlatform[platform]?.remove(personName);
        _availablePeopleByPlatform[platform]?.remove(personName);
        _personDatesByPlatform[platform]?.remove(personName);
        _selectedPersonByPlatform[platform] = null;
        _selectedDateByPlatform[platform] = null;
        _conversationSummaryByPlatform[platform] = null;
      }
    });

    // Save updated data
    await _savePlatformData(platform);

    if (!mounted) return;
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
        _isSummarizing = true;
      });

      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      String content = await file.readAsString();
      String fileName = path.split('/').last;
      
      LoggerService.debug('=== Starting file parsing ===');
      LoggerService.debug('File: $fileName');
      LoggerService.debug('Platform: $platform');
      
      // Reset selection for this platform but keep existing data
      setState(() {
        _selectedPersonByPlatform[platform] = null;
        _selectedDateByPlatform[platform] = null;
        _conversationSummaryByPlatform[platform] = null;
      });
      
      if (platform == 'WhatsApp' && (fileName.contains('WhatsApp') || content.contains('Mesajele și apelurile sunt criptate integral'))) {
        await _parseWhatsAppConversation(content, platform, fileName);
      } else if (platform == 'Instagram') {
        String personName = 'Instagram Conversation';
        if (fileName.contains('cu ')) {
          personName = fileName.split('cu ').last.split('.').first.trim();
        }
        await _parseGenericConversation(content, platform, personName);
      } else if (platform == 'Messenger') {
        String personName = 'Messenger Conversation';
        if (fileName.contains('cu ')) {
          personName = fileName.split('cu ').last.split('.').first.trim();
        }
        await _parseGenericConversation(content, platform, personName);
      } else {
        String personName = 'Unknown Conversation';
        if (fileName.contains('cu ')) {
          personName = fileName.split('cu ').last.split('.').first.trim();
        }
        await _parseGenericConversation(content, platform, personName);
      }
      
      // Save data after parsing
      await _savePlatformData(platform);
      
      LoggerService.debug('=== File parsing completed ===');
      LoggerService.debug('Available people: ${_availablePeopleByPlatform[platform]}');
      LoggerService.debug('Dates by person: ${_personDatesByPlatform[platform]}');
      LoggerService.debug('Messages by date: ${_conversationMessagesByPlatform[platform]}');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processed file: $fileName'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      LoggerService.error('Error parsing file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing file: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSummarizing = false;
      });
    }
  }
  
  Future<void> _parseWhatsAppConversation(String content, String platform, String fileName) async {
    String conversationName = 'WhatsApp Conversation';
    if (fileName.contains('cu ')) {
      conversationName = fileName.split('cu ').last.split('.').first.trim();
    }
    
    List<String> lines = content.split('\n');
    Map<DateTime, List<String>> messagesByDate = {};
    
    final whatsappPattern = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4}),\s+(\d{1,2}):(\d{2})\s+([ap])\.m\.\s+-\s+(.+?):\s+(.+)');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      if (line.contains("Mesajele și apelurile sunt criptate integral") ||
          line.contains("locație în timp real") ||
          line.contains("fișier atașat")) {
        continue;
      }
      
      var match = whatsappPattern.firstMatch(line);
      if (match != null) {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        
        DateTime messageDate = DateTime(year, month, day);
        
        // Store the complete message including date and time instead of just sender and message
        // This preserves the original format for the AI to analyze
        String fullMessage = line;
        
        if (!messagesByDate.containsKey(messageDate)) {
          messagesByDate[messageDate] = [];
        }
        messagesByDate[messageDate]!.add(fullMessage);
      }
    }
    
    setState(() {
      if (!_availablePeopleByPlatform[platform]!.contains(conversationName)) {
        _availablePeopleByPlatform[platform]!.add(conversationName);
      }
      
      if (!_personDatesByPlatform[platform]!.containsKey(conversationName)) {
        _personDatesByPlatform[platform]![conversationName] = [];
      }
      
      List<DateTime> availableDates = messagesByDate.keys.toList()..sort();
      for (DateTime date in availableDates) {
        if (!_personDatesByPlatform[platform]![conversationName]!.contains(date)) {
          _personDatesByPlatform[platform]![conversationName]!.add(date);
        }
      }
      
      final convMap = _conversationMessagesByPlatform[platform]
          .putIfAbsent(conversationName, () => {});
      for (var entry in messagesByDate.entries) {
        convMap[entry.key] = entry.value;
      }
    });
  }
  
  Future<void> _parseGenericConversation(String content, String platform, String conversationName) async {
    List<String> lines = content.split('\n');
    final now = DateTime.now();
    DateTime messageDate = DateTime(now.year, now.month, now.day);
    
    lines = lines.where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      throw Exception('No valid content found in the file');
    }
    
    setState(() {
      if (!_availablePeopleByPlatform[platform]!.contains(conversationName)) {
        _availablePeopleByPlatform[platform]!.add(conversationName);
      }
      
      if (!_personDatesByPlatform[platform]!.containsKey(conversationName)) {
        _personDatesByPlatform[platform]![conversationName] = [];
      }
      
      if (!_personDatesByPlatform[platform]![conversationName]!.contains(messageDate)) {
        _personDatesByPlatform[platform]![conversationName]!.add(messageDate);
      }
      
      List<String> messages = [];
      for (String line in lines) {
        if (line.contains(':')) {
          messages.add(line);
        } else {
          messages.add("Unknown: $line");
        }
      }
      
      final convMap = _conversationMessagesByPlatform[platform]
          .putIfAbsent(conversationName, () => {});
      convMap[messageDate] = messages;
    });
  }

  void _showDatePicker(String platformName) {
    final platformColor = SocialMediaPlatform.platforms[_currentPageIndex].iconColor;
    final selectedPerson = _selectedPersonByPlatform[platformName];
    
    if (selectedPerson == null) return;
    
    final dates = _personDatesByPlatform[platformName]?[selectedPerson] ?? [];
    if (dates.isEmpty) return;
    
    dates.sort();
    final initialDate = _selectedDateByPlatform[platformName] ?? dates.first;
    
    if (!mounted) return;
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

  Future<void> _generateSummary(String platform) async {
    final currentPlatform = SocialMediaPlatform.platforms[_currentPageIndex];
    final platformColor = currentPlatform.iconColor;
    final person = _selectedPersonByPlatform[platform];
    final date = _selectedDateByPlatform[platform];
    
    if (person == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a person first'),
          backgroundColor: platformColor,
        ),
      );
      return;
    }
    
    if (date == null) {
      if (!mounted) return;
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
      
      // Clear previous events for this platform when selecting new date
      _platformEvents[platform] = [];
      _eventAddedToCalendar[platform] = {};
    });

    try {
      final messages = _conversationMessagesByPlatform[platform]?[person]?[date] ?? [];
      if (messages.isEmpty) {
        throw Exception('No messages found for $person on selected date.');
      }
      
      // Debug: Print messages being sent to the API
      LoggerService.debug('Sending ${messages.length} messages to API for summary:');
      for (int i = 0; i < messages.length && i < 5; i++) {
        LoggerService.debug('Message ${i+1}: ${messages[i]}');
      }
      if (messages.length > 5) {
        LoggerService.debug('... and ${messages.length - 5} more messages');
      }

      final summaryData = await _apiService.summarizeMessages(messages);
      setState(() {
        _conversationSummaryByPlatform[platform] = summaryData['summary'];
      });

      final List<dynamic> eventsList = summaryData['detectedEvents'] ?? [];
      LoggerService.info('Processing ${eventsList.length} events from API response');
      
      final List<EventDetails> detectedEvents = [];
      
      // Process events from API response - rely entirely on the AI
      for (final e in eventsList) {
        if (e is Map) {
          try {
            // Parse date correctly
            final String dateTimeStr = e['dateTime'] ?? '';
            DateTime eventDateTime;
            
            if (dateTimeStr.isNotEmpty) {
              eventDateTime = DateTime.parse(dateTimeStr);
              
              // Adjust for timezone if needed
              if (eventDateTime.isUtc) {
                eventDateTime = eventDateTime.toLocal();
              }
              
              final String title = e['title'] ?? 'Untitled Event';
              final String location = e['location'] ?? '';
              final bool isAllDay = e['isAllDay'] == true || 
                                   title.toLowerCase().contains('ziua lui') ||
                                   title.toLowerCase().contains('zi de naștere');
                
              // Skip ad-hoc meetings or casual encounters
              final bool isAdHocMeeting = _isAdHocMeeting(title, location);
              if (isAdHocMeeting) {
                LoggerService.debug('Skipping ad-hoc event: $title');
                continue;
              }
              
              detectedEvents.add(EventDetails(
                title: title,
                dateTime: eventDateTime,
                location: location,
                isAllDay: isAllDay,
              ));
              LoggerService.info('Added event: $title on ${eventDateTime.toString()}, all-day: $isAllDay');
            }
          } catch (error) {
            LoggerService.error('Error processing event: $error');
          }
        }
      }

      setState(() {
        // Replace previous events with new ones for this platform
        _platformEvents[platform] = detectedEvents;
        _eventAddedToCalendar[platform] = {
          for (int i = 0; i < detectedEvents.length; i++) i: false
        };
      });
      
      // Debug: print current state of events
      LoggerService.debug('Current platform events:');
      for (final platform in _platformEvents.keys) {
        final events = _platformEvents[platform] ?? [];
        LoggerService.debug('$platform: ${events.length} events');
        for (final event in events) {
          LoggerService.debug('- ${event.title} on ${event.dateTime}');
        }
      }
      
    } catch (error) {
      LoggerService.error('Error in _generateSummary: $error');
      setState(() {
        _conversationSummaryByPlatform[platform] = 'Error generating summary: $error';
      });
    } finally {
      setState(() {
        _isSummarizing = false;
      });
    }
  }
  
  // Helper method to identify ad-hoc meetings that should be filtered out
  bool _isAdHocMeeting(String title, String location) {
    final lowerTitle = title.toLowerCase();
    
    // Common patterns for ad-hoc meetings
    final adHocIndicators = [
      'întâlnire la',
      'întâlnire informală',
      'ne vedem la',
      'sunt la',
    ];
    
    for (final indicator in adHocIndicators) {
      if (lowerTitle.contains(indicator)) {
        return true;
      }
    }
    
    // Generic short meeting titles without specifics
    if ((lowerTitle == 'întâlnire' || lowerTitle == 'meeting') &&
        location.isEmpty) {
      return true;
    }
    
    return false;
  }

  Future<void> _toggleEventCalendar(String platform, int index, EventDetails event) async {
    if (_eventAddedToCalendar[platform]?[index] == true) {
      final success = await _calendarService.removeEventWithConfirmation(context, event);
      if (success) {
        setState(() {
          _eventAddedToCalendar[platform]![index] = false;
        });
      }
      return;
    }

    final success = await _calendarService.addEventWithCalendarSelection(context, event);
    if (success) {
      setState(() {
        _eventAddedToCalendar[platform]![index] = true;
      });
    }
  }

  void _nextPage() {
    if (_currentPageIndex < SocialMediaPlatform.platforms.length - 1) {
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
                        leading: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                        title: Text(
                          path.split('/').last,
                          style: GoogleFonts.poppins(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
        final paths = _uploadedFilePathsByPlatform[platformName]!;
        final alreadyExists = paths.contains(file.path!);

        setState(() {
          if (!alreadyExists) {
            paths.add(file.path!);
          }
        });

        await _parseFile(file.path!, platformName);

        if (!mounted) return;
        final message = alreadyExists
            ? 'File ${file.name} replaced for $platformName'
            : 'File ${file.name} uploaded for $platformName';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      LoggerService.error('Error picking file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _processUploadedFile(String platform, String path) {
    _parseFile(path, platform).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File opened: ${path.split('/').last}'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  Widget _buildAskMeUI(String platform) {
    final currentPlatform = SocialMediaPlatform.platforms[_currentPageIndex];
    return AskMeUI(
      platformName: platform,
      platformColor: currentPlatform.iconColor,
      controller: _askControllers[platform]!,
      chatLog: _askChatLogByPlatform[platform]!,
      onQuestionSubmitted: (question) async {
        final messages = _getMessagesForAsk(platform);
        if (messages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No messages available for ${_selectedPersonByPlatform[platform]}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final trimmedDate = _trimmedUntilByPlatform[platform];
        if (trimmedDate != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Too many messages. We trimmed conversation until '
                  '${DateFormat('dd/MM/yyyy').format(trimmedDate)}'),
            ),
          );
        }

        final answer = await _apiService.askQuestion(messages, question);
        setState(() {
          _askChatLogByPlatform[platform]!.add('Q: $question\nA: $answer');
          _askControllers[platform]!.clear();
        });
      },
      isDateSelected: _selectedDateByPlatform[platform] != null,
      onModeChanged: (isDateSelected) {
        setState(() {
          if (isDateSelected) {
            _showDatePicker(platform);
          } else {
            _selectedDateByPlatform[platform] = null;
          }
        });
      },
    );
  }

  List<String> _getMessagesForAsk(String platform) {
    final selectedPerson = _selectedPersonByPlatform[platform];
    if (selectedPerson == null) return [];

    final selectedDate = _selectedDateByPlatform[platform];
    if (selectedDate != null) {
      // Dacă avem o dată selectată, returnăm mesajele din acea dată
      return _conversationMessagesByPlatform[platform]?[selectedPerson]?[selectedDate] ?? [];
    } else {
      // Dacă nu avem o dată selectată, returnăm toate mesajele pentru acea persoană
      final allMessages = <String>[];
      final dates = _personDatesByPlatform[platform]?[selectedPerson] ?? [];
      final sortedDates = List<DateTime>.from(dates)..sort();

      if (_askMessageLimit == null) {
        for (final date in sortedDates) {
          allMessages.addAll(
              _conversationMessagesByPlatform[platform]?[selectedPerson]?[date] ?? []);
        }
        _trimmedUntilByPlatform[platform] = null;
        return allMessages;
      }

      // Limitare opțională a numărului de mesaje
      DateTime? earliestIncluded;
      int count = 0;
      final temp = <List<String>>[];
      for (final date in sortedDates.reversed) {
        final msgs = _conversationMessagesByPlatform[platform]?[selectedPerson]?[date] ?? [];
        if (count + msgs.length > _askMessageLimit!) {
          break;
        }
        temp.add(msgs);
        earliestIncluded = date;
        count += msgs.length;
      }

      for (final msgs in temp.reversed) {
        allMessages.addAll(msgs);
      }

      if (earliestIncluded != null && earliestIncluded != sortedDates.first) {
        _trimmedUntilByPlatform[platform] = earliestIncluded;
      } else {
        _trimmedUntilByPlatform[platform] = null;
      }

      return allMessages;
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = SocialMediaPlatform.platforms[_currentPageIndex];
    final platformName = platform.name;
    final platformColor = platform.iconColor;

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: platformColor),
          onPressed: _previousPage,
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              platform.icon,
              color: platformColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              platformName,
              style: GoogleFonts.poppins(
                color: platformColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: platformColor),
            onPressed: _nextPage,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                itemCount: SocialMediaPlatform.platforms.length,
                itemBuilder: (context, index) {
                  final currentPlatform = SocialMediaPlatform.platforms[index];
                  final currentPlatformColor = currentPlatform.iconColor;
                  final currentPlatformName = currentPlatform.name;
                  
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DashboardSection(
                            title: 'Advanced Summary',
                            platformColor: currentPlatformColor,
                            child: AdvancedSummaryUI(
                              platformName: currentPlatformName,
                              platformColor: currentPlatformColor,
                              uploadedFiles: _uploadedFilePathsByPlatform[currentPlatformName] ?? [],
                              availablePeople: _availablePeopleByPlatform[currentPlatformName] ?? [],
                              selectedPerson: _selectedPersonByPlatform[currentPlatformName],
                              selectedDate: _selectedDateByPlatform[currentPlatformName],
                              conversationSummary: _conversationSummaryByPlatform[currentPlatformName],
                              isSummarizing: _isSummarizing,
                              onFileUpload: _openFileManager,
                              onFileDelete: _deleteFile,
                              onPersonSelected: (person) {
                                setState(() {
                                  _selectedPersonByPlatform[currentPlatformName] = person;
                                  _selectedDateByPlatform[currentPlatformName] = null;
                                  _conversationSummaryByPlatform[currentPlatformName] = null;
                                  _platformEvents[currentPlatformName] = [];
                                  _eventAddedToCalendar[currentPlatformName] = {};
                                  _askChatLogByPlatform[currentPlatformName] = [];
                                  _trimmedUntilByPlatform[currentPlatformName] = null;
                                  _askControllers[currentPlatformName]!.clear();
                                });
                              },
                              onDateSelected: () => _showDatePicker(currentPlatformName),
                              onGenerateSummary: () => _generateSummary(currentPlatformName),
                            ),
                          ),
                          DashboardSection(
                            title: 'Ask Me',
                            platformColor: currentPlatformColor,
                            child: _buildAskMeUI(currentPlatformName),
                          ),
                          DashboardSection(
                            title: 'Detected Events',
                            platformColor: currentPlatformColor,
                            child: DetectedEventsUI(
                              platformName: currentPlatformName,
                              platformColor: currentPlatformColor,
                              events: _platformEvents[currentPlatformName] ?? [],
                              eventAddedToCalendar: _eventAddedToCalendar[currentPlatformName] ?? {},
                              onToggleEventCalendar: (index, event) => _toggleEventCalendar(currentPlatformName, index, event),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
} 