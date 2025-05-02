import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AskMeUI extends StatefulWidget {
  final String platformName;
  final Color platformColor;
  final TextEditingController controller;
  final List<String> chatLog;
  final Function(String) onQuestionSubmitted;
  final bool isDateSelected;

  const AskMeUI({
    super.key,
    required this.platformName,
    required this.platformColor,
    required this.controller,
    required this.chatLog,
    required this.onQuestionSubmitted,
    required this.isDateSelected,
  });

  @override
  State<AskMeUI> createState() => _AskMeUIState();
}

class _AskMeUIState extends State<AskMeUI> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ask me about this conversation',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.platformColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isDateSelected ? 'Date Selected' : 'All Messages',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: widget.platformColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildQuestionInput(),
        const SizedBox(height: 16),
        if (widget.chatLog.isNotEmpty) _buildChatLog(),
      ],
    );
  }

  Widget _buildQuestionInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.platformColor.withAlpha(128)),
            ),
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: 'Type your question...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onQuestionSubmitted(value.trim());
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final text = widget.controller.text.trim();
            if (text.isNotEmpty) {
              widget.onQuestionSubmitted(text);
            }
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: widget.platformColor,
          ),
          child: const Icon(Icons.send, size: 18, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildChatLog() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.platformColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conversation History',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.platformColor,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ],
          ),
          if (_isExpanded)
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                itemCount: widget.chatLog.length,
                itemBuilder: (context, index) {
                  final message = widget.chatLog[widget.chatLog.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? widget.platformColor.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            ...widget.chatLog
                .take(3)
                .toList()
                .reversed
                .map((msg) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }
} 