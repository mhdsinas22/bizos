import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/datasoucre/expense_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRemoteDatasourceImpl implements ExpenseRemoteDatasource {
  final SupabaseClient supabaseClient;

  ExpenseRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<ExpenseModel>> getExpenseList(String businessId) async {
    if (businessId.trim().isEmpty) return [];
    final response = await supabaseClient
        .from('expenses')
        .select()
        .eq('business_id', businessId);

    return response.map((row) => _fromRow(row)).toList();
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    final response = await supabaseClient.from('expenses').select();
    return response.map((row) => _fromRow(row)).toList();
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    final Map<String, dynamic> data = {
      'amount': expense.amount,
      'category': expense.category,
      'description': expense.description,
      'expense_date': expense.date.toIso8601String(),
      'business_id': expense.businessId.trim().isNotEmpty ? expense.businessId : null,
      'created_by_user_id': (expense.createdByUserId != null && expense.createdByUserId!.trim().isNotEmpty) ? expense.createdByUserId : null,
      'created_by_name': expense.createdByName,
    };
    if (expense.id.trim().isNotEmpty) {
      data['id'] = expense.id;
    }
    await supabaseClient.from('expenses').insert(data);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await supabaseClient
        .from('expenses')
        .update({
          'amount': expense.amount,
          'category': expense.category,
          'description': expense.description,
          'expense_date': expense.date.toIso8601String(),
        })
        .eq('id', expense.id);
  }

  @override
  Future<ExpenseModel?> deleteExpense(String id) async {
    final response = await supabaseClient.from('expenses').select().eq('id', id).maybeSingle();
    if (response != null) {
      final model = _fromRow(response);
      await supabaseClient.from('expenses').delete().eq('id', id);
      return model;
    }
    return null;
  }

  ExpenseModel _fromRow(Map<String, dynamic> row) {
    return ExpenseModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      description: row['description'] ?? '',
      date: DateTime.parse(row['expense_date'] as String),
      createdByUserId: row['created_by_user_id'] as String?,
      createdByName: row['created_by_name'] as String?,
    );
  }
}
