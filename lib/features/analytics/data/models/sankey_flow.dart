import 'package:flutter/material.dart';

class SankeyNode {
  final String id;
  final String label;
  final Color color;
  final double amount;

  const SankeyNode({
    required this.id,
    required this.label,
    required this.color,
    required this.amount,
  });
}

class SankeyLink {
  final String sourceId;
  final String targetId;
  final double amount;
  final Color color;

  const SankeyLink({
    required this.sourceId,
    required this.targetId,
    required this.amount,
    required this.color,
  });
}

class SankeyData {
  final List<SankeyNode> sourceNodes;
  final List<SankeyNode> targetNodes;
  final List<SankeyNode>? middleNodes;
  final List<SankeyLink> links;

  const SankeyData({
    required this.sourceNodes,
    required this.targetNodes,
    this.middleNodes,
    required this.links,
  });

  bool get isEmpty => sourceNodes.isEmpty && targetNodes.isEmpty;
}
