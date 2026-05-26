import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:focusguard/features/appblocker/models/blocked_app.dart';

class InstalledAppModel {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final bool isSystemApp;
  final AppCategory category;

  const InstalledAppModel({
    required this.packageName,
    required this.appName,
    required this.icon,
    required this.isSystemApp,
    required this.category,
  });
}