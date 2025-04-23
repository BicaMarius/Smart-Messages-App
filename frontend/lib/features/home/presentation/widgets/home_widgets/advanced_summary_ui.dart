import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdvancedSummaryUI extends StatelessWidget {
  final String platformName;
  final Color platformColor;
  final List<String> uploadedFiles;
  final List<String> availablePeople;
  final String? selectedPerson;
  final DateTime? selectedDate;
  final String? conversationSummary;
  final bool isSummarizing;
  final Function(String) onFileUpload;
  final Function(String, String) onFileDelete;
  final Function(String) onPersonSelected;
  final Function() onDateSelected;
  final Function() onGenerateSummary;

  const AdvancedSummaryUI({
    super.key,
    required this.platformName,
    required this.platformColor,
    required this.uploadedFiles,
    required this.availablePeople,
    required this.selectedPerson,
    required this.selectedDate,
    required this.conversationSummary,
    required this.isSummarizing,
    required this.onFileUpload,
    required this.onFileDelete,
    required this.onPersonSelected,
    required this.onDateSelected,
    required this.onGenerateSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFileSection(),
        const Divider(height: 24),
        _buildPersonAndDateSection(),
        if (selectedPerson != null && selectedDate != null) ...[
          const SizedBox(height: 20),
          _buildSummarySection(),
        ],
      ],
    );
  }

  Widget _buildFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () => onFileUpload(platformName),
            ),
          ],
        ),
        if (uploadedFiles.isEmpty)
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
            child: _buildFileList(),
          ),
      ],
    );
  }

  Widget _buildFileList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: uploadedFiles.map((filePath) {
        final fileName = filePath.split('/').last;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, color: platformColor, size: 16),
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
                onPressed: () => onFileDelete(platformName, filePath),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPersonAndDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
          child: _buildPersonDropdown(),
        ),
        if (selectedPerson != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.calendar_today, size: 18, color: platformColor),
                  label: Text(
                    selectedDate != null
                        ? 'Date: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                        : 'Select a date',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: platformColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onDateSelected,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPersonDropdown() {
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
      value: selectedPerson,
      items: availablePeople.map((person) {
        return DropdownMenuItem<String>(
          value: person,
          child: Text(
            person,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        );
      }).toList(),
      onChanged: (value) => onPersonSelected(value!),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.summarize, color: platformColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Conversation Summary',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (conversationSummary != null && !isSummarizing)
              IconButton(
                icon: Icon(Icons.refresh, color: platformColor),
                tooltip: 'Refresh summary',
                onPressed: onGenerateSummary,
              ),
          ],
        ),
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
          child: isSummarizing
              ? _buildLoadingIndicator()
              : conversationSummary != null
                  ? _buildSummaryText()
                  : _buildEmptySummary(),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
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
    );
  }

  Widget _buildSummaryText() {
    return SingleChildScrollView(
      child: Text(
        _cleanupSummary(conversationSummary!),
        style: GoogleFonts.poppins(height: 1.5),
      ),
    );
  }

  Widget _buildEmptySummary() {
    return Center(
      child: Text(
        'Summary will appear here',
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  String _cleanupSummary(String summary) {
    if (summary.contains('EVENIMENTE_DETECTATE') || summary.contains('EVENTS_DETECTED')) {
      final parts = summary.split(RegExp(r'EVENIMENTE_DETECTATE|EVENTS_DETECTED'));
      return parts[0].trim();
    }
    return summary;
  }
} 