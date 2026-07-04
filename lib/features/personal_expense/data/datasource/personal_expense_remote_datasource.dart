import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/personal_expense/data/models/personal_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PersonalExpenseRemoteDatasource {
  Future<List<PersonalExpenseModel>> getExpenses(String userId);
  Future<void> addExpense(PersonalExpenseModel expense, String userId);
  Future<void> updateExpense(PersonalExpenseModel expense, String userId);
  Future<void> deleteExpense(String expenseId, String userId);
  Future<List<PersonalExpenseModel>> getFilteredExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });
}

class PersonalExpenseRemoteDatasourceImpl implements PersonalExpenseRemoteDatasource {
  final SupabaseClient supabaseClient;

  PersonalExpenseRemoteDatasourceImpl({required this.supabaseClient});

  Future<void> _verifyOwnerOnlyAccess(String userId) async {
    try {
      final response = await supabaseClient
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      final role = response['role'] as String? ?? '';
      if (role.toLowerCase() != 'owner') {
        throw ServerException(
          'Access Denied: Personal Expense module is restricted to Owners only.',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to verify user permissions. Access denied.',
      );
    }
  }

  @override
  Future<List<PersonalExpenseModel>> getExpenses(String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final response = await supabaseClient
          .from('personal_expenses')
          .select()
          .eq('owner_id', userId)
          .order('expense_date', ascending: false);

      final List<dynamic> list = response as List<dynamic>? ?? [];
      return list
          .map((item) => PersonalExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load personal expenses: $e');
    }
  }

  @override
  Future<void> addExpense(PersonalExpenseModel expense, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final mapData = expense.toJson();
      mapData['owner_id'] = userId;
      if (expense.id.isEmpty) {
        mapData.remove('id');
      }

      await supabaseClient.from('personal_expenses').insert(mapData);
    } catch (e) {
      throw ServerException('Failed to save personal expense: $e');
    }
  }

  @override
  Future<void> updateExpense(PersonalExpenseModel expense, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      final mapData = {
        'amount': expense.amount,
        'category': expense.category,
        'description': expense.description,
        'expense_date': expense.expenseDate.toIso8601String().split('T')[0],
      };
      await supabaseClient
          .from('personal_expenses')
          .update(mapData)
          .eq('id', expense.id)
          .eq('owner_id', userId);
    } catch (e) {
      throw ServerException('Failed to update personal expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId, String userId) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      await supabaseClient
          .from('personal_expenses')
          .delete()
          .eq('id', expenseId)
          .eq('owner_id', userId);
    } catch (e) {
      throw ServerException('Failed to delete personal expense: $e');
    }
  }

  @override
  Future<List<PersonalExpenseModel>> getFilteredExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _verifyOwnerOnlyAccess(userId);

    try {
      var query = supabaseClient.from('personal_expenses').select().eq('owner_id', userId);
      
      if (startDate != null) {
        query = query.gte('expense_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('expense_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('expense_date', ascending: false);
      final List<dynamic> list = response as List<dynamic>? ?? [];
      return list
          .map((item) => PersonalExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load filtered personal expenses: $e');
    }
  }
}
