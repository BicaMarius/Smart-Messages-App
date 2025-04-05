import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/api_service.dart';

class ConversationPerson {
  final String name;
  final List<DateTime> availableDates;
  
  ConversationPerson({required this.name, required this.availableDates});
}

class ConversationEntry {
  final String sender;
  final String content;
  final DateTime timestamp;
  
  ConversationEntry({
    required this.sender, 
    required this.content, 
    required this.timestamp
  });
}

class AdvancedSummaryScreen extends StatefulWidget {
  const AdvancedSummaryScreen({super.key});

  @override
  _AdvancedSummaryScreenState createState() => _AdvancedSummaryScreenState();
}

class _AdvancedSummaryScreenState extends State<AdvancedSummaryScreen> {
  final ApiService _apiService = ApiService();
  
  // State variables
  bool _isLoading = false;
  List<File> _uploadedFiles = [];
  List<ConversationEntry> _conversationEntries = [];
  List<ConversationPerson> _people = [];
  ConversationPerson? _selectedPerson;
  DateTime? _selectedDate;
  String? _summary;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Advanced Summary',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sample') {
                _generateSampleData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'sample',
                child: Text('Generate Sample Data'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUploadSection(),
                const SizedBox(height: 20),
                if (_uploadedFiles.isNotEmpty) ...[
                  _buildPersonSelector(),
                  const SizedBox(height: 20),
                  if (_selectedPerson != null) ...[
                    _buildDateSelector(),
                    const SizedBox(height: 20),
                    if (_selectedDate != null) ...[
                      _buildSummarySection(),
                    ],
                  ],
                ],
              ],
            ),
          ),
    );
  }
  
  Widget _buildUploadSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Conversation Files',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Select one or more exported conversation files from your social media accounts.',
              style: GoogleFonts.poppins(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_uploadedFiles.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _clearFiles,
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            if (_uploadedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _uploadedFiles
                    .map((file) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  file.path.split('/').last,
                                  style: GoogleFonts.poppins(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 16),
                                onPressed: () => _removeFile(file),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPersonSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Person',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_people.isEmpty)
              Text(
                'No people found in the uploaded conversation files.',
                style: GoogleFonts.poppins(color: Colors.black54),
              )
            else
              DropdownButtonFormField<ConversationPerson>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                hint: Text(
                  'Select a person',
                  style: GoogleFonts.poppins(),
                ),
                value: _selectedPerson,
                items: _people
                    .map((person) => DropdownMenuItem<ConversationPerson>(
                          value: person,
                          child: Text(person.name, style: GoogleFonts.poppins()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPerson = value;
                    _selectedDate = null;
                    _summary = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (_selectedPerson!.availableDates.isEmpty)
              Text(
                'No dates available for this person.',
                style: GoogleFonts.poppins(color: Colors.black54),
              )
            else
              DropdownButtonFormField<DateTime>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                hint: Text(
                  'Select a date',
                  style: GoogleFonts.poppins(),
                ),
                value: _selectedDate,
                items: _selectedPerson!.availableDates
                    .map((date) => DropdownMenuItem<DateTime>(
                          value: date,
                          child: Text(
                            DateFormat('MMM d, yyyy').format(date),
                            style: GoogleFonts.poppins(),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDate = value;
                    _summary = null;
                  });
                  
                  if (value != null) {
                    _generateSummary();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummarySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conversation Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_summary != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: _generateSummary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_summary == null)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _summary!,
                  style: GoogleFonts.poppins(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'csv'],
        allowMultiple: true,
      );
      
      if (result != null) {
        setState(() {
          _isLoading = true;
        });
        
        List<File> files = result.paths.map((path) => File(path!)).toList();
        
        // Add the picked files to state
        setState(() {
          _uploadedFiles.addAll(files);
        });
        
        // Process the files
        await _processFiles(files);
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error picking files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _clearFiles() {
    setState(() {
      _uploadedFiles = [];
      _conversationEntries = [];
      _people = [];
      _selectedPerson = null;
      _selectedDate = null;
      _summary = null;
    });
  }
  
  void _removeFile(File file) {
    setState(() {
      _uploadedFiles.remove(file);
      // We should reprocess the remaining files, but for simplicity's sake
      // we'll clear all derived data
      _people = [];
      _conversationEntries = [];
      _selectedPerson = null;
      _selectedDate = null;
      _summary = null;
    });
    
    // Reprocess the remaining files
    if (_uploadedFiles.isNotEmpty) {
      _processFiles(_uploadedFiles);
    }
  }
  
  Future<void> _processFiles(List<File> files) async {
    List<ConversationEntry> allEntries = [];
    int totalLinesProcessed = 0;
    int parsedEntries = 0;
    
    for (File file in files) {
      try {
        String content = await file.readAsString();
        List<String> lines = content.split('\n');
        totalLinesProcessed += lines.length;
        
        print("Processing file: ${file.path}");
        print("File contains ${lines.length} lines");
        
        List<ConversationEntry> entries = _parseConversation(content);
        print("Extracted ${entries.length} messages from file");
        parsedEntries += entries.length;
        
        allEntries.addAll(entries);
      } catch (e) {
        print('Error processing file ${file.path}: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing file ${file.path.split('/').last}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (parsedEntries == 0 && totalLinesProcessed > 0) {
      print("Warning: Failed to parse any messages from $totalLinesProcessed total lines!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No messages could be parsed. The file format may not be supported.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      print("Successfully parsed $parsedEntries messages from $totalLinesProcessed total lines");
    }
    
    // Extract people and available dates
    Map<String, Set<DateTime>> peopleWithDates = {};
    
    for (var entry in allEntries) {
      if (!peopleWithDates.containsKey(entry.sender)) {
        peopleWithDates[entry.sender] = {};
      }
      
      // Add the date (without time) to the set
      DateTime dateOnly = DateTime(
        entry.timestamp.year, 
        entry.timestamp.month, 
        entry.timestamp.day
      );
      peopleWithDates[entry.sender]!.add(dateOnly);
    }
    
    // Convert to list of ConversationPerson objects
    List<ConversationPerson> people = peopleWithDates.entries
        .map((entry) => ConversationPerson(
              name: entry.key,
              availableDates: entry.value.toList()..sort(),
            ))
        .toList();
    
    // Sort people alphabetically
    people.sort((a, b) => a.name.compareTo(b.name));
    
    print("Identified ${people.length} unique people in the conversation");
    if (people.isNotEmpty) {
      for (var person in people) {
        print("- ${person.name}: ${person.availableDates.length} days of conversation");
      }
    }
    
    setState(() {
      _conversationEntries = allEntries;
      _people = people;
    });
  }
  
  List<ConversationEntry> _parseConversation(String content) {
    // Try different parsing strategies based on content format
    try {
      // Check if it's a WhatsApp export by looking for specific patterns
      if (content.contains("Mesajele și apelurile sunt criptate integral") ||
          content.contains("Messages and calls are end-to-end encrypted")) {
        print("Detected WhatsApp export format");
        return _parseWhatsAppConversation(content);
      }
      
      // Try parsing as JSON first
      if (content.trim().startsWith('{') || content.trim().startsWith('[')) {
        return _parseJsonConversation(content);
      }
      
      // Try parsing as plain text with common patterns
      return _parsePlainTextConversation(content);
    } catch (e) {
      print('Error parsing conversation: $e');
      return [];
    }
  }
  
  List<ConversationEntry> _parseWhatsAppConversation(String content) {
    List<ConversationEntry> entries = [];
    List<String> lines = content.split('\n');
    
    // WhatsApp format (Romanian): DD.MM.YYYY, h:mm a.m./p.m. - Sender: Message
    final whatsappPattern = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4}),\s+(\d{1,2}):(\d{2})\s+([ap])\.m\.\s+-\s+(.*?):\s+(.*)', dotAll: true);
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Skip system messages
      if (line.contains("Mesajele și apelurile sunt criptate integral")) continue;
      if (line.contains("locație în timp real")) continue;
      if (line.contains("fișier atașat")) continue;
      if (line.endsWith(".pdf") || line.endsWith(".jpg") || line.endsWith(".webp")) continue;
      
      var match = whatsappPattern.firstMatch(line);
      if (match != null) {
        // Extract date components
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        
        // Extract time components
        int hour = int.parse(match.group(4)!);
        int minute = int.parse(match.group(5)!);
        String amPm = match.group(6)!;
        
        // Convert to 24-hour format if PM
        if (amPm == 'p' && hour < 12) {
          hour += 12;
        } else if (amPm == 'a' && hour == 12) {
          hour = 0;
        }
        
        // Extract sender and message
        String sender = match.group(7)?.trim() ?? '';
        String message = match.group(8)?.trim() ?? '';
        
        // Create timestamp
        DateTime timestamp = DateTime(year, month, day, hour, minute);
        
        entries.add(ConversationEntry(
          sender: sender,
          content: message,
          timestamp: timestamp,
        ));
      } else {
        print("Could not parse WhatsApp line: $line");
      }
    }
    
    print("Parsed ${entries.length} entries from WhatsApp format");
    return entries;
  }
  
  List<ConversationEntry> _parseJsonConversation(String content) {
    List<ConversationEntry> entries = [];
    
    try {
      // Check if it's WhatsApp JSON export format
      final decoded = jsonDecode(content);
      
      // WhatsApp export format - array of messages
      if (decoded is List) {
        for (var message in decoded) {
          if (message is Map<String, dynamic>) {
            // Check for common fields in various export formats
            String? sender = message['sender'] ?? 
                            message['author'] ?? 
                            message['from'] ?? 
                            message['name'] ?? 
                            'Unknown';
                            
            String? messageContent = message['message'] ?? 
                                   message['content'] ?? 
                                   message['text'] ?? 
                                   message['body'] ?? 
                                   '';
                                   
            // Try to parse timestamp in various formats
            DateTime timestamp = DateTime.now();
            if (message.containsKey('timestamp')) {
              if (message['timestamp'] is int) {
                timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
              } else if (message['timestamp'] is String) {
                try {
                  timestamp = DateTime.parse(message['timestamp']);
                } catch (e) {
                  // Keep default
                }
              }
            } else if (message.containsKey('date') || message.containsKey('time')) {
              String dateTimeStr = '${message['date'] ?? ''} ${message['time'] ?? ''}';
              try {
                timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeStr.trim());
              } catch (e) {
                // Keep default
              }
            }
            
            if (sender is String && messageContent is String) {
              entries.add(ConversationEntry(
                sender: sender,
                content: messageContent,
                timestamp: timestamp,
              ));
            }
          }
        }
      } 
      // Message thread format - object with nested messages
      else if (decoded is Map<String, dynamic>) {
        final messages = decoded['messages'] ?? 
                        decoded['conversation'] ?? 
                        decoded['chat'] ?? 
                        [];
                        
        if (messages is List) {
          for (var message in messages) {
            if (message is Map<String, dynamic>) {
              final sender = message['sender'] ?? 
                           message['author'] ?? 
                           message['from'] ?? 
                           'Unknown';
                           
              final content = message['message'] ?? 
                            message['content'] ?? 
                            message['text'] ?? 
                            '';
                            
              // Parse timestamp
              DateTime timestamp = DateTime.now();
              if (message.containsKey('timestamp')) {
                if (message['timestamp'] is int) {
                  timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
                } else if (message['timestamp'] is String) {
                  try {
                    timestamp = DateTime.parse(message['timestamp']);
                  } catch (e) {
                    // Keep default
                  }
                }
              }
              
              entries.add(ConversationEntry(
                sender: sender,
                content: content,
                timestamp: timestamp,
              ));
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing JSON conversation: $e');
    }
    
    return entries;
  }
  
  List<ConversationEntry> _parsePlainTextConversation(String content) {
    List<ConversationEntry> entries = [];
    List<String> lines = content.split('\n');
    
    // Try several common patterns used in text exports
    
    // Pattern 1: [Timestamp] Sender: Message
    final pattern1 = RegExp(r'\[(.*?)\]\s+(.*?):\s+(.*)');
    
    // Pattern 2: Sender (Timestamp): Message
    final pattern2 = RegExp(r'(.*?)\s+\((.*?)\):\s+(.*)');
    
    // Pattern 3: Sender: Message [Timestamp]
    final pattern3 = RegExp(r'(.*?):\s*(.*?)\s*\[(.*?)\]');
    
    // Pattern 4: DD/MM/YYYY, HH:MM - Sender: Message
    final pattern4 = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4},\s+\d{1,2}:\d{2})\s+-\s+(.*?):\s+(.*)');
    
    // Pattern 5: DD.MM.YYYY, H:MM a/p.m. - Sender: Message (WhatsApp Romanian format)
    final pattern5 = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4}),\s+(\d{1,2}:\d{2}\s+[ap]\.m\.)\s+-\s+(.*?):\s+(.*)', dotAll: true);
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Skip system messages from WhatsApp that don't have a real sender
      if (line.contains("Mesajele și apelurile sunt criptate integral")) continue;
      if (line.contains("locație în timp real distribuită")) continue;
      if (line.contains("fișier atașat") || line.contains("file attached")) continue;
      
      var match = pattern1.firstMatch(line);
      if (match != null) {
        String timestampStr = match.group(1)?.trim() ?? '';
        String sender = match.group(2)?.trim() ?? '';
        String message = match.group(3)?.trim() ?? '';
        
        DateTime timestamp = _parseTimestamp(timestampStr);
        
        entries.add(ConversationEntry(
          sender: sender,
          content: message,
          timestamp: timestamp,
        ));
        continue;
      }
      
      match = pattern2.firstMatch(line);
      if (match != null) {
        String sender = match.group(1)?.trim() ?? '';
        String timestampStr = match.group(2)?.trim() ?? '';
        String message = match.group(3)?.trim() ?? '';
        
        DateTime timestamp = _parseTimestamp(timestampStr);
        
        entries.add(ConversationEntry(
          sender: sender,
          content: message,
          timestamp: timestamp,
        ));
        continue;
      }
      
      match = pattern3.firstMatch(line);
      if (match != null) {
        String sender = match.group(1)?.trim() ?? '';
        String message = match.group(2)?.trim() ?? '';
        String timestampStr = match.group(3)?.trim() ?? '';
        
        DateTime timestamp = _parseTimestamp(timestampStr);
        
        entries.add(ConversationEntry(
          sender: sender,
          content: message,
          timestamp: timestamp,
        ));
        continue;
      }
      
      match = pattern4.firstMatch(line);
      if (match != null) {
        String timestampStr = match.group(1)?.trim() ?? '';
        String sender = match.group(2)?.trim() ?? '';
        String message = match.group(3)?.trim() ?? '';
        
        DateTime timestamp = _parseTimestamp(timestampStr);
        
        entries.add(ConversationEntry(
          sender: sender,
          content: message,
          timestamp: timestamp,
        ));
        continue;
      }
      
      match = pattern5.firstMatch(line);
      if (match != null) {
        String dateStr = match.group(1)?.trim() ?? '';
        String timeStr = match.group(2)?.trim() ?? '';
        String sender = match.group(3)?.trim() ?? '';
        String message = match.group(4)?.trim() ?? '';
        
        String fullTimestamp = '$dateStr, $timeStr';
        DateTime timestamp = _parseTimestamp(fullTimestamp);
        
        entries.add(ConversationEntry(
          sender: sender,
          content: message,
          timestamp: timestamp,
        ));
        continue;
      }
    }
    
    return entries;
  }
  
  DateTime _parseTimestamp(String timestampStr) {
    DateTime timestamp;
    try {
      // Try various date formats common in chat exports
      
      // Format: yyyy-MM-dd HH:mm:ss
      timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestampStr);
    } catch (e) {
      try {
        // Format: MM/dd/yyyy HH:mm:ss
        timestamp = DateFormat('MM/dd/yyyy HH:mm:ss').parse(timestampStr);
      } catch (e) {
        try {
          // Format: dd/MM/yyyy, HH:mm
          timestamp = DateFormat('dd/MM/yyyy, HH:mm').parse(timestampStr);
        } catch (e) {
          try {
            // Format: dd.MM.yyyy, h:mm a (Romanian WhatsApp format, replacing p.m./a.m. with PM/AM)
            // First, normalize the timestamp
            String normalizedStr = timestampStr
                .replaceAll('p.m.', 'PM')
                .replaceAll('a.m.', 'AM');
            timestamp = DateFormat('dd.MM.yyyy, h:mm a').parse(normalizedStr);
          } catch (e) {
            try {
              // Try another Romanian WhatsApp pattern
              String normalizedStr = timestampStr
                  .replaceAll('p.m.', 'PM')
                  .replaceAll('a.m.', 'AM');
              timestamp = DateFormat('d.MM.yyyy, h:mm a').parse(normalizedStr);
            } catch (e) {
              try {
                // Format: HH:mm dd/MM/yyyy
                timestamp = DateFormat('HH:mm dd/MM/yyyy').parse(timestampStr);
              } catch (e) {
                try {
                  // Format: yyyy-MM-ddTHH:mm:ss (ISO format)
                  timestamp = DateTime.parse(timestampStr);
                } catch (e) {
                  print('Failed to parse timestamp: $timestampStr - $e');
                  // Default to current time if parsing fails
                  timestamp = DateTime.now();
                }
              }
            }
          }
        }
      }
    }
    return timestamp;
  }
  
  Future<void> _generateSummary() async {
    if (_selectedPerson == null || _selectedDate == null) return;
    
    setState(() {
      _summary = null;
      _isLoading = true;
    });
    
    try {
      // Filter conversation entries for the selected date
      final selectedDateOnly = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      
      List<ConversationEntry> relevantEntries = _conversationEntries.where((entry) {
        // Check if entry is from the selected date
        final entryDateOnly = DateTime(
          entry.timestamp.year,
          entry.timestamp.month,
          entry.timestamp.day,
        );
        
        // We want conversations between the selected person and the user
        final isSelectedPerson = entry.sender == _selectedPerson!.name;
        final isFromSelectedDate = entryDateOnly.isAtSameMomentAs(selectedDateOnly);
        
        return isFromSelectedDate && (isSelectedPerson || isConversationWithSelectedPerson(entry));
      }).toList();
      
      // Sort entries by timestamp
      relevantEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (relevantEntries.isEmpty) {
        setState(() {
          _summary = 'No conversation found for ${_selectedPerson!.name} on ${DateFormat('MMM d, yyyy').format(_selectedDate!)}';
          _isLoading = false;
        });
        return;
      }
      
      // Format the conversation entries for summarization
      final List<String> formattedMessages = relevantEntries.map((entry) {
        final timeStr = DateFormat('HH:mm').format(entry.timestamp);
        return '${entry.sender} ($timeStr): ${entry.content}';
      }).toList();
      
      // Call the API service to generate a summary
      final result = await _apiService.summarizeMessages(formattedMessages);
      final summary = result['summary'] as String? ?? 'Failed to generate summary.';
      
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error generating summary: $e');
      setState(() {
        _summary = 'Error generating summary: $e';
        _isLoading = false;
      });
    }
  }
  
  bool isConversationWithSelectedPerson(ConversationEntry entry) {
    // Look for conversation partners in the message content
    // This is a simplified approach - in a real app, you would need more
    // sophisticated analysis to determine conversation participants
    
    // Example: Check if the message mentions the selected person
    if (entry.content.toLowerCase().contains(_selectedPerson!.name.toLowerCase())) {
      return true;
    }
    
    // Example: If the message is from someone else, it might be a response to the selected person
    if (entry.sender != _selectedPerson!.name) {
      // Find nearby messages from the selected person
      final selectedDateOnly = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      
      final nearbySenderMessages = _conversationEntries.where((e) {
        // Check if it's from the selected person on the same day
        final entryDateOnly = DateTime(
          e.timestamp.year,
          e.timestamp.month,
          e.timestamp.day,
        );
        
        return e.sender == _selectedPerson!.name && 
               entryDateOnly.isAtSameMomentAs(selectedDateOnly) &&
               (e.timestamp.difference(entry.timestamp).inMinutes.abs() < 30); // Within 30 minutes
      });
      
      return nearbySenderMessages.isNotEmpty;
    }
    
    return false;
  }

  void _generateSampleData() async {
    // Create a temporary directory to save the sample file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/sample_conversation.txt');
    
    // Generate a sample conversation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final sampleConversation = '''
Rares: Hey, how are you doing today? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 9, minutes: 30)))}]
You: I'm good, thanks! How about you? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 9, minutes: 32)))}]
Rares: Doing well. Do you want to meet up for coffee tomorrow at 3pm? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 9, minutes: 35)))}]
You: Sure, that sounds great! Where were you thinking? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 9, minutes: 40)))}]
Rares: How about that new café downtown? I heard they have great pastries. [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 9, minutes: 45)))}]
You: Perfect! I'll see you there at 3pm tomorrow. [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 9, minutes: 50)))}]
Rares: Looking forward to it! [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 9, minutes: 52)))}]

