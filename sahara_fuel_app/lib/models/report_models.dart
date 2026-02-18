class ReportRow {
  final String type;
  final int prevBalance, expense, sales, purchase, currentBalance, avgPrice;
  ReportRow(
      {required this.type,
      required this.prevBalance,
      required this.expense,
      required this.sales,
      required this.purchase,
      required this.currentBalance,
      required this.avgPrice});
}

class StationReport {
  final String name;
  final int consumed, balance, efficiency;
  StationReport(
      {required this.name,
      required this.consumed,
      required this.balance,
      required this.efficiency});
}
