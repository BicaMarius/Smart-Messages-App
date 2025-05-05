import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AskMeUI extends StatefulWidget {
  final String platformName;
  final Color platformColor;
  final TextEditingController controller;
  final List<String> chatLog;
  final Function(String) onQuestionSubmitted;
  final bool isDateSelected;
  final Function(bool) onModeChanged;

  const AskMeUI({
    super.key,
    required this.platformName,
    required this.platformColor,
    required this.controller,
    required this.chatLog,
    required this.onQuestionSubmitted,
    required this.isDateSelected,
    required this.onModeChanged,
  });

  @override
  State<AskMeUI> createState() => _AskMeUIState();
}

class _AskMeUIState extends State<AskMeUI> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _handleQuestionSubmitted(String question) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onQuestionSubmitted(question);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Dismiss keyboard when tapping anywhere outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask me about this conversation',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: widget.platformColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildModeButton(
                label: 'All Conversations',
                isSelected: !widget.isDateSelected,
                onTap: () {
                  if (widget.isDateSelected) {
                    widget.onModeChanged(false);
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                label: 'Date Selected',
                isSelected: widget.isDateSelected,
                onTap: () {
                  if (!widget.isDateSelected) {
                    widget.onModeChanged(true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuestionInput(),
          const SizedBox(height: 16),
          if (widget.chatLog.isNotEmpty) _buildChatLog(),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.platformColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? widget.platformColor
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? widget.platformColor : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
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
              focusNode: _focusNode,
              enabled: !_isLoading,
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
                  _handleQuestionSubmitted(value.trim());
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  final text = widget.controller.text.trim();
                  if (text.isNotEmpty) {
                    _handleQuestionSubmitted(text);
                  }
                },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: widget.platformColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: _loadingAnimation.value,
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send, size: 18, color: Colors.white),
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
          Text(
            'Conversation History',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.platformColor,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 300,
              minHeight: 0,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.chatLog.length,
              itemBuilder: (context, index) {
                // Reverse the index to show newest messages at the top
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
          ),
        ],
      ),
    );
  }
} 