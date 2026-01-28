import 'package:flutter/material.dart';

enum InsightType { spending, saving, trend, anomaly, recurring, forecast, pattern, goal }

enum InsightSentiment { positive, negative, neutral }

enum InsightPriority { high, medium, low }

class FinancialInsight {
  final String message;
  final InsightType type;
  final InsightSentiment sentiment;
  final IconData icon;
  final InsightPriority priority;
  final double? value;
  final String? categoryId;
  final Map<String, dynamic>? metadata;

  const FinancialInsight({
    required this.message,
    required this.type,
    required this.sentiment,
    required this.icon,
    this.priority = InsightPriority.medium,
    this.value,
    this.categoryId,
    this.metadata,
  });
}
