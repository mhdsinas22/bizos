import 'package:pdf/pdf.dart';

class KpiMetricsModel {
  final double totalRevenue;
  final double totalExpense;
  final double grossProfit;
  final double netProfit;
  final double profitMarginPct;
  final double totalSales;
  final double totalPurchases;
  final double cashIn;
  final double cashOut;
  final double openingBalance;
  final double closingBalance;
  final double pendingReceivables;
  final double pendingPayables;
  final int totalCustomers;
  final int totalSuppliers;
  final int totalProducts;
  final int totalTransactions;

  const KpiMetricsModel({
    required this.totalRevenue,
    required this.totalExpense,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMarginPct,
    required this.totalSales,
    required this.totalPurchases,
    required this.cashIn,
    required this.cashOut,
    required this.openingBalance,
    required this.closingBalance,
    required this.pendingReceivables,
    required this.pendingPayables,
    required this.totalCustomers,
    required this.totalSuppliers,
    required this.totalProducts,
    required this.totalTransactions,
  });
}

class MonthlyAnalyticsItem {
  final int monthNumber;
  final String monthName;
  final double revenue;
  final double expense;
  final double profit;
  final double sales;
  final double purchases;
  final double growthPct;

  const MonthlyAnalyticsItem({
    required this.monthNumber,
    required this.monthName,
    required this.revenue,
    required this.expense,
    required this.profit,
    required this.sales,
    required this.purchases,
    required this.growthPct,
  });
}

class MonthlyAnalyticsModel {
  final List<MonthlyAnalyticsItem> monthlyItems;
  final String highestRevenueMonth;
  final double highestRevenueMonthAmount;
  final String lowestRevenueMonth;
  final double lowestRevenueMonthAmount;
  final String highestExpenseMonth;
  final double highestExpenseMonthAmount;
  final String lowestExpenseMonth;
  final double lowestExpenseMonthAmount;
  final String highestProfitMonth;
  final double highestProfitMonthAmount;
  final String highestLossMonth;
  final double highestLossMonthAmount;
  final String highestSalesMonth;
  final double highestSalesMonthAmount;
  final String highestPurchaseMonth;
  final double highestPurchaseMonthAmount;

  const MonthlyAnalyticsModel({
    required this.monthlyItems,
    required this.highestRevenueMonth,
    required this.highestRevenueMonthAmount,
    required this.lowestRevenueMonth,
    required this.lowestRevenueMonthAmount,
    required this.highestExpenseMonth,
    required this.highestExpenseMonthAmount,
    required this.lowestExpenseMonth,
    required this.lowestExpenseMonthAmount,
    required this.highestProfitMonth,
    required this.highestProfitMonthAmount,
    required this.highestLossMonth,
    required this.highestLossMonthAmount,
    required this.highestSalesMonth,
    required this.highestSalesMonthAmount,
    required this.highestPurchaseMonth,
    required this.highestPurchaseMonthAmount,
  });
}

class DailyAnalyticsModel {
  final String highestRevenueDay;
  final double highestRevenueDayAmount;
  final String highestExpenseDay;
  final double highestExpenseDayAmount;
  final String highestSalesDay;
  final double highestSalesDayAmount;
  final String highestPurchaseDay;
  final double highestPurchaseDayAmount;
  final double avgRevenuePerDay;
  final double avgExpensePerDay;
  final double avgProfitPerDay;

  const DailyAnalyticsModel({
    required this.highestRevenueDay,
    required this.highestRevenueDayAmount,
    required this.highestExpenseDay,
    required this.highestExpenseDayAmount,
    required this.highestSalesDay,
    required this.highestSalesDayAmount,
    required this.highestPurchaseDay,
    required this.highestPurchaseDayAmount,
    required this.avgRevenuePerDay,
    required this.avgExpensePerDay,
    required this.avgProfitPerDay,
  });
}

class CustomerAnalyticsItem {
  final String name;
  final double totalAmount;
  final double contributionPct;
  final int transactionCount;

