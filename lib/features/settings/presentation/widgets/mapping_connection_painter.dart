import 'package:flutter/material.dart';

import 'mapping_connection.dart';

/// CustomPainter that draws smooth S-curve bezier lines connecting
/// mapped fields between the left and right panels.
class MappingConnectionPainter extends CustomPainter {
  /// List of connections to draw.
  final List<MappingConnection> connections;

  /// X position where the gap between panels starts (end of left panel).
  final double gapStart;

  /// X position where the gap between panels ends (start of right panel).
  final double gapEnd;

  /// Top of the visible clipping area.
  final double topClip;

  /// Bottom of the visible clipping area.
  final double bottomClip;

  /// Whether preview mode is active (holding an element).
  /// Lines are brighter in preview mode.
  final bool isPreviewActive;

  MappingConnectionPainter({
    required this.connections,
    required this.gapStart,
    required this.gapEnd,
    required this.topClip,
    required this.bottomClip,
    this.isPreviewActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Clip to the visible area to avoid drawing outside the panel bounds
    canvas.clipRect(Rect.fromLTRB(0, topClip, size.width, bottomClip));

    for (final connection in connections) {
      _drawConnection(canvas, connection);
    }
  }

  void _drawConnection(Canvas canvas, MappingConnection connection) {
    final startX = gapStart;
    final endX = gapEnd;
    final startY = connection.leftY;
    final endY = connection.rightY;

    // Create the path for a horizontal S-curve
    final path = Path();
    path.moveTo(startX, startY);

    // Control points for smooth S-curve (40% into the gap)
    final controlPointOffset = (endX - startX) * 0.4;
    path.cubicTo(
      startX + controlPointOffset, // First control point X
      startY, // First control point Y (same as start)
      endX - controlPointOffset, // Second control point X
      endY, // Second control point Y (same as end)
      endX, // End point X
      endY, // End point Y
    );

    // Adjust opacity based on preview mode
    // Dimmer when not previewing, brighter when previewing
    final lineOpacity = isPreviewActive ? 1.0 : 0.4;
    final glowOpacity = isPreviewActive ? 0.3 : 0.15;
    final dotOpacity = isPreviewActive ? 1.0 : 0.5;

    // Draw glow effect first (subtle, for dark theme)
    final glowPaint = Paint()
      ..color = connection.color.withValues(alpha: glowOpacity)
      ..strokeWidth = isPreviewActive ? 6.0 : 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isPreviewActive ? 4.0 : 3.0);
    canvas.drawPath(path, glowPaint);

    // Draw main line
    final mainPaint = Paint()
      ..color = connection.color.withValues(alpha: lineOpacity)
      ..strokeWidth = isPreviewActive ? 2.0 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, mainPaint);

    // Draw small circles at connection endpoints
    final dotPaint = Paint()
      ..color = connection.color.withValues(alpha: dotOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(startX, startY), isPreviewActive ? 3.0 : 2.5, dotPaint);
    canvas.drawCircle(Offset(endX, endY), isPreviewActive ? 3.0 : 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(MappingConnectionPainter oldDelegate) {
    // Repaint if any connection data changed
    if (connections.length != oldDelegate.connections.length) return true;
    if (gapStart != oldDelegate.gapStart || gapEnd != oldDelegate.gapEnd) {
      return true;
    }
    if (topClip != oldDelegate.topClip ||
        bottomClip != oldDelegate.bottomClip) {
      return true;
    }
    if (isPreviewActive != oldDelegate.isPreviewActive) {
      return true;
    }
    for (var i = 0; i < connections.length; i++) {
      final a = connections[i];
      final b = oldDelegate.connections[i];
      if (a.fieldKey != b.fieldKey ||
          a.csvColumn != b.csvColumn ||
          a.leftY != b.leftY ||
          a.rightY != b.rightY ||
          a.color != b.color) {
        return true;
      }
    }
    return false;
  }
}
