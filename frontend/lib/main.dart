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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final MessageProcessor _messageProcessor = MessageProcessor();
  final CalendarService _calendarService = CalendarService();
  
  List<MessageSummary> _unreadSummaries = [];
  List<EventDetails> _detectedEvents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
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
      // Example messages from the problem statement
      final messages = [
        "Salut, când ne întâlnim?",
        "Propun să ne vedem la ora 18:00.",
        "Confirm, ne vedem la cafenea.",
        "Esti sigur?",
        "Da"
      ];
      
      final response = await _apiService.summarizeMessages(messages);
      final summary = response['summary'] ?? 'No summary available';
      
      // Process the summary to create a MessageSummary object
      final messageSummary = MessageSummary(summary: summary);
      
      // Check if it contains an event
      final eventDetails = _messageProcessor.detectEvent(summary);
      
      setState(() {
        _unreadSummaries = [messageSummary];
        
        if (eventDetails != null) {
          _detectedEvents = [eventDetails];
        }
      });
    } catch (e) {
      print('Error fetching data: $e');
      // Show a mock summary for testing if the API call fails
      setState(() {
        _unreadSummaries = [
          MessageSummary(
            summary: 'Meeting confirmed at 18:00 at the coffee shop.',
          )
        ];
        
        _detectedEvents = [
          EventDetails(
            title: 'Coffee shop meeting',
            dateTime: DateTime.now().add(const Duration(hours: 2)),
            location: 'Coffee shop',
          )
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addEventToCalendar(EventDetails event) async {
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Event added to calendar!' : 'Failed to add event to calendar',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios, color: Colors.black54),
        centerTitle: true,
        title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FontAwesomeIcons.instagram, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Smart message Instagram',
                  textAlign: TextAlign.center,
                  softWrap: true,
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
        actions: const [
          Icon(Icons.arrow_forward_ios, color: Colors.black54),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            : _detectedEvents.map((event) => 
                                GestureDetector(
                                  onTap: () => _addEventToCalendar(event),
                                  child: eventRow(
                                    '${_formatDateTime(event.dateTime)}, ${event.location}',
                                  ),
                                ),
                              ).toList(),
                      ),
                    ),
                  ],
                ),
              ),
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

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return 'Date: ${dateTime.day}/${dateTime.month}/${dateTime.year}, Time: $hour:$minute';
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

  Widget eventRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  'Add to Calendar',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
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
