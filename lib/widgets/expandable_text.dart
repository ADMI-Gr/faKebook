import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Texto expandible reutilizable
class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    this.trimLength = 147,
  });

  final String text;
  final int trimLength;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;
  late TapGestureRecognizer _moreRecognizer;
  late TapGestureRecognizer _lessRecognizer;

  @override
  void initState() {
    super.initState();
    _moreRecognizer = TapGestureRecognizer()..onTap = _expand;
    _lessRecognizer = TapGestureRecognizer()..onTap = _collapse;
  }

  void _expand() => setState(() => _expanded = true);
  void _collapse() => setState(() => _expanded = false);

  @override
  void dispose() {
    _moreRecognizer.dispose();
    _lessRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: Colors.black87,
    );

    final fullText = widget.text.trim();
    if (fullText.length <= widget.trimLength) {
      return Text(fullText, style: baseStyle);
    }

    if (_expanded) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: fullText),
            const TextSpan(text: ' '),
            TextSpan(
              text: 'Ver menos',
              style: baseStyle.copyWith(color: Colors.blue),
              recognizer: _lessRecognizer,
            ),
          ],
        ),
      );
    }

    final visible = fullText.substring(0, widget.trimLength).trimRight();
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '$visible... '),
          TextSpan(
            text: 'Ver mas',
            style: baseStyle.copyWith(color: Colors.blue),
            recognizer: _moreRecognizer,
          ),
        ],
      ),
    );
  }
}
