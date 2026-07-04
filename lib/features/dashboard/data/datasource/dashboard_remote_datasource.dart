class DashboardData {
  final int totalBusinesses;
  final double totalIncome;
  final double totalExpense;
  final double totalProfit;
  final int pendingTasks;
  final List<Map<String, dynamic>> recentActivities;
  final Map<String, Map<String, double>> monthlySummary;

  DashboardData({
    required this.totalBusinesses,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalProfit,
    required this.pendingTasks,
    required this.recentActivities,
    required this.monthlySummary,
  });
}

abstract class DashboardRemoteDatasource {
  Future<DashboardData> getDashboardData(
    String? businessId,
    String currentuserid,
  );
  Future<void> logActivity({
    String? businessId,
    required String title,
    required String description,
    required double amount,
  });
  Future<DashboardData> getSpecificBusinessData(String businessId);
}
