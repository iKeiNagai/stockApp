import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const backgroundColor = Color(0xFF282A36);
  static const surfaceColor = Color(0xFF44475A);
  static const primaryColor = Color(0xFF50FA7B);
  static const accentColor = Color(0xFFFF79C6);
  static const textColor = Colors.white;
  static const secondaryTextColor = Colors.white54;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: textColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textColor,
    fontSize: 16,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 14,
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(8),
  );

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: backgroundColor,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: surfaceColor,
    foregroundColor: textColor,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // Input Decoration
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: secondaryTextColor),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
    );
  }

  // AppBar Theme
  static AppBar appBar(String title, {List<Widget>? actions, Widget? leading}) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: Text(title, style: titleStyle),
      leading: leading,
      actions: actions,
      elevation: 0,
    );
  }

  // Card Style
  static Card standardCard({required Widget child}) {
    return Card(
      color: surfaceColor,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: child,
    );
  }
}
