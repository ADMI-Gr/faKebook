import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Texto expandible reutilizable
class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    this.trimLength = 160,
    this.midTrimLength,
  });

  final String text;
  final int trimLength;
  final int? midTrimLength;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  int _stage = 0;
  late TapGestureRecognizer _moreRecognizer;
  late TapGestureRecognizer _moreMoreRecognizer;
  late TapGestureRecognizer _lessRecognizer;

  @override
  void initState() {
    super.initState();
    _moreRecognizer = TapGestureRecognizer()..onTap = _toMidOrFull;
    _moreMoreRecognizer = TapGestureRecognizer()..onTap = _toFull;
    _lessRecognizer = TapGestureRecognizer()..onTap = _collapse;
  }

  String _safeCut(String input, int limit) {
    if (input.length <= limit) return input;
    // Buscar último espacio antes o en el límite para no cortar palabras
    final cutIndex = input.lastIndexOf(RegExp(r'\s'), limit);
    if (cutIndex > 0) {
      return input.substring(0, cutIndex).trimRight();
    }
    // Si no hay espacios, cortar en el límite (palabra muy larga)
    return input.substring(0, limit).trimRight();
  }

  void _toMidOrFull() {
    final fullText = widget.text.trim();
    final midLen = widget.midTrimLength ?? (widget.trimLength * 2);
    setState(() => _stage = fullText.length > midLen ? 1 : 2);
  }

  void _toFull() => setState(() => _stage = 2);
  void _collapse() => setState(() => _stage = 0);

  @override
  void dispose() {
    _moreRecognizer.dispose();
    _moreMoreRecognizer.dispose();
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
    final midLen = widget.midTrimLength ?? (widget.trimLength * 2);

    if (fullText.length <= widget.trimLength) {
      return Text(fullText, style: baseStyle);
    }

    if (_stage == 2) {
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

    if (_stage == 1) {
      final visibleMid = _safeCut(fullText, midLen);
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: '$visibleMid... '),
            TextSpan(
              text: 'Ver mas...',
              style: baseStyle.copyWith(color: Colors.blue),
              recognizer: _moreMoreRecognizer,
            ),
          ],
        ),
      );
    }

    final visible = _safeCut(fullText, widget.trimLength);
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '$visible... '),
          TextSpan(
            text: 'Ver mas..',
            style: baseStyle.copyWith(color: Colors.blue),
            recognizer: _moreRecognizer,
          ),
        ],
      ),
    );
  }
}
