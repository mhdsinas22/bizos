import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/data/datasoucre/income_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomeRemoteDatasourceImpl implements IncomeRemoteDatasource {
  final SupabaseClient supabaseClient;

  IncomeRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<IncomeModel>> getIncomeList(String businessId) async {
    final response = await supabaseClient
        .from('incomes')
        .select()
        .eq('business_id', businessId);

    return response.map((row) => _fromRow(row)).toList();
  }

  @override
  Future<List<IncomeModel>> getAllIncome() async {
    final response = await supabaseClient.from('incomes').select();
    return response.map((row) => _fromRow(row)).toList();
  }

  @override
  Future<void> addIncome(IncomeModel income) async {
    await supabaseClient.from('incomes').insert({
      'id': income.id,
      'business_id': income.businessId,
      'amount': income.amount,
      'category': income.category,
      'description': income.description,
      'income_date': income.date.toIso8601String(),
      'created_by_user_id': income.createdByUserId,
      'created_by_name': income.createdByName,
    });
  }

  @override
  Future<void> updateIncome(IncomeModel income) async {
    await supabaseClient
        .from('incomes')
        .update({
          'amount': income.amount,
          'category': income.category,
          'description': income.description,
          'income_date': income.date.toIso8601String(),
        })
        .eq('id', income.id);
  }

  @override
  Future<IncomeModel?> deleteIncome(String id) async {
    final response = await supabaseClient.from('incomes').select().eq('id', id).maybeSingle();
    if (response != null) {
      final model = _fromRow(response);
      await supabaseClient.from('incomes').delete().eq('id', id);
      return model;
    }
    return null;
  }

  IncomeModel _fromRow(Map<String, dynamic> row) {
    return IncomeModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      description: row['description'] ?? '',
      date: DateTime.parse(row['income_date'] as String),
      createdByUserId: row['created_by_user_id'] as String?,
      createdByName: row['created_by_name'] as String?,
    );
  }
}
