   import 'package:flutter/material.dart';

bool isRtl(String text) {
  final rtl = RegExp(
      r'[\u0591-\u07FF\u200F\u202B\u202E\uFB1D-\uFDFD\uFE70-\uFEFC]');
  for (final char in text.characters) {
    if (rtl.hasMatch(char)) return true;
    if (RegExp(r'[A-Za-z]').hasMatch(char)) return false;
  }
  return false;
}

TextDirection directionOf(String text) =>
    isRtl(text) ? TextDirection.rtl : TextDirection.ltr;