  const CustomerAnalyticsItem({
    required this.name,
    required this.totalAmount,
    required this.contributionPct,
    required this.transactionCount,
  });
}

class CustomerAnalyticsModel {
  final int totalCustomers;
  final int newCustomers;
  final int returningCustomers;
  final String highestPayingCustomer;
  final double highestPayingCustomerAmount;
  final double avgCustomerSpend;
  final int outstandingCustomersCount;
  final List<CustomerAnalyticsItem> top10Customers;

  const CustomerAnalyticsModel({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.highestPayingCustomer,
    required this.highestPayingCustomerAmount,
    required this.avgCustomerSpend,
    required this.outstandingCustomersCount,
    required this.top10Customers,
  });
}

class SupplierAnalyticsItem {
  final String name;
  final double totalAmount;
  final double contributionPct;
  final int transactionCount;

  const SupplierAnalyticsItem({
    required this.name,
    required this.totalAmount,
    required this.contributionPct,
    required this.transactionCount,
  });
}

class SupplierAnalyticsModel {
  final int totalSuppliers;
  final String largestSupplier;
  final double largestSupplierAmount;
  final String highestPurchaseSupplier;
  final double highestPurchaseSupplierAmount;
  final double outstandingPayables;
  final List<SupplierAnalyticsItem> topSuppliers;

  const SupplierAnalyticsModel({
    required this.totalSuppliers,
    required this.largestSupplier,
    required this.largestSupplierAmount,
    required this.highestPurchaseSupplier,
    required this.highestPurchaseSupplierAmount,
    required this.outstandingPayables,
    required this.topSuppliers,
  });
}

class ProductAnalyticsItem {
  final String name;
  final double revenue;
  final int unitsSold;
  final String status;

  const ProductAnalyticsItem({
    required this.name,
    required this.revenue,
    required this.unitsSold,
    required this.status,
  });
}

class ProductAnalyticsModel {
  final String bestSellingProduct;
  final String leastSellingProduct;
  final String highestRevenueProduct;
  final String lowestRevenueProduct;
  final String fastMovingProduct;
  final String slowMovingProduct;
  final int deadStockCount;
  final int lowStockItemsCount;
  final List<ProductAnalyticsItem> topSellingProducts;

  const ProductAnalyticsModel({
    required this.bestSellingProduct,
    required this.leastSellingProduct,
    required this.highestRevenueProduct,
    required this.lowestRevenueProduct,
    required this.fastMovingProduct,
    required this.slowMovingProduct,
    required this.deadStockCount,
    required this.lowStockItemsCount,
    required this.topSellingProducts,
  });
}

class PaymentAnalyticsItem {
  final String method;
  final double amount;
  final double percentage;
  final int count;

