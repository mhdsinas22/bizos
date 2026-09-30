import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/data/datasoucre/income_remote_datasource.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomeRemoteDatasourceImpl implements IncomeRemoteDatasource {
  final SupabaseClient supabaseClient;

  IncomeRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<IncomeModel>> getIncomeList(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (businessId.trim().isEmpty) return [];
    var query = supabaseClient
        .from('incomes')
        .select()
        .eq('business_id', businessId);

    if (startDate != null) {
      query = query.gte('income_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('income_date', endDate.toIso8601String());
    }

    final response = await query.order('income_date', ascending: false);

    return (response as List<dynamic>)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<IncomeModel>> getAllIncome() async {
    final response = await supabaseClient.from('incomes').select();
    return (response as List<dynamic>)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addIncome(IncomeModel income) async {
    final Map<String, dynamic> data = {
      'amount': income.amount,
      'category': income.category,
      'payment_method': PaymentMethodHelper.sanitize(income.paymentMethod),
      'description': income.description,
      'income_date': income.date.toIso8601String(),
      'business_id': income.businessId.trim().isNotEmpty ? income.businessId : null,
      'created_by_user_id': (income.createdByUserId != null && income.createdByUserId!.trim().isNotEmpty) ? income.createdByUserId : null,
      'created_by_name': income.createdByName,
    };
    if (income.id.trim().isNotEmpty) {
      data['id'] = income.id;
    }
    await supabaseClient.from('incomes').insert(data);
  }

  @override
  Future<void> updateIncome(IncomeModel income) async {
    await supabaseClient
        .from('incomes')
        .update({
          'amount': income.amount,
          'category': income.category,
          'payment_method': PaymentMethodHelper.sanitize(income.paymentMethod),
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
    return IncomeModel.fromMap(row);
  }
}
