import 'package:flutter/material.dart';

enum InsightType { spending, saving, trend, anomaly }

enum InsightSentiment { positive, negative, neutral }

class FinancialInsight {
  final String message;
  final InsightType type;
  final InsightSentiment sentiment;
  final IconData icon;

  const FinancialInsight({
    required this.message,
    required this.type,
    required this.sentiment,
    required this.icon,
  });
}