  const PaymentAnalyticsItem({
    required this.method,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

class PaymentAnalyticsModel {
  final List<PaymentAnalyticsItem> paymentBreakdown;

  const PaymentAnalyticsModel({
    required this.paymentBreakdown,
  });
}

class CategoryAnalyticsItem {
  final String categoryName;
  final double amount;
  final double contributionPct;

  const CategoryAnalyticsItem({
    required this.categoryName,
    required this.amount,
    required this.contributionPct,
  });
}

class CategoryAnalyticsModel {
  final List<CategoryAnalyticsItem> topExpenseCategories;
  final String highestExpenseCategory;
  final String lowestExpenseCategory;
  final List<CategoryAnalyticsItem> revenueSources;
  final String topRevenueCategory;
  final String lowestRevenueCategory;

  const CategoryAnalyticsModel({
    required this.topExpenseCategories,
    required this.highestExpenseCategory,
    required this.lowestExpenseCategory,
    required this.revenueSources,
    required this.topRevenueCategory,
    required this.lowestRevenueCategory,
  });
}

class ComparisonAnalyticsModel {
  final double currentMonthRevenue;
  final double prevMonthRevenue;
  final double revenueDiff;
  final double revenueGrowthPct;
  final double currentMonthExpense;
  final double prevMonthExpense;
  final double expenseDiff;
  final double expenseGrowthPct;
  final double currentMonthProfit;
  final double prevMonthProfit;
  final double profitDiff;
  final double profitGrowthPct;

  const ComparisonAnalyticsModel({
    required this.currentMonthRevenue,
    required this.prevMonthRevenue,
    required this.revenueDiff,
    required this.revenueGrowthPct,
    required this.currentMonthExpense,
    required this.prevMonthExpense,
    required this.expenseDiff,
    required this.expenseGrowthPct,
    required this.currentMonthProfit,
    required this.prevMonthProfit,
    required this.profitDiff,
    required this.profitGrowthPct,
  });
}

class YearlyAnalyticsModel {
  final int year;
  final List<MonthlyAnalyticsItem> monthlySummary;

  const YearlyAnalyticsModel({
    required this.year,
    required this.monthlySummary,
  });
}

class HealthScoreModel {
  final int score; // 0 to 100
  final String status; // 'EXCELLENT', 'GOOD', 'AVERAGE', 'NEEDS IMPROVEMENT'
  final PdfColor color;

  const HealthScoreModel({
    required this.score,
    required this.status,
    required this.color,
  });
}

class TaskAnalyticsModel {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int inProgressTasks;
  final double completionRatePct;
  final double avgCompletionDays;
  final int highPriorityCount;
  final int mediumPriorityCount;
  final int lowPriorityCount;
  final String mostActiveStaff;
  final Map<String, int> staffTaskCounts;
  final Map<String, int> monthlyCompletionCounts;

  const TaskAnalyticsModel({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.inProgressTasks,
    required this.completionRatePct,
    required this.avgCompletionDays,
    required this.highPriorityCount,
    required this.mediumPriorityCount,
    required this.lowPriorityCount,
    required this.mostActiveStaff,
    required this.staffTaskCounts,
    required this.monthlyCompletionCounts,
  });
}

class StaffPerformanceItem {
  final String staffName;
  final int assigned;
  final int completed;
  final int pending;
  final int overdue;
  final double completionPct;

  const StaffPerformanceItem({
    required this.staffName,
    required this.assigned,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.completionPct,
  });
}

class StaffAnalyticsModel {
  final int totalStaff;
  final int activeStaff;
  final int totalAssignedTasks;
  final int totalCompletedTasks;
  final int totalPendingTasks;
  final int totalOverdueTasks;
  final double overallCompletionPct;
  final List<StaffPerformanceItem> staffPerformance;

  const StaffAnalyticsModel({
    required this.totalStaff,
    required this.activeStaff,
    required this.totalAssignedTasks,
    required this.totalCompletedTasks,
    required this.totalPendingTasks,
    required this.totalOverdueTasks,
    required this.overallCompletionPct,
    required this.staffPerformance,
  });
}

class BusinessAnalyticsData {
  final KpiMetricsModel kpis;
  final MonthlyAnalyticsModel monthly;
  final DailyAnalyticsModel daily;
  final CustomerAnalyticsModel customers;
  final SupplierAnalyticsModel suppliers;
  final ProductAnalyticsModel products;
  final PaymentAnalyticsModel payment;
  final CategoryAnalyticsModel categories;
  final ComparisonAnalyticsModel comparison;
  final YearlyAnalyticsModel yearly;
  final HealthScoreModel healthScore;
  final TaskAnalyticsModel taskAnalytics;
  final StaffAnalyticsModel staffAnalytics;
  final List<String> insights;
  final List<String> riskWarnings;

  const BusinessAnalyticsData({
    required this.kpis,
    required this.monthly,
    required this.daily,
    required this.customers,
    required this.suppliers,
    required this.products,
    required this.payment,
    required this.categories,
    required this.comparison,
    required this.yearly,
    required this.healthScore,
    required this.taskAnalytics,
    required this.staffAnalytics,
    required this.insights,
    required this.riskWarnings,
  });
}
