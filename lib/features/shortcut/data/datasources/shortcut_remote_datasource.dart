import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';
import 'package:bizos/features/personal_expense/data/datasource/personal_expense_remote_datasource.dart';
import 'package:bizos/features/personal_expense/data/models/personal_expense_model.dart';
import 'package:bizos/features/shortcut/core/shortcut_constants.dart';
import 'package:bizos/features/shortcut/data/models/quick_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ShortcutRemoteDatasource {
  Future<QuickExpenseModel> createQuickExpense(
    QuickExpenseModel expense,
    String userId,
  );
  Future<List<String>> getCategories(String userId);
  Future<List<String>> getPaymentMethods();

  Future<Map<String, dynamic>> pairShortCut({required String deviceName});
  Future<Map<String, dynamic>> verifyPairingCode({required String code});
  Future<String> provisionShortcutToken({required String deviceName});
}

class ShortcutRemoteDatasourceImpl implements ShortcutRemoteDatasource {
  final SupabaseClient supabaseClient;
  final PersonalExpenseRemoteDatasource? personalExpenseRemoteDatasource;

  ShortcutRemoteDatasourceImpl({
    required this.supabaseClient,
    this.personalExpenseRemoteDatasource,
  });

  PersonalExpenseRemoteDatasource get _expenseDatasource =>
      personalExpenseRemoteDatasource ??
      PersonalExpenseRemoteDatasourceImpl(supabaseClient: supabaseClient);

  @override
  Future<QuickExpenseModel> createQuickExpense(
    QuickExpenseModel expense,
    String userId,
  ) async {
    try {
      final personalExpenseModel = PersonalExpenseModel(
        id: expense.id,
        ownerId: userId,
        amount: expense.amount,
        category: expense.category,
        paymentMethod: PaymentMethodHelper.sanitize(expense.paymentMethod),
        description: expense.description,
        expenseDate: expense.expenseDate,
        createdAt: expense.createdAt,
      );

      await _expenseDatasource.addExpense(personalExpenseModel, userId);

      return expense.copyWith(
        ownerId: userId,
      ) as QuickExpenseModel;
    } catch (e, stackTrace) {
      AppLogger.error('Remote error creating quick expense: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<List<String>> getCategories(String userId) async {
    try {
      final categories = await _expenseDatasource.getCategories(userId);
      final categoryNames = categories.map((c) => c.name).toSet().toList();
      if (categoryNames.isEmpty) {
        return ShortcutConstants.defaultCategories;
      }
      return categoryNames;
    } catch (e) {
      AppLogger.error('Error fetching categories for quick add, using default list: $e');
      return ShortcutConstants.defaultCategories;
    }
  }

  @override
  Future<List<String>> getPaymentMethods() async {
    return PaymentMethodHelper.allowedMethods;
  }

  @override
  Future<Map<String, dynamic>> pairShortCut({
    required String deviceName,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw Exception('Please login to Voryn first.');
      }

      final response = await supabaseClient.functions.invoke(
        'shortcut-create-pairing-code',
        body: {'device_name': deviceName},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception('Failed to create pairing code.');
      }

      final data = response.data;
      if (data is! Map) {
        throw Exception('Invalid pairing-code response.');
      }

      final result = Map<String, dynamic>.from(data);
      if (result['success'] != true || result['pairing_code'] is! String) {
        throw Exception(
          result['error']?.toString() ?? 'Unable to create pairing code.',
        );
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Create-Pairing-Code-Error: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>> verifyPairingCode({
    required String code,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'shortcut-verify-pairing-code',
        body: {'code': code.trim().toUpperCase()},
      );

      final data = response.data;
      if (data is! Map) {
        throw Exception('Invalid pairing verification response.');
      }

      final result = Map<String, dynamic>.from(data);
      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          result['error']?.toString() ?? 'Pairing verification failed.',
        );
      }

      if (result['success'] != true ||
          result['token'] is! String ||
          (result['token'] as String).isEmpty) {
        throw Exception(
          result['error']?.toString() ?? 'Invalid token received.',
        );
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Verify-Pairing-Code-Error: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<String> provisionShortcutToken({required String deviceName}) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw Exception('Please login to Voryn first.');
      }

      final response = await supabaseClient.functions.invoke(
        'shortcut-pair',
        body: {'device_name': deviceName},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception('Failed to provision shortcut token.');
      }

      final data = response.data;
      String? token;
      if (data is Map) {
        token = data['pairing_token']?.toString() ??
            data['token']?.toString() ??
            data['one_time_token']?.toString();
      } else if (data is String) {
        token = data;
      }

      if (token == null || token.trim().isEmpty) {
        throw Exception('No shortcut token returned from server.');
      }

      return token.trim();
    } catch (e, stackTrace) {
      AppLogger.error('Provision-Shortcut-Token-Error: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}
