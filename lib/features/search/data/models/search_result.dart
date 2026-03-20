import 'package:flutter/material.dart';

enum SearchResultType { transaction, account, category, tag }

class GlobalSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final IconData icon;
  final Color color;
  final String? route;
  /// The portion of the result that matched the query (for highlighting).
  final String? matchedField;

  const GlobalSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.color,
    this.route,
    this.matchedField,
  });
}