Maria: Did you finish the project? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday.add(const Duration(hours: 14, minutes: 15)))}]
You: Almost done, I'll send it to you by the end of the day. [${DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday.add(const Duration(hours: 14, minutes: 20)))}]
Maria: Great! We have the presentation tomorrow at 10am. [${DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday.add(const Duration(hours: 14, minutes: 25)))}]
You: I'll be ready. Do you want to go through it together before the meeting? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday.add(const Duration(hours: 14, minutes: 30)))}]
Maria: Yes, let's meet at 9am to review everything. [${DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday.add(const Duration(hours: 14, minutes: 35)))}]
You: Works for me. See you tomorrow! [${DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday.add(const Duration(hours: 14, minutes: 40)))}]

Alex: Hey, are we still on for the movie tonight? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 13, minutes: 10)))}]
You: Absolutely! What time is the showing again? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 13, minutes: 15)))}]
Alex: It starts at 8pm. Want to grab dinner before at 6:30? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 13, minutes: 20)))}]
You: Sounds like a plan. Where should we meet for dinner? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 13, minutes: 25)))}]
Alex: How about that Italian place near the theater? [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 13, minutes: 30)))}]
You: Perfect! See you there at 6:30. [${DateFormat('yyyy-MM-dd HH:mm:ss').format(today.add(const Duration(hours: 13, minutes: 35)))}]
''';
    
    // Write the sample conversation to a file
    await file.writeAsString(sampleConversation);
    
    // Process the sample file
    setState(() {
      _uploadedFiles = [file];
      _isLoading = true;
    });
    
    await _processFiles(_uploadedFiles);
    
    setState(() {
      _isLoading = false;
    });
    
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample data generated successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 