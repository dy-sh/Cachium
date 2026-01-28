import 'package:flutter/material.dart';

class WaterfallEntry {
  final String label;
  final double amount;
  final double runningTotal;
  final WaterfallEntryType type;
  final Color color;
  final String? categoryId;

  const WaterfallEntry({
    required this.label,
    required this.amount,
    required this.runningTotal,
    required this.type,
    required this.color,
    this.categoryId,
  });
}

enum WaterfallEntryType { income, expense, netTotal }
