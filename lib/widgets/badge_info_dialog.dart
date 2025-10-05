import 'package:flutter/material.dart';

//====== MODAL PARA LAS INSIGNIAS ======
class BadgeInfoDialog extends StatelessWidget {
  //==== ACLARACION ====
  // SE PASAN 2 FONDOS, EL BACKGROUND Y EL GRADIENTE SI NO SE PASA EL GRADIENTE SE USA EL BACKGROUND POR DEFECTO Q ES BLANCO
  final String title;
  final String description;
  final Color borderColor;
  final Color backgroundColor;
  final String? fontFamily;
  final IconData? icon;
  final Gradient? backgroundGradient;
  final TextStyle? titleTextStyle;
  final TextStyle? descriptionTextStyle;

  const BadgeInfoDialog({
    super.key,
    required this.title,
    required this.description,
    required this.borderColor,
    required this.backgroundColor,
    this.fontFamily,
    this.icon,
    this.backgroundGradient,
    this.titleTextStyle,
    this.descriptionTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textStyleTitle = titleTextStyle ?? TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFamily: fontFamily,
      color: Colors.black87,
    );

    final textStyleDesc = descriptionTextStyle ?? TextStyle(
      fontSize: 14,
      height: 1.35,
      fontFamily: fontFamily,
      color: Colors.black87,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundGradient == null ? backgroundColor : null,
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor.withOpacity(0.8)),
                    ),
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 12),
                    child: Icon(icon, size: 24, color: borderColor),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textStyleTitle),
                      const SizedBox(height: 6),
                      Text(description, style: textStyleDesc),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 22),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: borderColor,
                ),
                child: const Text('Cerrar'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<void> showBadgeInfoDialog(
  BuildContext context, {
  required String title,
  required String description,
  required Color borderColor,
  required Color backgroundColor,
  String? fontFamily,
  IconData? icon,
  Gradient? backgroundGradient,
  TextStyle? titleTextStyle,
  TextStyle? descriptionTextStyle,
}) async {
  return showDialog(
    context: context,
    builder: (_) => BadgeInfoDialog(
      title: title,
      description: description,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      fontFamily: fontFamily,
      icon: icon,
      backgroundGradient: backgroundGradient,
      titleTextStyle: titleTextStyle,
      descriptionTextStyle: descriptionTextStyle,
    ),
  );
}
