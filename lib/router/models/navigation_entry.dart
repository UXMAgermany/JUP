import 'package:flutter/material.dart';

enum NavigationElement { news, events, surveys, profile, help }

class NavigationEntry {
  final NavigationElement type;
  final String label;
  final Icon icon;

  NavigationEntry({
    required this.type,
    required this.icon,
    required this.label,
  });
}
