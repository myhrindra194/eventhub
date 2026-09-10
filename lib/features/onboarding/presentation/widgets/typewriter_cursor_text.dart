import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterCursorText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration typingSpeed;
  final Duration pauseAfterTyping;
  final Duration pauseAfterErasing;
  final Duration erasingSpeed;

  const TypewriterCursorText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
    this.typingSpeed = const Duration(milliseconds: 40),
    this.erasingSpeed = const Duration(milliseconds: 20),
    this.pauseAfterTyping = const Duration(milliseconds: 1400),
    this.pauseAfterErasing = const Duration(milliseconds: 300),
  });

  @override
  State<TypewriterCursorText> createState() => _TypewriterCursorTextState();
}

class _TypewriterCursorTextState extends State<TypewriterCursorText>
    with TickerProviderStateMixin {
  late final AnimationController _cursorController;

  int _charCount = 0;
  Timer? _typingTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _startLoop();
  }

  void _startLoop() async {
    while (!_disposed) {
      for (int i = 0; i <= widget.text.length; i++) {
        if (_disposed) return;
        setState(() => _charCount = i);
        await Future.delayed(widget.typingSpeed);
      }

      if (_disposed) return;
      await Future.delayed(widget.pauseAfterTyping);

      for (int i = widget.text.length; i >= 0; i--) {
        if (_disposed) return;
        setState(() => _charCount = i);
        await Future.delayed(widget.erasingSpeed);
      }

      if (_disposed) return;
      await Future.delayed(widget.pauseAfterErasing);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _typingTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _charCount);

    return RichText(
      textAlign: widget.textAlign,
      text: TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: visibleText),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: FadeTransition(
              opacity: _cursorController,
              child: Text('|', style: widget.style),
            ),
          ),
        ],
      ),
    );
  }
}
