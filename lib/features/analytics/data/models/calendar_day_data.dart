class CalendarDayData {
  final DateTime date;
  final double income;
  final double expense;
  final double net;
  final int intensity; // 0-4

  const CalendarDayData({
    required this.date,
    required this.income,
    required this.expense,
    required this.net,
    required this.intensity,
  });
}
