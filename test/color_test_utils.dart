import 'package:flutter/material.dart';

/// Composite translucent foregrounds/backgrounds before checking contrast.
double contrastOn(Color foreground, Color background, {Color? surface}) {
  final backdrop = Color.alphaBlend(background, surface ?? Colors.white);
  final a = Color.alphaBlend(foreground, backdrop).computeLuminance();
  final b = backdrop.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}
