import 'package:flutter/material.dart';

/// Data model for a connection between a target field and a CSV column.
/// Used by MappingConnectionPainter to draw bezier curves.
class MappingConnection {
  /// The target field key (e.g., 'date', 'description', 'fk:category:name')
  final String fieldKey;

  /// The CSV column name
  final String csvColumn;

  /// Y position of the left panel item (center of the item)
  final double leftY;

  /// Y position of the right panel item (center of the item)
  final double rightY;

  /// The connection line color
  final Color color;

  const MappingConnection({
    required this.fieldKey,
    required this.csvColumn,
    required this.leftY,
    required this.rightY,
    required this.color,
  });

  @override
  String toString() =>
      'MappingConnection($fieldKey -> $csvColumn, leftY: $leftY, rightY: $rightY)';
}
