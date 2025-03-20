import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/message_processor.dart';
import 'package:frontend/services/calendar_service.dart';
import 'package:frontend/models/message_summary.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  List<EventDetails> _detectedEvents = [];
  // Track which events have been added to calendar
  Map<int, bool> _eventAddedToCalendar = {};
  bool _isLoading = false;

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
    
    // Fetch messages
    _fetchMessages();
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
        
        _detectedEvents = [
          EventDetails(
            title: 'Meeting with Alice',
            dateTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
            location: 'Pietris',
          ),
          EventDetails(
            title: 'Zoom Call',
            dateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
            location: 'online',
          ),
        ];
        
        // Initialize all events as not added to calendar
        _eventAddedToCalendar = {
          for (int i = 0; i < _detectedEvents.length; i++) i: false
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
        
        _detectedEvents = [
          EventDetails(
            title: 'Meeting with Alice',
            dateTime: DateTime.now().add(const Duration(days: 1, hours: 15)),
            location: 'Pietris',
          ),
          EventDetails(
            title: 'Zoom Call',
            dateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
            location: 'online',
          ),
        ];
        
        // Initialize all events as not added to calendar
        _eventAddedToCalendar = {
          for (int i = 0; i < _detectedEvents.length; i++) i: false
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleEventCalendar(int index, EventDetails event) async {
    // If event is already added to calendar, remove it
    if (_eventAddedToCalendar[index] == true) {
      // Here you would implement the actual calendar event removal functionality
      // For now we just toggle the UI state
      setState(() {
        _eventAddedToCalendar[index] = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event removed from calendar'),
          duration: Duration(seconds: 2),
        ),
      );
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
        _eventAddedToCalendar[index] = true;
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Event added to calendar!' : 'Failed to add event to calendar',
        ),
        duration: const Duration(seconds: 2),
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
            buildCard(
              context,
              title: 'Unread Messages',
              child: Column(
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
            buildCard(
              context,
              title: 'Advanced Summary',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Summary of conversations from selected date ...',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  const Icon(FontAwesomeIcons.calendar, color: Colors.black54),
                ],
              ),
            ),
            buildCard(
              context,
              minHeight: 60,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ask me anything ...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.send, color: Colors.black54),
                ],
              ),
            ),
            buildCard(
              context,
              title: 'Detected events',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _detectedEvents.isEmpty
                    ? [const Text('No events detected')]
                    : List.generate(
                        _detectedEvents.length,
                        (index) => GestureDetector(
                          onTap: () => _toggleEventCalendar(index, _detectedEvents[index]),
                          child: eventRow(
                            _formatEventDetails(_detectedEvents[index]),
                            _eventAddedToCalendar[index] ?? false,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
}
