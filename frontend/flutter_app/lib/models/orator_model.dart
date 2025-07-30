import 'package:flutter/material.dart';

class Orator {
  final String id;
  final String name;
  final String mainQuote;
  final String secondaryQuote;
  final String imagePath;
  final String domain;
  final String period;
  final Color accentColor;

  const Orator({
    required this.id,
    required this.name,
    required this.mainQuote,
    required this.secondaryQuote,
    required this.imagePath,
    required this.domain,
    required this.period,
    required this.accentColor,
  });
}