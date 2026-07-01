import 'package:flutter/material.dart';

/// RF Village brand palette (from RF VILLAGE.png).
abstract final class AppColors {
  static const villageBlack = Color(0xFF1D1D1B);
  static const villagePanel = Color(0xFF121821);
  static const villageGreen = Color(0xFF40DE7D);
  static const villagePurple = Color(0xFF7E30D8);
  static const villagePurpleDeep = Color(0xFF552A87);
  static const villagePurpleDarker = Color(0xFF472FA5);
  static const villageCyan = Color(0xFF00E5FF);
  static const villageText = Color(0xFFEAF2FF);
  static const warningAmber = Color(0xFFFFC857);
  static const errorRed = Color(0xFFFF4D6D);

  // Legacy aliases used across the app.
  static const electricPink = villagePurple;
  static const cyberGreen = villageGreen;
  static const deepPurple = villagePurpleDeep;
  static const terminalBlack = villageBlack;
  static const panelBlack = villagePanel;
  static const softWhite = villageText;
}
