import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSent;

  const ChatBubble({super.key, required this.text, this.isSent = true});

  @override
  Widget build(BuildContext context) {
    final bg = isSent ? Colors.blue[100] : Colors.grey[200];
    final align = isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text),
        ),
      ],
    );
  }
}
