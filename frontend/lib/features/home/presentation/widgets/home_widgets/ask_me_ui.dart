import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AskMeUI extends StatelessWidget {
  final String platformName;
  final Color platformColor;
  final TextEditingController controller;
  final List<String> chatLog;
  final Function(String) onQuestionSubmitted;

  const AskMeUI({
    super.key,
    required this.platformName,
    required this.platformColor,
    required this.controller,
    required this.chatLog,
    required this.onQuestionSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask me about this conversation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildQuestionInput(),
        const SizedBox(height: 16),
        if (chatLog.isNotEmpty) _buildChatLog(),
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
              border: Border.all(color: platformColor.withAlpha(128)),
            ),
            child: TextField(
              controller: controller,
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
                  onQuestionSubmitted(value.trim());
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              onQuestionSubmitted(text);
            }
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: platformColor,
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
        border: Border.all(color: platformColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chatLog
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
    );
  }
} 