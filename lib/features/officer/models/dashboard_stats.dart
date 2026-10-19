class DashboardStats {
  const DashboardStats({
    required this.totalCases,
    required this.checkedIn,
    required this.pending,
    required this.missed,
  });

  final int totalCases;
  final int checkedIn;
  final int pending;
  final int missed;
}
