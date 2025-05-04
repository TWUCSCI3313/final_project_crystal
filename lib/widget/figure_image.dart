import 'package:flutter/material.dart';

Widget figureImage(bool visible, String path, bool isDarkMode) {
  return Visibility(
    visible: visible,
    child: Image.asset(
      path,
      color: isDarkMode ? Colors.white : null,
    ),
  );
}