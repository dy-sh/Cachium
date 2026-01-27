class SpendingProfile {
  final String label;
  final List<SpendingProfileAxis> axes;

  const SpendingProfile({
    required this.label,
    required this.axes,
  });
}

class SpendingProfileAxis {
  final String categoryName;
  final double value; // 0.0 to 1.0 normalized
  final double rawAmount;

  const SpendingProfileAxis({
    required this.categoryName,
    required this.value,
    required this.rawAmount,
  });
}
